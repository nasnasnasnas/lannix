{inputs, ...}: {
  flake.modules.nixos.leah-framework = {
    pkgs,
    modulesPath,
    config,
    lib,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ];

    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/83ce626e-dae6-44a7-8599-fb3db1d1a585";
      fsType = "ext4";
    };

    boot.initrd.luks.devices."luks-fa93d340-5b88-4696-ae1a-cda4db5580b1".device = "/dev/disk/by-uuid/fa93d340-5b88-4696-ae1a-cda4db5580b1";

    boot.initrd.luks.devices."luks-b78f2055-2df8-4686-a08f-414894dab060".device = "/dev/disk/by-uuid/b78f2055-2df8-4686-a08f-414894dab060";

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/21A2-2848";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/083c8bbc-e20c-4e9f-9cfa-958185839a15";}
    ];

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp192s0.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
