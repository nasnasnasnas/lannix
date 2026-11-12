{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}" = {pkgs, ...}: {
    programs.ssh = {
      enable = true;
      includes = ["~/.ssh/1Password/config"];
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
