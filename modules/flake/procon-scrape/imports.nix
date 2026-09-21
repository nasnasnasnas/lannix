{...}: {
  flake-file.inputs.procon-scrape = {
    url = "github:nealol/procon-scrape";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
