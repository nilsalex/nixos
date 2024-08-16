{ hostname, hardwareConfig }:

{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [ hardwareConfig ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.firmware = [ pkgs.firmwareLinuxNonfree pkgs.sof-firmware ];

  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = true;

  hardware.graphics.enable = true;

  hardware.bluetooth.enable = true;

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  time.timeZone = "Europe/Berlin";

  users.users.nils = {
    isNormalUser = true;
    home = "/home/nils";
    description = "Nils Alex";
    extraGroups = [
      "wheel"
      "video"
      "networkmanager"
      "libvirtd"
      "kvm"
      "qemu-libvirtd"
      "docker"
    ];
  };

  nix = {
    package = pkgs.nixFlakes;
    settings.allowed-users = [ "nils" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.systemPackages = with pkgs; [ vim win-virtio ];

  environment.etc = {
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package
        + "/share/qemu/edk2-x86_64-secure-code.fd";
    };
  };

  environment.etc = {
    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package
        + "/share/qemu/edk2-i386-vars.fd";
    };
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.services.swaylock.text = "auth include login";

  security.pki.certificateFiles = if builtins.pathExists ./cacerts then
    map (file: ./. + "/cacerts/${file}")
    (builtins.attrNames (builtins.readDir ./cacerts))
  else
    [ ];

  programs.light.enable = true;
  programs.dconf.enable = true;

  programs.virt-manager.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # environment.etc."pipewire/pipewire.conf".text = ''
  # context.properties = {
  #   default.clock.quantum     = 2048
  #   default.clock.min-quantum = 1024
  #   default.clock.max-quantum = 4096
  # }
  # '';

  services.fwupd.enable = true;

  services.acpid.enable = true;

  services.upower.enable = true;

  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  services.dbus = {
    enable = true;
    packages = [ pkgs.gcr ];
  };

  services.clamav = {
    daemon.enable = true;
    scanner.enable = true;
    updater.enable = true;
    fangfrisch.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  services.pcscd.enable = true;

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
      swtpm = { enable = true; };
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.docker.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
