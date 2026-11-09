{ inputs, ... }: {
  flake.modules.nixos.lilac = {
    services.udev.extraRules = ''
      # Give the active local user access to iFixit FixHub serial devices.

        # FixHub Smart Station (USB VID:PID 346c:1f00)
        ACTION!="remove", SUBSYSTEM=="tty", ATTRS{idVendor}=="346c", ATTRS{idProduct}=="1f00", TAG+="uaccess", ENV{ID_MM_PORT_IGNORE}="1"
        ACTION!="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="346c", ATTR{idProduct}=="1f00", ENV{ID_MM_DEVICE_IGNORE}="1"

        # FixHub Soldering Iron (USB VID:PID 346c:1f01)
        ACTION!="remove", SUBSYSTEM=="tty", ATTRS{idVendor}=="346c", ATTRS{idProduct}=="1f01", TAG+="uaccess", ENV{ID_MM_PORT_IGNORE}="1"
        ACTION!="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="346c", ATTR{idProduct}=="1f01", ENV{ID_MM_DEVICE_IGNORE}="1"
    '';
  };
}
