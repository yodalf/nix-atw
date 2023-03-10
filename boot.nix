{ config, lib, pkgs,  ... }:

{
  #hardware.deviceTree.name = "imx6dl-aristainetos2c-cslb_7.dtb";
  hardware.deviceTree.name = "imx6dl-aristainetos2d_7.dtb";
  #hardware.deviceTree.name = "imx6dl-aristainetos_7.dtb";
  
#hardware.deviceTree.name = "kontron/imx6q-smx6-eval-valise.dtb";
  #hardware.deviceTree.name = "imx6dl-sabreauto.dts";

  #isoImage.makeEfiBootable = true;
  #isoImage.makeUsbBootable = true;

  boot = 
    {
    consoleLogLevel = lib.mkDefault 7;

    kernelPackages = pkgs.linuxPackages_atw;

    kernelParams = 
      [
      "console=ttymxc0,115200n8"
      "earlycon=ttymxc0,115200n8"
      "boot.shell_on_fail"
      "fbcon=map:0"
      #"root=/dev/disk/by-label/NIXOS"
      #"findiso=/nixos.iso"
      ];

    loader = 
      {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      
      ##grub.enable = true;
      #grub.efiSupport = true;
      #grub.efiInstallAsRemovable = true;
      #grub.device = "nodev";
      #grub.extraConfig =  ''
      #  iso_path /nixos.iso
      #  textmode true
      #  '';  
      };
  

    initrd = 
      {
      availableKernelModules = 
        [
          "iso9660"
          "usbserial"
          "usb_storage"
          "squashfs"
          "nls_cp437"
          "overlay"
        ];
      

      supportedFilesystems = 
        [
          "qnx6"
          "btrfs"
          "squashfs"
          "so9660"
          "overlay"
          "vfat"
        ];

      #network = {
      #    enable = true;
      #    ssh = {
      #      enable = true;
      #      hostKeys = [ ./dummy_rsa ];
      #      authorizedKeys = config.users.users.abb.openssh.authorizedKeys.keys;
      #    };

       #   # Set the shell profile to meet SSH connections with a decryption
       #   # prompt that writes to /tmp/continue if successful.
       #   postCommands = let
       #     disk = "/dev/disk/by-label/crypt";
       #   in ''
       #     # echo 'cryptsetup open ${disk} root --type luks && echo > /tmp/continue' >> /root/.profile
       #     # echo 'starting sshd...'
       #     echo 'sh && echo > /tmp/continue' >> /root/.profile
       #     echo 'YES ... starting ssh ...'
       #   '';
      #};

      # Block the boot process until /tmp/continue is written to
      #postDeviceCommands = ''
      #  echo 'I am waiting for /tmp/continue ...'
      #  mkfifo /tmp/continue
      #  cat /tmp/continue
      #'';
      };
    };


    sdImage = 
      {
      # We have to use custom boot firmware since we do not support
      # StarFive's Fedora MMC partition layout. Thus, we include this in
      # the image's firmware partition so the user can flash the custom firmware.
      
      populateFirmwareCommands = ''
      '';
     
      populateRootCommands = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
      '';
   
      };
}
