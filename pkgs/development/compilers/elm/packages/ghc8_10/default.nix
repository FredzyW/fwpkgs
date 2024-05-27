{ pkgs, lib }:

self: pkgs.haskell.packages.ghc810.override {
  overrides = self: super: with pkgs.haskell.lib.compose; with lib;
    let
      elmPkgs = rec {
        elmi-to-json = justStaticExecutables (overrideCabal
          (drv: {
            version = "unstable-2021-07-19";
            src = pkgs.fetchgit {
              url = "https://github.com/stoeffel/elmi-to-json";
              sha256 = "0vy678k15rzpsn0aly90fb01pxsbqkgf86pa86w0gd94lka8acwl";
              rev = "6a42376ef4b6877e130971faf964578cc096e29b";
              fetchSubmodules = true;
            };

            prePatch = ''
              substituteInPlace package.yaml --replace "- -Werror" ""
              hpack
            '';
            jailbreak = true;

            description = "Tool that reads .elmi files (Elm interface file) generated by the elm compiler";
            homepage = "https://github.com/stoeffel/elmi-to-json";
            license = licenses.bsd3;
            maintainers = [ maintainers.turbomack ];
          })
          (self.callPackage ./elmi-to-json { }));

        elm-instrument = justStaticExecutables (overrideCabal
          (drv: {
            version = "unstable-2020-03-16";
            src = pkgs.fetchgit {
              url = "https://github.com/zwilias/elm-instrument";
              sha256 = "167d7l2547zxdj7i60r6vazznd9ichwc0bqckh3vrh46glkz06jv";
              rev = "63e15bb5ec5f812e248e61b6944189fa4a0aee4e";
              fetchSubmodules = true;
            };
            patches = [
              # Update code after breaking change in optparse-applicative
              # https://github.com/zwilias/elm-instrument/pull/5
              (pkgs.fetchpatch {
                name = "update-optparse-applicative.patch";
                url = "https://github.com/mdevlamynck/elm-instrument/commit/c548709d4818aeef315528e842eaf4c5b34b59b4.patch";
                sha256 = "0ln7ik09n3r3hk7jmwwm46kz660mvxfa71120rkbbaib2falfhsc";
              })
            ];

            prePatch = ''
              sed "s/desc <-.*/let desc = \"${drv.version}\"/g" Setup.hs --in-place
            '';
            jailbreak = true;
            # Tests are failing because of missing instances for Eq and Show type classes
            doCheck = false;

            description = "Instrument Elm code as a preprocessing step for elm-coverage";
            homepage = "https://github.com/zwilias/elm-instrument";
            license = licenses.bsd3;
            maintainers = [ maintainers.turbomack ];
          })
          (self.callPackage ./elm-instrument { }));
      };
    in
    elmPkgs // {
      inherit elmPkgs;

      # We need attoparsec < 0.14 to build elm for now
      attoparsec = self.attoparsec_0_13_2_5;

      # aeson 2.0.3.0 does not build with attoparsec_0_13_2_5
      aeson = doJailbreak self.aeson_1_5_6_0;

      # elm-instrument needs this
      indents = self.callPackage ./indents { };

      # elm-instrument's tests depend on an old version of elm-format, but we set doCheck to false for other reasons above
      elm-format = null;
    };
}