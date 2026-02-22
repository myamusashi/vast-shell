#!/usr/bin/env python3

import re
import os
import sys
import subprocess
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


def find_git_root() -> Optional[Path]:
    """Find the root directory of the git repository."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        )
        return Path(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def classify_import(import_line: str) -> ImportType:
    import_match = re.match(r"import\s+([^\s]+)", import_line)
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
        if stripped.startswith("import "):
            import_type = classify_import(stripped)
            imports.append(Import(line, import_type, i))
        elif stripped and not stripped.startswith("//"):
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
            if (
                prev_type in [ImportType.QUICKSHELL, ImportType.QUICKSHELL_OTHER]
                and current_type == ImportType.QS_COMPONENTS
            ):
                result.append("\n")
            elif (
                current_type == ImportType.EXPLICIT and prev_type != ImportType.EXPLICIT
            ):
                result.append("\n")
        result.append(imp.line)
        prev_type = current_type
    if non_import_start > 0:
        result.append("\n")
    result.extend(lines[non_import_start:])

    # Check if the imports changed
    changed = [imp.line for imp in sorted_imports] != [imp.line for imp in imports]

    return result, changed


def classify_property(line: str) -> Optional[PropertyType]:
    stripped = line.strip()
    if re.match(r"property\s+alias\s+", stripped):
        return PropertyType.ALIAS
    elif re.match(r"required\s+property\s+", stripped):
        return PropertyType.REQUIRED
    elif re.match(r"readonly\s+property\s+", stripped):
        return PropertyType.READONLY
    elif re.match(r"property\s+\w+", stripped):
        return PropertyType.NORMAL
    return None


def find_component_structure(lines: List[str], start_idx: int) -> dict:
    structure = {
        "id": None,
        "anchors": [],
        "properties": [],
        "functions": [],
        "behaviors": [],
        "objects": [],
        "issues": [],
    }

    brace_count = 1
    i = start_idx + 1
    current_section = None
    base_indent = None

    while i < len(lines) and brace_count > 0:
        line = lines[i]
        stripped = line.strip()

        # Skip empty lines and comments
        if not stripped or stripped.startswith("//"):
            i += 1
            continue

        brace_count += line.count("{") - line.count("}")

        # Detect indentation level (process only top-level items)
        if base_indent is None and stripped:
            base_indent = len(line) - len(line.lstrip())

        current_indent = len(line) - len(line.lstrip())

        # Only process lines at base indentation level
        if base_indent is not None and current_indent == base_indent:
            # ID property
            if stripped.startswith("id:"):
                structure["id"] = (i, line)
            # Anchors
            elif stripped.startswith("anchors"):
                structure["anchors"].append((i, line))
            # Properties
            elif classify_property(line) is not None:
                prop_type = classify_property(line)
                structure["properties"].append((i, line, prop_type))
            # Functions
            elif re.match(r"function\s+\w+", stripped):
                structure["functions"].append((i, line))
            # Behaviors, Transitions, States
            elif re.match(r"(Behavior\s+on|Transition|States)\s*[:{[]", stripped):
                structure["behaviors"].append((i, line))
            # Objects (other components)
            elif re.match(r"[A-Z]\w+\s*\{", stripped):
                structure["objects"].append((i, line))

        i += 1

    return structure


def check_component_order(structure: dict) -> List[str]:
    issues = []

    if not structure["id"]:
        return issues

    id_line = structure["id"][0]
    last_line = id_line
    last_section = "id"

    # Expected order: id -> anchors -> properties -> functions -> behaviors -> objects
    sections = [
        ("anchors", structure["anchors"]),
        ("properties", structure["properties"]),
        ("functions", structure["functions"]),
        ("behaviors", structure["behaviors"]),
        ("objects", structure["objects"]),
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

        if stripped.startswith("id:"):
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
                if next_stripped.startswith("//"):
                    result.append(next_line)
                    next_idx += 1
                    continue

                if next_stripped and next_stripped != "}":
                    if not has_empty_line:
                        result.append("\n")
                        changed = True
                break
            i = next_idx
            continue
        result.append(line)
        i += 1
    return result, changed


def format_qml_file(filepath: Path, check_only: bool = False) -> Tuple[bool, List[str]]:
    try:
        with open(filepath, "r", encoding="utf-8") as f:
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
        if re.match(r"^[A-Z]\w+\s*\{", line.strip()):
            structure = find_component_structure(new_lines, i)
            order_issues = check_component_order(structure)
            issues.extend(order_issues)
            if structure["properties"]:
                prop_issues = check_property_order(structure["properties"])
                issues.extend(prop_issues)

    if changed and not check_only:
        try:
            with open(filepath, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
        except Exception as e:
            return False, [f"Error when writing file: {e}"]

    return changed or bool([i for i in issues if not i.startswith("✓")]), issues


def find_qml_files(directory: Path) -> List[Path]:
    """Find QML files using fd command for better performance."""
    try:
        result = subprocess.run(
            ["fd", "-e", "qml", "-t", "f", ".", str(directory)],
            capture_output=True,
            text=True,
            check=True,
        )
        files = [
            Path(line.strip())
            for line in result.stdout.strip().split("\n")
            if line.strip()
        ]
        return files
    except FileNotFoundError:
        # Fallback to Python's rglob if fd is not available
        print("Warning: 'fd' command not found, using slower fallback method")
        return list(directory.rglob("*.qml"))
    except subprocess.CalledProcessError:
        # Fallback on error
        return list(directory.rglob("*.qml"))


def run_custom_check(git_root: Path, verbose: bool = False) -> int:
    """Run custom QML check on all files."""
    print("\n" + "=" * 60)
    print("STEP 1: Running custom QML checks...")
    print("=" * 60)

    files = find_qml_files(git_root)
    if not files:
        print(f"No QML files found in {git_root}")
        return 0

    files_with_issues = 0
    total_manual_issues = 0

    for filepath in files:
        if verbose:
            print(f"\nProcessing: {filepath}")
        has_issues, issues = format_qml_file(filepath, check_only=True)
        if has_issues or issues:
            files_with_issues += 1
            print(f"\n{'='*60}")
            print(f"File: {filepath.relative_to(git_root)}")
            print("=" * 60)
            for issue in issues:
                print(f"  {issue}")
                if not issue.startswith("✓"):
                    total_manual_issues += 1

    print(f"\nCheck completed: {files_with_issues} of {len(files)} file(s) have issues")
    if total_manual_issues > 0:
        print(f"Manual fixes required: {total_manual_issues}")

    return total_manual_issues


def run_qmlformat(git_root: Path) -> int:
    """Run qmlformat on all QML files recursively."""
    print("\n" + "=" * 60)
    print("STEP 2: Running qmlformat...")
    print("=" * 60)

    files = find_qml_files(git_root)
    if not files:
        print("No QML files found")
        return 0

    failed_files = []
    for filepath in files:
        try:
            result = subprocess.run(
                ["qmlformat", "-i", str(filepath)],
                capture_output=True,
                text=True,
                cwd=git_root,
            )
            if result.returncode != 0:
                failed_files.append((filepath, result.stderr))
                print(f"✗ Failed: {filepath.relative_to(git_root)}")
                if result.stderr:
                    print(f"  Error: {result.stderr.strip()}")
            else:
                print(f"✓ Formatted: {filepath.relative_to(git_root)}")
        except FileNotFoundError:
            print("\nError: qmlformat not found. Please install Qt development tools.")
            return 1
        except Exception as e:
            failed_files.append((filepath, str(e)))
            print(f"✗ Error processing {filepath.relative_to(git_root)}: {e}")

    if failed_files:
        print(f"\nqmlformat failed on {len(failed_files)} file(s)")
        return 1
    else:
        print(f"\nqmlformat completed successfully on {len(files)} file(s)")
        return 0


def run_lupdate(git_root: Path) -> int:
    """Run lupdate to update translation files."""
    print("\n" + "=" * 60)
    print("STEP 3: Running lupdate...")
    print("=" * 60)

    translations_dir = git_root / "translations"

    if not translations_dir.exists():
        print(f"Warning: translations directory not found at {translations_dir}")
        print("Skipping lupdate step")
        return 0

    ts_files = list(translations_dir.glob("*.ts"))
    if not ts_files:
        print(f"Warning: No .ts files found in {translations_dir}")
        print("Skipping lupdate step")
        return 0

    try:
        result = subprocess.run(
            ["lupdate", ".", "-ts"] + [str(f) for f in ts_files],
            capture_output=True,
            text=True,
            cwd=git_root,
        )

        if result.returncode != 0:
            print(f"✗ lupdate failed")
            if result.stderr:
                print(f"Error: {result.stderr.strip()}")
            return 1
        else:
            print(f"✓ lupdate completed successfully")
            if result.stdout:
                print(result.stdout.strip())
            return 0
    except FileNotFoundError:
        print("\nError: lupdate not found. Please install Qt Linguist tools.")
        return 1
    except Exception as e:
        print(f"✗ Error running lupdate: {e}")
        return 1


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="QML formatter and checker - runs from git root"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose logging"
    )
    parser.add_argument(
        "--skip-check", action="store_true", help="Skip custom QML check (step 1)"
    )
    parser.add_argument(
        "--skip-format", action="store_true", help="Skip qmlformat (step 2)"
    )
    parser.add_argument(
        "--skip-lupdate", action="store_true", help="Skip lupdate (step 3)"
    )

    args = parser.parse_args()

    # Find git root
    git_root = find_git_root()
    if git_root is None:
        print("Error: Not in a git repository")
        sys.exit(1)

    print(f"Git root: {git_root}")
    print(f"Current directory: {Path.cwd()}")

    # Change to git root
    os.chdir(git_root)

    exit_code = 0

    # Step 1: Custom check
    if not args.skip_check:
        check_result = run_custom_check(git_root, args.verbose)
        if check_result > 0:
            exit_code = 1

    # Step 2: qmlformat
    if not args.skip_format:
        format_result = run_qmlformat(git_root)
        if format_result != 0:
            exit_code = 1

    # Step 3: lupdate
    if not args.skip_lupdate:
        lupdate_result = run_lupdate(git_root)
        if lupdate_result != 0:
            exit_code = 1

    # Final summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    if exit_code == 0:
        print("✓ All steps completed successfully")
    else:
        print("✗ Some steps failed or require manual fixes")

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
