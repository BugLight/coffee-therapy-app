{
  description = "Coffee Therapy App";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-flake.url = "github:juspay/rust-flake";
  };

  outputs = inputs @ {
    flake-parts,
    rust-flake,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        rust-flake.flakeModules.default
        rust-flake.flakeModules.nixpkgs
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        self',
        pkgs,
        config,
        lib,
        ...
      }: {
        devShells.default = let
          inherit (config.rust-project) toolchain crane;
          androidBuildToolsVersion = "34.0.0";
          androidPackages = pkgs.androidenv.composeAndroidPackages {
            buildToolsVersions = [
              androidBuildToolsVersion
            ];
            platformVersions = [
              "34"
            ];
            abiVersions = ["armeabi-v7a" "arm64-v8a"];
            includeNDK = true;
          };
        in
          pkgs.mkShell rec {
            name = "coffee-therapy-app-shell";

            ANDROID_HOME = "${androidPackages.androidsdk}/libexec/android-sdk";
            ANDROID_NDK_ROOT = "${ANDROID_HOME}/ndk-bundle";
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${androidBuildToolsVersion}/aapt2";
            RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";

            buildInputs =
              [
                pkgs.libiconv
                androidPackages.androidsdk
                pkgs.jdk
              ]
              ++ lib.concatMap (crate: crate.crane.args.buildInputs) (lib.attrValues config.rust-project.crates);
            packages =
              [
                toolchain
                androidPackages.platform-tools
                pkgs.dioxus-cli
              ]
              ++ lib.concatMap (crate: crate.crane.args.nativeBuildInputs) (lib.attrValues config.rust-project.crates);
          };
      };
    };
}
