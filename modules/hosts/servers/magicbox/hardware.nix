{...}: {
  flake.modules.nixos.magicbox = {
    config,
    lib,
    pkgs,
    ...
  }: {
    hardware.enableRedistributableFirmware = false;

    # Keep AMD CPU security/stability microcode updates.
    hardware.cpu.amd.updateMicrocode = true;
  
    # Keep this if Wi-Fi may be used.
    hardware.wirelessRegulatoryDatabase = true;
  
    hardware.firmware = [
      (pkgs.runCommand "rtw8852a-firmware" {} ''
        install -Dm644 \
          ${pkgs.linux-firmware}/lib/firmware/rtw89/rtw8852a_fw.bin.zst \
          $out/lib/firmware/rtw89/rtw8852a_fw.bin.zst
      '')
    ];

    hardware.graphics.enable = false;

    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
    };

    hardware.nvidia-container-toolkit.enable = true;
    virtualisation.docker.daemon.settings.features.cdi = true;
    virtualisation.docker.rootless.daemon.settings.features.cdi = true;

    boot.loader.systemd-boot.enable = true;

    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/ebaffbfc-6dbc-4ffa-ab23-3245a15d7301";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/E6D8-6AA1";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    fileSystems."/mnt/windows" = {
      device = "/dev/disk/by-label/UwU";
      fsType = "ntfs3";
      options = ["nofail" "x-systemd.device-timeout=5s" "uid=1000" "gid=100" "umask=022"];
    };

    fileSystems."/mnt/extra" = {
      device = "/dev/disk/by-label/magicbox-extra";
      fsType = "ext4";
      options = ["nofail" "x-systemd.device-timeout=5s"];
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/738ff207-1ca6-466b-a04c-43b2c41d31cc";}
    ];

    networking.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
