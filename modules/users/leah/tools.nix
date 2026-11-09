{ inputs, ... }: {
  flake.modules.homeManager.leah-tools-linux =
    { pkgs, ... }:
    let
      agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = with pkgs; [
        wget
        gh
        unstable.bun
        unstable.nodejs_24
        rustup
        clang
        nil
        nixd
        powershell
        flyctl
        dua
        zulu25
        btop
        unstable.typst
        unstable.tinymist
        unstable.typstyle
        agents.claude-code
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.omp
        agents.opencode2
        agents.junie
        agents.herdr
      ];
    };
  flake.modules.homeManager.leah-tools-darwin =
    { pkgs, ... }:
    let
      agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = with pkgs; [
        _1password-cli
        unstable.bun
        nil
        nodejs
        jujutsu
        agents.claude-code
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.omp
        agents.opencode2
        agents.junie
        agents.herdr
      ];
    };
}
