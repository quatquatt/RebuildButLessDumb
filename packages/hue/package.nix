{ pkgs, localPackages }:

localPackages.writeFishApplication {
  name = "hue"; # Handle Ugly Errors
  runtimeInputs = with pkgs; [
    git
  ];
  text = builtins.readFile ./hue.fish;
}
