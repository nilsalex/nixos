# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ hostname, hardwareConfig }:

{ config, pkgs, ... }:

{
  imports = [ hardwareConfig ];

  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.firmware = [ pkgs.firmwareLinuxNonfree pkgs.sof-firmware ];

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ 24727 ];
  # networking.firewall.allowedUDPPorts = [ 24727 ];

  powerManagement.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = true;

  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  hardware.bluetooth.enable = true;

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  users.users.nils = {
    isNormalUser = true;
    home = "/home/nils";
    description = "Nils Alex";
    extraGroups = [
      "wheel"
      "video"
      "networkmanager"
      "libvirtd"
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  environment.systemPackages = with pkgs; [
    vim
  ];


  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.services.swaylock.text = "auth include login";

  security.pki.certificateFiles = if builtins.pathExists ./cacerts then map (file: ./. + "/cacerts/${file}") (builtins.attrNames (builtins.readDir ./cacerts)) else [];

  programs.light.enable = true;
  programs.dconf.enable = true;

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

  # virtualisation.virtualbox.host = {
  #   enable = true;
  #   enableExtensionPack = true;
  # };

  virtualisation.libvirtd.enable = true;

  virtualisation.docker.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
