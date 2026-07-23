package cmd

import (
	"fmt"
	"strconv"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/myamusashi/vast-shell/vastctl/internal/pretty"
)

func ipcCallPrint(target, method string, args ...string) error {
	output, err := ipc.Call(target, method, args...)
	if err != nil {
		return err
	}
	if prettier {
		if tree, treeErr := pretty.Tree(output); treeErr == nil {
			output = tree
		}
	}
	fmt.Println(output)
	return nil
}

func ipcCallVoid(target, method string, args ...string) error {
	_, err := ipc.Call(target, method, args...)
	return err
}

func validatePercent(s string) (int, error) {
	v, err := strconv.Atoi(s)
	if err != nil || v < 0 || v > 100 {
		return 0, fmt.Errorf("invalid percent: %s (must be 0-100)", s)
	}
	return v, nil
}

func actionOrDefault(args []string, defaultAction string) string {
	if len(args) > 0 {
		return args[0]
	}
	return defaultAction
}
