{inputs, ...}: {
  flake.modules.nixos.nea-desktop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    hardware.enableRedistributableFirmware = true;
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
    boot.initrd.kernelModules = ["amdgpu"];
    boot.kernelModules = ["kvm-amd"];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Match upstream's cache and retain the desktop's BORE scheduler.
    nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];
    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
    nix.settings = {
      extra-substituters = ["https://cache.lantian.pub/lantian"];
      extra-trusted-public-keys = ["lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="];
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/5db81415-d81e-44c9-a833-6467c781ed26";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/0C37-6205";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
    swapDevices = [{device = "/dev/disk/by-uuid/2c09953d-79a9-4307-9bfa-f9f1887a33b4";}];
    networking.useDHCP = lib.mkDefault true;
  };
}
