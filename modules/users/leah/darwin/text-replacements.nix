{inputs, ...}: let
  username = "leah";
in {
  flake.modules.homeManager."${username}-darwin" = {lib, ...}: let
    replacements = {
      "/:" = "Σ:";
      "/:3" = "Σ:3";
      "/:D" = "Σ:D";
    };
  in {
    targets.darwin.defaults.NSGlobalDomain.NSUserDictionaryReplacementItems = lib.mapAttrsToList (short: long: {
      on = 1;
      replace = short;
      "with" = long;
    })
    replacements;
  };
}
