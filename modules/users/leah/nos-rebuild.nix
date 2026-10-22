{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    home.packages = with pkgs; [
      nix-output-monitor
    ];

    programs.fish.functions = {
      nos-rebuild = {
        description = "Does a nixos-rebuild with nix-output-monitor";
        body = ''
          pushd /home/leah/lannix
          sudo -v
          sudo nixos-rebuild switch --flake --log-format internal-json |& nom --json
          popd
        '';
      };
    };
  };
}
