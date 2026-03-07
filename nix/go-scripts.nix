{
    stdenvNoCC,
    go,
}:
stdenvNoCC.mkDerivation {
    pname = "go-scripts";
    version = "0.1.0";

    src = ../Assets/go;

    nativeBuildInputs = [go];

    buildPhase = ''
        export HOME=$TMPDIR
        go build -o screen-capture screen-capture.go
        go build -o keystate-bin keystate.go
    '';

    installPhase = ''
        install -Dm755 keystate-bin $out/bin/keystate-bin
        install -Dm755 screen-capture $out/bin/screen-capture
    '';

    meta = {
        description = "go scripts for vast-shell";
    };
}
