{inputs, ...}: {
  flake.modules.nixos.magicplank = {
    pkgs,
    modulesPath,
    lib,
    config,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/01ea8b13-77c0-4efb-85d8-27a350210260";
      fsType = "btrfs";
      options = ["subvol=@"];
    };

    fileSystems."/nix" = {
      device = "/dev/disk/by-uuid/01ea8b13-77c0-4efb-85d8-27a350210260";
      fsType = "btrfs";
      options = ["subvol=@nix"];
    };

    fileSystems."/home" = {
      device = "/dev/disk/by-uuid/01ea8b13-77c0-4efb-85d8-27a350210260";
      fsType = "btrfs";
      options = ["subvol=@home"];
    };

    fileSystems."/var/log" = {
      device = "/dev/disk/by-uuid/01ea8b13-77c0-4efb-85d8-27a350210260";
      fsType = "btrfs";
      options = ["subvol=@log"];
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/24CB-03FF";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };

    swapDevices = [];

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.enp194s0f0u2.useDHCP = lib.mkDefault true;
    # networking.interfaces.eth0.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
