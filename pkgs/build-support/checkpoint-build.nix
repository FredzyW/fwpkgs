{ lib
, buildPackages
}:

let
  # rudimentary support for cross-compiling
  # see: https://github.com/NixOS/nixpkgs/pull/279487#discussion_r1444449726
  inherit (buildPackages)
    mktemp
    rsync
    ;
in

rec {
  /* Prepare a derivation for local builds.
    *
    * This function prepares checkpoint builds by storing
    * the build output and the sources for cross checking.
    * The build output can be used later to allow checkpoint builds
    * by passing the derivation output to the `mkCheckpointBuild` function.
    *
    * To build a project with checkpoints, follow these steps:
    * - run `prepareCheckpointBuild` on the desired derivation, e.g.
    *     checkpointArtifacts = prepareCheckpointBuild virtualbox;
    * - change something you want in the sources of the package,
    *   e.g. using source override:
    *     changedVBox = pkgs.virtuabox.overrideAttrs (old: {
    *       src = path/to/vbox/sources;
    *     };
    * - use `mkCheckpointBuild changedVBox checkpointArtifacts`
    * - enjoy shorter build times
  */
  prepareCheckpointBuild = drv: drv.overrideAttrs (old: {
    outputs = [ "out" ];
    name = drv.name + "-checkpointArtifacts";
    # To determine differences between the state of the build directory
    # from an earlier build and a later one we store the state of the build
    # directory before build, but after patch phases.
    # This way, the same derivation can be used multiple times and only changes are detected.
    # Additionally, removed files are handled correctly in later builds.
    preBuild = (old.preBuild or "") + ''
      mkdir -p $out/sources
      cp -r ./* $out/sources/
    '';

    # After the build, the build directory is copied again
    # to get the output files.
    # We copy the complete build folder, to take care of
    # build tools that build in the source directory, instead of
    # having a separate build directory such as the Linux kernel.
    installPhase = ''
      runHook preCheckpointInstall
      mkdir -p $out/outputs
      cp -r ./* $out/outputs/
      runHook postCheckpointInstall
      unset postPhases
    '';

    dontFixup = true;
    doInstallCheck = false;
    doDist = false;
  });

  /* Build a derivation based on the checkpoint output generated by
    * the `prepareCheckpointBuild` function.
    *
    * Usage:
    * let
    *   checkpointArtifacts = prepareCheckpointBuild drv;
    * in mkCheckpointBuild drv checkpointArtifacts
  */
  mkCheckpointBuild = drv: checkpointArtifacts: drv.overrideAttrs (old: {
    # The actual checkpoint build phase.
    # We compare the changed sources from a previous build with the current and create a patch.
    # Afterwards we clean the build directory and copy the previous output files (including the sources).
    # The source difference patch is then applied to get the latest changes again to allow short build times.
    preBuild = (old.preBuild or "") + ''
      set +e
      sourceDifferencePatchFile=$(${mktemp}/bin/mktemp)
      diff -ur ${checkpointArtifacts}/sources ./ > "$sourceDifferencePatchFile"
      set -e
      shopt -s dotglob
      rm -r *
      ${rsync}/bin/rsync \
        --checksum --times --atimes --chown=$USER:$USER --chmod=+w \
        -r ${checkpointArtifacts}/outputs/ .
      patch -p 1 -i "$sourceDifferencePatchFile"
      rm "$sourceDifferencePatchFile"
    '';
  });

  mkCheckpointedBuild = lib.warn
    "`mkCheckpointedBuild` is deprecated, use `mkCheckpointBuild` instead!"
    mkCheckpointBuild;
}
