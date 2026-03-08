package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type ImportType int

const (
	QT_CORE ImportType = iota + 1
	QT_QUICK
	QT_LABS
	QT_QUICK_OTHER
	QUICKSHELL
	QUICKSHELL_OTHER
	QS_COMPONENTS
	EXPLICIT
)

type PropertyType int

const (
	ALIAS PropertyType = iota + 1
	REQUIRED
	READONLY
	NORMAL
)

type Import struct {
	Line          string
	Type          ImportType
	OriginalIndex int
}

type Property struct {
	Line   string
	Type   PropertyType
	Indent string
}

type ComponentStructure struct {
	ID           *LineInfo
	Anchors      []LineInfo
	Properties   []PropertyInfo
	Functions    []LineInfo
	Behaviors    []LineInfo
	Objects      []LineInfo
	NestedStarts []int
}

type LineInfo struct {
	Index int
	Line  string
}

type PropertyInfo struct {
	Index string
	Line  string
	Type  PropertyType
}

func findGitRoot() (string, error) {
	out, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

func classifyImport(line string) ImportType {
	re := regexp.MustCompile(`import\s+([^\s]+)`)
	matches := re.FindStringSubmatch(line)
	if len(matches) < 2 {
		return EXPLICIT
	}

	module := matches[1]
	if strings.HasPrefix(module, `"`) || strings.HasPrefix(module, `'`) {
		return EXPLICIT
	}

	switch {
	case module == "QtCore":
		return QT_CORE
	case module == "QtQuick":
		return QT_QUICK
	case strings.HasPrefix(module, "Qt.labs."):
		return QT_LABS
	case strings.HasPrefix(module, "QtQuick."):
		return QT_QUICK_OTHER
	case module == "Quickshell":
		return QUICKSHELL
	case strings.HasPrefix(module, "Quickshell."):
		return QUICKSHELL_OTHER
	case strings.HasPrefix(module, "qs."):
		return QS_COMPONENTS
	default:
		return EXPLICIT
	}
}

func sortImports(lines []string) ([]string, bool) {
	var imports []Import
	nonImportStart := -1

	for i, line := range lines {
		stripped := strings.TrimSpace(line)
		if strings.HasPrefix(stripped, "import ") {
			importType := classifyImport(stripped)
			imports = append(imports, Import{Line: line, Type: importType, OriginalIndex: i})
		} else if stripped != "" && !strings.HasPrefix(stripped, "//") {
			nonImportStart = i
			break
		}
	}

	if len(imports) == 0 {
		return lines, false
	}

	sortedImports := make([]Import, len(imports))
	copy(sortedImports, imports)
	sort.SliceStable(sortedImports, func(i, j int) bool {
		return sortedImports[i].Type < sortedImports[j].Type
	})

	var result []string
	var prevType ImportType = 0
	changed := false

	for i, imp := range sortedImports {
		if i < len(imports) && imp.Line != imports[i].Line {
			changed = true
		}

		if prevType != 0 {
			if (prevType == QUICKSHELL || prevType == QUICKSHELL_OTHER) && imp.Type == QS_COMPONENTS {
				result = append(result, "\n")
			} else if imp.Type == EXPLICIT && prevType != EXPLICIT {
				result = append(result, "\n")
			}
		}
		result = append(result, imp.Line)
		prevType = imp.Type
	}

	if nonImportStart > 0 {
		result = append(result, "\n")
		result = append(result, lines[nonImportStart:]...)
	} else if nonImportStart == -1 {
		// Only imports or empty/comments
	} else if nonImportStart == 0 {
		// Should not happen if imports exist
		result = append(result, lines...)
	}

	return result, changed
}

func classifyProperty(line string) *PropertyType {
	stripped := strings.TrimSpace(line)
	var pt PropertyType
	if regexp.MustCompile(`^property\s+alias\s+`).MatchString(stripped) {
		pt = ALIAS
	} else if regexp.MustCompile(`^required\s+property\s+`).MatchString(stripped) {
		pt = REQUIRED
	} else if regexp.MustCompile(`^readonly\s+property\s+`).MatchString(stripped) {
		pt = READONLY
	} else if regexp.MustCompile(`^property\s+\w+`).MatchString(stripped) {
		pt = NORMAL
	} else {
		return nil
	}
	return &pt
}

func findComponentStructure(lines []string, startIdx int) ComponentStructure {
	structure := ComponentStructure{}
	braceCount := 1
	i := startIdx + 1
	baseIndent := -1

	for i < len(lines) && braceCount > 0 {
		line := lines[i]
		stripped := strings.TrimSpace(line)

		if stripped == "" || strings.HasPrefix(stripped, "//") {
			i++
			continue
		}

		openBraces := strings.Count(line, "{")
		closeBraces := strings.Count(line, "}")
		braceCount += openBraces - closeBraces

		currentIndent := len(line) - len(strings.TrimLeft(line, " \t"))
		if baseIndent == -1 && stripped != "" {
			baseIndent = currentIndent
		}

		if baseIndent != -1 && currentIndent == baseIndent {
			if strings.HasPrefix(stripped, "id:") {
				structure.ID = &LineInfo{Index: i, Line: line}
			} else if strings.HasPrefix(stripped, "anchors") {
				structure.Anchors = append(structure.Anchors, LineInfo{Index: i, Line: line})
			} else if pt := classifyProperty(line); pt != nil {
				structure.Properties = append(structure.Properties, PropertyInfo{Index: fmt.Sprintf("%d", i), Line: line, Type: *pt})
			} else if regexp.MustCompile(`^function\s+\w+`).MatchString(stripped) {
				structure.Functions = append(structure.Functions, LineInfo{Index: i, Line: line})
			} else if regexp.MustCompile(`^(Behavior\s+on|Transition|States)\s*[:{[]`).MatchString(stripped) {
				structure.Behaviors = append(structure.Behaviors, LineInfo{Index: i, Line: line})
			} else if regexp.MustCompile(`^[A-Z]\w+\s*\{`).MatchString(stripped) {
				structure.Objects = append(structure.Objects, LineInfo{Index: i, Line: line})
				structure.NestedStarts = append(structure.NestedStarts, i) // <-- record for recursion
			}
		} else if baseIndent != -1 && currentIndent > baseIndent {
			if regexp.MustCompile(`^[A-Z]\w+\s*\{`).MatchString(stripped) {
				structure.NestedStarts = append(structure.NestedStarts, i)
			}
		}

		i++
	}
	return structure
}

func collectComponentIssues(lines []string, startIdx int) []string {
	var issues []string
	structure := findComponentStructure(lines, startIdx)

	issues = append(issues, checkComponentOrder(structure)...)
	if len(structure.Properties) > 0 {
		issues = append(issues, checkPropertyOrder(structure.Properties)...)
	}

	for _, nestedIdx := range structure.NestedStarts {
		issues = append(issues, collectComponentIssues(lines, nestedIdx)...)
	}

	return issues
}

func checkComponentOrder(structure ComponentStructure) []string {
	var issues []string
	if structure.ID == nil {
		return issues
	}

	lastLine := structure.ID.Index
	lastSection := "id"

	type section struct {
		name  string
		items []LineInfo
	}

	sections := []section{
		{"anchors", structure.Anchors},
		{"properties", propertyInfoToLineInfo(structure.Properties)},
		{"functions", structure.Functions},
		{"behaviors", structure.Behaviors},
		{"objects", structure.Objects},
	}

	for _, s := range sections {
		if len(s.items) == 0 {
			continue
		}

		firstItemLine := s.items[0].Index
		if firstItemLine < lastLine {
			issues = append(issues, fmt.Sprintf("Line %d: %s should be after %s", firstItemLine+1, s.name, lastSection))
		}

		lastLine = s.items[len(s.items)-1].Index
		lastSection = s.name
	}

	return issues
}

func propertyInfoToLineInfo(pi []PropertyInfo) []LineInfo {
	var li []LineInfo
	for _, p := range pi {
		var idx int
		fmt.Sscanf(p.Index, "%d", &idx)
		li = append(li, LineInfo{Index: idx, Line: p.Line})
	}
	return li
}

func checkPropertyOrder(properties []PropertyInfo) []string {
	var issues []string
	if len(properties) < 2 {
		return issues
	}

	var prevType PropertyType = 0
	for _, p := range properties {
		if prevType != 0 && p.Type < prevType {
			var idx int
			fmt.Sscanf(p.Index, "%d", &idx)
			issues = append(issues, fmt.Sprintf("Line %d: Wrong property order. Order: alias -> required -> readonly -> normal", idx+1))
		}
		prevType = p.Type
	}
	return issues
}

func addSpacingAfterID(lines []string) ([]string, bool) {
	var result []string
	changed := false
	i := 0
	for i < len(lines) {
		line := lines[i]
		stripped := strings.TrimSpace(line)

		if strings.HasPrefix(stripped, "id:") {
			result = append(result, line)
			nextIdx := i + 1
			hasEmptyLine := false

			for nextIdx < len(lines) {
				nextLine := lines[nextIdx]
				nextStripped := strings.TrimSpace(nextLine)

				if nextStripped == "" {
					hasEmptyLine = true
					result = append(result, nextLine)
					nextIdx++
					continue
				}

				if strings.HasPrefix(nextStripped, "//") {
					result = append(result, nextLine)
					nextIdx++
					continue
				}

				if nextStripped != "" && nextStripped != "}" {
					if !hasEmptyLine {
						result = append(result, "\n")
						changed = true
					}
				}
				break
			}
			i = nextIdx
			continue
		}
		result = append(result, line)
		i++
	}
	return result, changed
}

func formatQMLFile(filepath string, checkOnly bool) (bool, []string) {
	content, err := os.ReadFile(filepath)
	if err != nil {
		return false, []string{fmt.Sprintf("File read error: %v", err)}
	}

	lines := strings.Split(string(content), "\n")
	// Ensure last empty line is handled correctly if it exists
	if len(lines) > 0 && lines[len(lines)-1] == "" && !strings.HasSuffix(string(content), "\n") {
		// do nothing
	}

	issues := []string{}
	changed := false

	newLines, importChanged := sortImports(lines)
	if importChanged {
		changed = true
		issues = append(issues, "✓ Fixed import order")
	}

	if !checkOnly {
		_, idChanged := addSpacingAfterID(newLines)
		if idChanged {
			changed = true
			issues = append(issues, "✓ Added spacing after 'id'")
		}
	}

	for i, line := range newLines {
		if regexp.MustCompile(`^[A-Z]\w+\s*\{`).MatchString(strings.TrimSpace(line)) {
			issues = append(issues, collectComponentIssues(newLines, i)...)
			break
		}
	}

	if changed && !checkOnly {
		output := strings.Join(newLines, "\n")
		err := os.WriteFile(filepath, []byte(output), 0644)
		if err != nil {
			return false, []string{fmt.Sprintf("Error when writing file: %v", err)}
		}
	}

	manualIssues := []string{}
	for _, issue := range issues {
		if !strings.HasPrefix(issue, "✓") {
			manualIssues = append(manualIssues, issue)
		}
	}

	return len(manualIssues) > 0, issues
}

func findQMLFiles(directory string) []string {
	out, err := exec.Command("fd", "-e", "qml", "-t", "f", ".", directory).Output()
	if err != nil {
		// Fallback to manual walk
		var files []string
		filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
			if err == nil && !info.IsDir() && strings.HasSuffix(path, ".qml") {
				files = append(files, path)
			}
			return nil
		})
		return files
	}

	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	var files []string
	for _, line := range lines {
		if line != "" {
			files = append(files, line)
		}
	}
	return files
}

func runCustomCheck(gitRoot string, verbose bool) int {
	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Println("STEP 1: Running custom QML checks...")
	fmt.Println(strings.Repeat("=", 60))

	files := findQMLFiles(gitRoot)
	if len(files) == 0 {
		fmt.Printf("No QML files found in %s\n", gitRoot)
		return 0
	}

	filesWithIssues := 0
	totalManualIssues := 0

	for _, fp := range files {
		if verbose {
			fmt.Printf("\nProcessing: %s\n", fp)
		}
		hasIssues, issues := formatQMLFile(fp, true)
		if hasIssues {
			filesWithIssues++
			rel, _ := filepath.Rel(gitRoot, fp)
			fmt.Println("\n" + strings.Repeat("=", 60))
			fmt.Printf("File: %s\n", rel)
			fmt.Println(strings.Repeat("=", 60))
			for _, issue := range issues {
				fmt.Printf("  %s\n", issue)
				if !strings.HasPrefix(issue, "✓") {
					totalManualIssues++
				}
			}
		}
	}

	fmt.Printf("\nCheck completed: %d of %d file(s) have issues\n", filesWithIssues, len(files))
	if totalManualIssues > 0 {
		fmt.Printf("Manual fixes required: %d\n", totalManualIssues)
	}
	return totalManualIssues
}

func runQmlformat(gitRoot string) int {
	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Println("STEP 2: Running qmlformat...")
	fmt.Println(strings.Repeat("=", 60))

	files := findQMLFiles(gitRoot)
	if len(files) == 0 {
		fmt.Println("No QML files found")
		return 0
	}

	failedFiles := 0
	for _, fp := range files {
		cmd := exec.Command("qmlformat", "-i", fp)
		cmd.Dir = gitRoot
		out, err := cmd.CombinedOutput()
		if err != nil {
			failedFiles++
			rel, _ := filepath.Rel(gitRoot, fp)
			fmt.Printf("✗ Failed: %s\n", rel)
			fmt.Printf("  Error: %s\n", strings.TrimSpace(string(out)))
		}
	}

	if failedFiles > 0 {
		fmt.Printf("\nqmlformat failed on %d file(s)\n", failedFiles)
		return 1
	}
	fmt.Printf("\nqmlformat completed successfully on %d file(s)\n", len(files))
	return 0
}

func runLupdate(gitRoot string) int {
	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Println("STEP 3: Running lupdate...")
	fmt.Println(strings.Repeat("=", 60))

	translationsDir := filepath.Join(gitRoot, "translations")
	if _, err := os.Stat(translationsDir); os.IsNotExist(err) {
		fmt.Printf("Warning: translations directory not found at %s\n", translationsDir)
		return 0
	}

	entries, _ := os.ReadDir(translationsDir)
	var tsFiles []string
	for _, entry := range entries {
		if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".ts") {
			tsFiles = append(tsFiles, filepath.Join(translationsDir, entry.Name()))
		}
	}

	if len(tsFiles) == 0 {
		fmt.Printf("Warning: No .ts files found in %s\n", translationsDir)
		return 0
	}

	args := append([]string{".", "-ts"}, tsFiles...)
	cmd := exec.Command("lupdate", args...)
	cmd.Dir = gitRoot
	out, err := cmd.CombinedOutput()

	if err != nil {
		fmt.Println("✗ lupdate failed")
		fmt.Printf("Error: %s\n", strings.TrimSpace(string(out)))
		return 1
	}

	fmt.Println("✓ lupdate completed successfully")
	if len(out) > 0 {
		fmt.Println(strings.TrimSpace(string(out)))
	}
	return 0
}

func main() {
	verbose := false
	skipCheck := false
	skipFormat := false
	skipLupdate := false

	for _, arg := range os.Args[1:] {
		switch arg {
		case "-v", "--verbose":
			verbose = true
		case "--skip-check":
			skipCheck = true
		case "--skip-format":
			skipFormat = true
		case "--skip-lupdate":
			skipLupdate = true
		}
	}

	gitRoot, err := findGitRoot()
	if err != nil {
		fmt.Println("Error: Not in a git repository")
		os.Exit(1)
	}

	fmt.Printf("Git root: %s\n", gitRoot)
	cwd, _ := os.Getwd()
	fmt.Printf("Current directory: %s\n", cwd)

	os.Chdir(gitRoot)
	exitCode := 0

	if !skipCheck {
		if runCustomCheck(gitRoot, verbose) > 0 {
			exitCode = 1
		}
	}

	if !skipFormat {
		if runQmlformat(gitRoot) != 0 {
			exitCode = 1
		}
	}

	if !skipLupdate {
		if runLupdate(gitRoot) != 0 {
			exitCode = 1
		}
	}

	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Println("SUMMARY")
	fmt.Println(strings.Repeat("=", 60))
	if exitCode == 0 {
		fmt.Println("✓ All steps completed successfully")
	} else {
		fmt.Println("✗ Some steps failed or require manual fixes")
	}

	os.Exit(exitCode)
}
