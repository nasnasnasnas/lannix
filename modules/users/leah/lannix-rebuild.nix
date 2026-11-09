{ ... }: {
  flake.modules.homeManager.leah-lilac =
    { pkgs, ... }:
    let
      # pkexec clears PATH; rebuild and activation tools need the NixOS system
      # commands. Use only root-managed paths, never the caller's user profile.
      privilegedRebuild = pkgs.writeShellScript "lannix-rebuild-root" ''
        export PATH=/run/current-system/sw/bin:/run/wrappers/bin
        exec /run/current-system/sw/bin/nixos-rebuild "$@"
      '';
    in
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "lannix-rebuild";
          runtimeInputs = [ pkgs.nix-output-monitor ];
          # Use NixOS's privileged pkexec wrapper. An absolute flake path survives
          # pkexec's working-directory reset; nom still runs as the normal user.
          # pipefail propagates authentication cancellation and rebuild failures.
          text = ''
            /run/wrappers/bin/pkexec ${privilegedRebuild} \
              switch --flake /home/leah/lannix --log-format internal-json -j 4 --cores 8 2>&1 | nom --json
          '';
        })
        pkgs.nix-output-monitor
      ];
    };
}
