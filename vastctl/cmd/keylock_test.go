package cmd

import "testing"

func TestKeylock(t *testing.T) {
	t.Setenv("SHIM_OUT", `{"capsLock":false,"numLock":true}`)

	for _, tc := range []struct {
		name string
		args []string
		want []string
	}{
		{"capslock", []string{"keylock", "capslock"}, []string{"keylock", "capslock"}},
		{"numlock", []string{"keylock", "numlock"}, []string{"keylock", "numlock"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			runCall(t, tc.want, tc.args...)
		})
	}
}

func TestKeylockRendersTree(t *testing.T) {
	t.Setenv("SHIM_OUT", `{"capsLock":true,"numLock":false}`)

	res := runCall(t, []string{"keylock", "capslock"}, "keylock", "capslock")

	want := "├── capsLock: yes\n└── numLock: no\n\n"
	if res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}
}
