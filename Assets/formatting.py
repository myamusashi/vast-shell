#!/usr/bin/env python3

import re
import os
import sys
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class ImportType(Enum):
    QT_CORE = 1
    QT_QUICK = 2
    QT_LABS = 3
    QT_QUICK_OTHER = 4
    QUICKSHELL = 5
    QUICKSHELL_OTHER = 6
    QS_COMPONENTS = 7
    EXPLICIT = 8


class PropertyType(Enum):
    ALIAS = 1
    REQUIRED = 2
    READONLY = 3
    NORMAL = 4


@dataclass
class Import:
    line: str
    type: ImportType
    original_index: int


@dataclass
class Property:
    line: str
    type: PropertyType
    indent: str


def classify_import(import_line: str) -> ImportType:
    import_match = re.match(r'import\s+([^\s]+)', import_line)
    if not import_match:
        return ImportType.EXPLICIT

    module = import_match.group(1)

    if module.startswith('"') or module.startswith("'"):
        return ImportType.EXPLICIT

    if module == "QtCore":
        return ImportType.QT_CORE
    elif module == "QtQuick":
        return ImportType.QT_QUICK
    elif module.startswith("Qt.labs."):
        return ImportType.QT_LABS
    elif module.startswith("QtQuick."):
        return ImportType.QT_QUICK_OTHER
    elif module == "Quickshell":
        return ImportType.QUICKSHELL
    elif module.startswith("Quickshell."):
        return ImportType.QUICKSHELL_OTHER
    elif module.startswith("qs."):
        return ImportType.QS_COMPONENTS
    else:
        return ImportType.EXPLICIT


def sort_imports(lines: List[str]) -> Tuple[List[str], bool]:
    imports = []
    non_import_start = 0

    # Get all imports
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('import '):
            import_type = classify_import(stripped)
            imports.append(Import(line, import_type, i))
        elif stripped and not stripped.startswith('//'):
            non_import_start = i
            break

    if not imports:
        return lines, False

    sorted_imports = sorted(imports, key=lambda x: x.type.value)

    result = []
    prev_type = None

    for imp in sorted_imports:
        current_type = imp.type

        if prev_type is not None:
            if prev_type in [ImportType.QUICKSHELL, ImportType.QUICKSHELL_OTHER] and \
                 current_type == ImportType.QS_COMPONENTS:
                result.append('\n')
            elif current_type == ImportType.EXPLICIT and prev_type != ImportType.EXPLICIT:
                result.append('\n')
        result.append(imp.line)
        prev_type = current_type
    if non_import_start > 0:
        result.append('\n')
    result.extend(lines[non_import_start:])

    # Check if the imports changed
    changed = [imp.line for imp in sorted_imports] != [imp.line for imp in imports]

    return result, changed


def classify_property(line: str) -> Optional[PropertyType]:
    stripped = line.strip()
    if re.match(r'property\s+alias\s+', stripped):
        return PropertyType.ALIAS
    elif re.match(r'required\s+property\s+', stripped):
        return PropertyType.REQUIRED
    elif re.match(r'readonly\s+property\s+', stripped):
        return PropertyType.READONLY
    elif re.match(r'property\s+\w+', stripped):
        return PropertyType.NORMAL
    return None


def find_component_structure(lines: List[str], start_idx: int) -> dict:
    structure = {
        'id': None,
        'anchors': [],
        'properties': [],
        'functions': [],
        'behaviors': [],
        'objects': [],
        'issues': []
    }

    brace_count = 1
    i = start_idx + 1
    current_section = None
    base_indent = None

    while i < len(lines) and brace_count > 0:
        line = lines[i]
        stripped = line.strip()

        # Skip empty lines and comments
        if not stripped or stripped.startswith('//'):
            i += 1
            continue

        brace_count += line.count('{') - line.count('}')

        # Detect indentation level (process only top-level items)
        if base_indent is None and stripped:
            base_indent = len(line) - len(line.lstrip())

        current_indent = len(line) - len(line.lstrip())

        # Only process lines at base indentation level
        if base_indent is not None and current_indent == base_indent:
            # ID property
            if stripped.startswith('id:'):
                structure['id'] = (i, line)
            # Anchors
            elif stripped.startswith('anchors'):
                structure['anchors'].append((i, line))
            # Properties
            elif classify_property(line) is not None:
                prop_type = classify_property(line)
                structure['properties'].append((i, line, prop_type))
            # Functions
            elif re.match(r'function\s+\w+', stripped):
                structure['functions'].append((i, line))
            # Behaviors, Transitions, States
            elif re.match(r'(Behavior\s+on|Transition|States)\s*[:{[]', stripped):
                structure['behaviors'].append((i, line))
            # Objects (other components)
            elif re.match(r'[A-Z]\w+\s*\{', stripped):
                structure['objects'].append((i, line))

        i += 1

    return structure


def check_component_order(structure: dict) -> List[str]:
    issues = []

    if not structure['id']:
        return issues

    id_line = structure['id'][0]
    last_line = id_line
    last_section = 'id'

    # Expected order: id -> anchors -> properties -> functions -> behaviors -> objects
    sections = [
        ('anchors', structure['anchors']),
        ('properties', structure['properties']),
        ('functions', structure['functions']),
        ('behaviors', structure['behaviors']),
        ('objects', structure['objects'])
    ]

    for section_name, items in sections:
        if not items:
            continue

        first_item_line = items[0][0]

        if first_item_line < last_line:
            issues.append(
                f"Line {first_item_line + 1}: {section_name} should be after {last_section}"
            )

        last_line = items[-1][0]
        last_section = section_name

    return issues


def check_property_order(properties: List[Tuple[int, str, PropertyType]]) -> List[str]:
    issues = []

    if len(properties) < 2:
        return issues

    prev_type = None
    for line_num, line, prop_type in properties:
        if prev_type is not None and prop_type.value < prev_type.value:
            issues.append(
                f"Line {line_num + 1}: Wrong property order. "
                f"Order: alias -> required -> readonly -> normal"
            )
        prev_type = prop_type

    return issues


def add_spacing_after_id(lines: List[str]) -> Tuple[List[str], bool]:
    result = []
    changed = False
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if stripped.startswith('id:'):
            result.append(line)

            next_idx = i + 1
            has_empty_line = False

            while next_idx < len(lines):
                next_line = lines[next_idx]
                next_stripped = next_line.strip()

                # If empty line is found, continue scanning
                if not next_stripped:
                    has_empty_line = True
                    result.append(next_line)
                    next_idx += 1
                    continue

                # Skip comments
                if next_stripped.startswith('//'):
                    result.append(next_line)
                    next_idx += 1
                    continue

                if next_stripped and next_stripped != '}':
                    if not has_empty_line:
                        result.append('\n')
                        changed = True
                break
            i = next_idx
            continue
        result.append(line)
        i += 1
    return result, changed


def format_qml_file(filepath: Path, check_only: bool = False) -> Tuple[bool, List[str]]:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        return False, [f"File read error: {e}"]

    issues = []
    changed = False

    new_lines, import_changed = sort_imports(lines)
    if import_changed:
        changed = True
        issues.append("✓ Fixed import order")

    if not check_only:
        new_lines, id_changed = add_spacing_after_id(new_lines)
        if id_changed:
            changed = True
            issues.append("✓ Added spacing after 'id'")

    for i, line in enumerate(new_lines):
        if re.match(r'^[A-Z]\w+\s*\{', line.strip()):
            structure = find_component_structure(new_lines, i)
            order_issues = check_component_order(structure)
            issues.extend(order_issues)
            if structure['properties']:
                prop_issues = check_property_order(structure['properties'])
                issues.extend(prop_issues)

    if changed and not check_only:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
        except Exception as e:
            return False, [f"Error when writing file: {e}"]

    return changed or bool([i for i in issues if not i.startswith('✓')]), issues


def find_qml_files(directory: str) -> List[Path]:
    path = Path(directory)
    return list(path.rglob("*.qml"))


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Check and format QML files'
    )
    parser.add_argument(
        'path',
        nargs='?',
        default='.',
        help='Path to QML file or directory (default: current directory)'
    )
    parser.add_argument(
        '-c', '--check',
        action='store_true',
        help='Check only (do not modify files)'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )

    args = parser.parse_args()

    path = Path(args.path)

    if path.is_file():
        if path.suffix != '.qml':
            print(f"Error: {path} is not a QML file")
            sys.exit(1)
        files = [path]
    elif path.is_dir():
        files = find_qml_files(str(path))
        if not files:
            print(f"No QML files found in {path}")
            sys.exit(0)
    else:
        print(f"Error: {path} not found")
        sys.exit(1)

    files_with_issues = 0
    total_manual_issues = 0

    for filepath in files:
        if args.verbose:
            print(f"\nProcessing: {filepath}")
        has_issues, issues = format_qml_file(filepath, args.check)
        if has_issues or issues:
            files_with_issues += 1
            print(f"\n{'='*60}")
            print(f"File: {filepath}")
            print('='*60)
            for issue in issues:
                print(f"  {issue}")
                if not issue.startswith('✓'):
                    total_manual_issues += 1

    # Summary
    print(f"\n{'='*60}")
    mode = "Check" if args.check else "Format"
    print(f"{mode} completed: {files_with_issues} of {len(files)} file(s) have issues")
    if not args.check:
        print(f"Manual fixes required: {total_manual_issues}")

    sys.exit(1 if total_manual_issues > 0 else 0)


if __name__ == '__main__':
    main()
