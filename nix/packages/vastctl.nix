{ lib, buildGoModule }:

buildGoModule {
  pname = "vastctl";
  version = "0.1.0";
  src = ../../vastctl;

  proxyVendor = true;
  vendorHash = "sha256-QlOOmsYB4qK3Bgf+PB+QXs65XnwKz2ds3GJuvwCSc+k=";

  ldflags = [ "-s" "-w" ];

  postInstall = ''
    mkdir -p $out/share/bash-completion/completions
    $out/bin/vastctl completion bash > $out/share/bash-completion/completions/vastctl

    mkdir -p $out/share/fish/vendor_completions.d
    $out/bin/vastctl completion fish > $out/share/fish/vendor_completions.d/vastctl.fish

    mkdir -p $out/share/zsh/site-functions
    $out/bin/vastctl completion zsh > $out/share/zsh/site-functions/_vastctl

    mkdir -p $out/share/nushell/completions
    $out/bin/vastctl completion nushell > $out/share/nushell/completions/vastctl.nu
  '';

  meta = with lib; {
    description = "CLI control surface for vast-shell";
    license = licenses.gpl3Only;
    mainProgram = "vastctl";
  };
}
