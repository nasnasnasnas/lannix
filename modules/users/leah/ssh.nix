{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    programs.ssh = {
      settings = {
        "*" = {
          IdentityAgent = "~/.1password/agent.sock";
        };

        "git.nixium.dev" = {
          Port = 222;
        };
      };
    };
  };
}