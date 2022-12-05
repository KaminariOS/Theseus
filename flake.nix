{
  description = "RedLeaf Operating System";

  inputs = {
    mars-std.url = "github:mars-research/mars-std";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, mars-std, rust-overlay,... }: let
    supportedSystems = [ "x86_64-linux" ];
  in mars-std.lib.eachSystem supportedSystems (system: let
    nightlyVersion = "2022-11-29";

    #pkgs = mars-std.legacyPackages.${system};
    pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (import rust-overlay)
          #(import ./pkgs)
        ];
      };
    pinnedRust = pkgs.rust-bin.nightly.${nightlyVersion}.default.override {
      extensions = [ "rust-src" "rust-analyzer-preview" ];
      targets = [ "x86_64-unknown-linux-gnu" ];
    };
    rustPlatform = pkgs.makeRustPlatform {
      rustc = pinnedRust;
      cargo = pinnedRust;
    };
    cargoExpand = pkgs.cargo-expand.override { inherit rustPlatform; };
  in {
    devShell = pkgs.mkShell {
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

      nativeBuildInputs = [
        pinnedRust cargoExpand
      ] ++ (with pkgs; [
        gnumake utillinux which

        gcc10 clang_10 nasm
        qemu grub2 xorriso gdb
        zlib

        pkg-config
        mtools
        qemu_kvm
        grub2
      ]);
    };

    reproduce = pkgs.mars-research.mkReproduceHook {
      cloudlab = "c220g2";
      script = ''
        echo "OK"
      '';
    };
  });
}
