{ hostname, hardwareConfig }:

{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [ hardwareConfig ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

  boot.kernelModules = [
    "kvm-intel"
    "v4l2loopback"
  ];

  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';

  hardware.firmware = [
    pkgs.linux-firmware
    pkgs.sof-firmware
  ];

  networking.hostName = hostname;
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 24727 ];
  };

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
    package = pkgs.nixVersions.latest;
    settings = {
      allowed-users = [ "nils" ];
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ];
      substituters = [ "https://cache.iog.io" ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.systemPackages = with pkgs; [
    vim
    virtio-win
  ];

  environment.etc = {
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
    };
  };

  environment.etc = {
    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
    };
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.services.swaylock.text = "auth include login";

  security.pki.certificateFiles =
    if builtins.pathExists ./cacerts then
      map (file: ./. + "/cacerts/${file}") (builtins.attrNames (builtins.readDir ./cacerts))
    else
      [ ];

  programs.light.enable = true;
  programs.dconf.enable = true;

  programs.virt-manager.enable = true;

  programs.nix-ld = {
    enable = true;
    # libraries = with pkgs; [ ];
  };

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
    scanner.interval = "Son *-*-* 04:00:00";
    updater.enable = true;
    fangfrisch.enable = true;
  };

  services.pcscd.enable = true;

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      swtpm = {
        enable = true;
      };
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
