{
  inputs = 
    {
    #nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixos-generators = 
      {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
      };
    atw-kernel = 
      {
      flake = false;
      url = "github:yodalf/linux-atw-5.10.162/main";
      #url = "github:yodalf/linux-smx6_5.8.18/main";
      #url = "github:yodalf/linux-atw-4.14.60/main";
      #url = "github:yodalf/linux-5.8.18/main";
      #url = "github:yodalf/linux-atw-4.14.60/main";
      #url = "github:yodalf/linux-5.8.18/?ref=5788661b9cfb9f706c410585083d6936421fbab4";

      #url = "github:yodalf/linux-atw-5.10.161/main";
      #url = "github:yodalf/linux-smx6_5.8.18/?ref=1d56ce00236f73277ef610930257f751c5159b2f";
      #url = "git+https://gitlab.kontron.com/imx/linux-imx.git?ref=samx6i_5.8.18";
      };
    };

  outputs = { self, nixpkgs, atw-kernel, nixos-generators }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
      modules = [ 
        {nixpkgs.overlays = [ self.overlay ]; }
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
        #"${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
        ./boot.nix
        ./configuration.nix
      ];



      #squashfsKit = pkgs.squashfsTools.overrideDerivation (oldAttrs: {
      #  src = pkgs.fetchFromGitHub {
      #    owner = "squashfskit";
      #    repo = "squashfskit";
      #    sha256 = "1qampwl0ywiy9g2abv4jxnq33kddzdsq742ng5apkmn3gn12njqd";
      #    rev = "3f97efa7d88b2b3deb6d37ac7a5ddfc517e9ce98";
      #    };
      #  }); 
    in
      {
      overlay = final: prev: 
        {
        # Fix missing modules in intrd
        makeModulesClosure = x:
          prev.makeModulesClosure (x // { allowMissing = true; });
      
          final.tpm2-abrmd = (prev.tpm2-abrmd).overriideAttrs( final: prev: { nativeBuildInputs =  prev.nativeBuildInputs ++ [ prev.glib ];});
        
 
        linuxPackages_atw = 
          final.linuxPackagesFor ((final.callPackage ./kernel.nix { inherit atw-kernel; }).override { 
            patches = [ ]; 
            });

        };

      # Save the kernel packages in our pkgs
      legacyPackages.${system} =
        {
          inherit (pkgs.pkgsCross.armv7l.linux) linuxPackages_atw;
        };


      nixosConfigurations = 
        {
        atw = nixpkgs.lib.nixosSystem 
          {
          system = "${system}";
          modules = modules ++ 
            [{
              nixpkgs.crossSystem = 
                {
                system = "armv7l-linux";
                };
            }
            ];
          };
        };

      
      images = {
        sd = self.nixosConfigurations.atw.config.system.build.sdImage;
        iso = self.nixosConfigurations.atw.config.system.build.isoImage;
      };

      vm = nixos-generators.nixosGenerate {
        #system = "x86_64-linux";
        system = "armv7l-linux";
          #modules = modules ++ [
          #  {
          #    nixpkgs.crossSystem = {
          #      system = "armv7l-linux";
          #    };
          #  } ];
        format = "vm";
      };




######
      X =
        let 
          smx6 = self.nixosConfigurations.smx6;
          
        in  
        pkgs.stdenv.mkDerivation {
          name = "smx6.squashfs";
          #src = ./hello.tar.gz;

          nativeBuildInputs = [ pkgs.squashfsTools ];
          
          
          buildCommand =
            ''
              #closureInfo=${pkgs.closureInfo { rootPaths = [  ]; }}
              closureInfo=${pkgs.closureInfo { rootPaths = pkgs.hello; }}
              # Uncomment to print dependencies in the build log.
              # This is the easiest way I've found to do this.
              #echo "BEGIN DEPS"
              #cat $closureInfo/store-paths
              #echo "END DEPS"
              # TODO: Put symlinks binaries in /usr/bin.
              # Generate the squashfs image. Pass the -no-fragments option to make
              # the build reproducible; apparently splitting fragments is a
              # nondeterministic multithreaded process. Also set processors to 1 for
              # the same reason.
              mksquashfs $(cat $closureInfo/store-paths) $out \
                -no-fragments      \
                -processors 1      \
                -keep-as-directory \
                -all-root          \
                -b 1048576         \
                -comp xz           \
                -Xdict-size 100%   \
            '';
          };
######


  };
}
