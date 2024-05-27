args:
import ../generic.nix (args // {
  version = "13.4.14";
  hash = "sha256-g11D5lekI3pUpKf5CLUuNjejs0gN/bEemHkCj3akha0=";
  vendorHash = "sha256-kiDhlR/P81u/yNq72JuskES/UzMrTFzJT0H3xldGk8I=";
  yarnHash = "sha256-E9T+7aXVoERdUnVEL4va2fcMnv1jsL9Js/R2LZo4hu4=";
  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "rdp-rs-0.1.0" = "sha256-4NbAsEmyUdmBcHuzx+SLQCGKICC4V4FX4GTK2SzyHC0=";
    };
  };
  extPatches = [
    # https://github.com/NixOS/nixpkgs/issues/120738
    ../tsh.patch
  ];
})
