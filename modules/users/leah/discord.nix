{
  inputs,
  self,
  ...
}:
let
  username = "leah";
in
{
  flake.modules.homeManager.leah-desktop-linux = { pkgs, ... }: {
    home.packages = with pkgs; [
      unstable.vesktop
      (unstable.discord.override {
        # withOpenASAR = true; # complementary
        withVencord = true;
      })
    ];
  };

}
