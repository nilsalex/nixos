{ hostname, hardwareConfig }:

{
  config,
  pkgs,
  lib,
  ...
}:
let
  baseSopsSecret = config.my.mail.sopsMbsync && builtins.pathExists ./secrets/mail.yaml;
in
{
  # The personal host enables this by default. The work wrapper extends the
  # alexntng host and opts in explicitly once it has its own sops secret.
  my.mail.sopsMbsync = lib.mkDefault (hostname == "linux");

  nixpkgs.config.allowUnfree = true;

  imports = [
    hardwareConfig
    ./modules/mail.nix
  ];

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

  # Machine-consumed secrets (e.g. mail passwords) come from sops-nix so
  # mbsync/msmtp never invoke gpg-agent. The decryption key is a local age key,
  # generated once with `age-keygen -o /var/lib/sops-nix/key.txt`.
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets = lib.mkIf baseSopsSecret {
    "mail-password" = {
      sopsFile = ./secrets/mail.yaml;
      # Root-only; only the mbsync service receives it, via LoadCredential.
      mode = "0400";
    };
  };

  my.mail.mbsyncCredentials = lib.mkIf baseSopsSecret {
    personal = config.sops.secrets."mail-password".path;
  };

  users.groups.mail = { };

  # Dedicated account for the background mail sync. It shares the Maildir with
  # nils through the `mail` group, but is the only user that can read the
  # mail password.
  users.users.mbsync = {
    isSystemUser = true;
    group = "mail";
    home = "/var/lib/mbsync";
    createHome = true;
    description = "mbsync mail synchronization";
  };

  systemd.services.mbsync = lib.mkIf config.my.mail.sopsMbsync {
    description = "mbsync mailbox synchronization";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "mbsync";
      Group = "mail";
      UMask = "0007";
      Environment = [ "HOME=/var/lib/mbsync" ];
      LoadCredential = lib.mapAttrsToList (
        name: path: "${name}:${path}"
      ) config.my.mail.mbsyncCredentials;
      ExecStart = "${pkgs.isync}/bin/mbsync -c /home/nils/.config/isyncrc --all";
      # mbsync creates Maildir files with mode 0600, which masks inherited
      # ACLs. Re-apply the shared group ACL after every sync.
      ExecStartPost = [
        "+${pkgs.acl}/bin/setfacl -R -m g:mail:rwX /var/lib/mail/nils"
        "+${pkgs.acl}/bin/setfacl -R -d -m g:mail:rwX /var/lib/mail/nils"
      ];
    };
  };

  systemd.timers.mbsync = lib.mkIf config.my.mail.sopsMbsync {
    description = "mbsync mailbox synchronization";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Unit = "mbsync.service";
    };
  };

  # Hosts that don't use the sops/dedicated-user setup keep the old
  # home-manager user service (which is what the work wrapper relies on).
  home-manager.users.nils.services.mbsync.enable = !config.my.mail.sopsMbsync;

  # Keep the shared Maildir writable by both nils and the mbsync user. The
  # default ACL makes new files/directories inherit group write as well.
  system.activationScripts.maildir-permissions = lib.mkIf config.my.mail.sopsMbsync {
    deps = [ "users" ];
    text = ''
      ${pkgs.coreutils}/bin/install -d -o root -g mail -m 0750 /var/lib/mail
      ${pkgs.coreutils}/bin/install -d -o nils -g mail -m 2770 /var/lib/mail/nils
      ${pkgs.coreutils}/bin/chgrp -R mail /var/lib/mail/nils
      ${pkgs.coreutils}/bin/chmod -R g+rwX /var/lib/mail/nils
      ${pkgs.acl}/bin/setfacl -R -m g:mail:rwX /var/lib/mail/nils
      ${pkgs.acl}/bin/setfacl -R -d -m g:mail:rwX /var/lib/mail/nils
      ${pkgs.acl}/bin/setfacl -m u:mbsync:x /home/nils
      if [ -d /home/nils/.config ]; then
        ${pkgs.acl}/bin/setfacl -m u:mbsync:x /home/nils/.config
      fi
    '';
  };

  hardware.graphics.enable = true;

  hardware.bluetooth.enable = true;

  hardware.logitech.wireless = {
    enable = true;
  };

  programs.solaar.enable = true;

  time.timeZone = "Europe/Berlin";

  users.users.nils = {
    isNormalUser = true;
    home = "/home/nils";
    description = "Nils Alex";
    extraGroups = [
      "wheel"
      "video"
      "networkmanager"
      "kvm"
      "mail"
    ];
  };

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      allowed-users = [ "nils" ];
      extra-trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
      extra-substituters = [
        "https://cache.iog.io"
        "https://cache.numtide.com"
      ];
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

  # Make Electron apps (Slack, VS Code, Obsidian) run native Wayland under
  # every Wayland session. X11-only apps fall back to XWayland: sway's
  # built-in support, or xwayland-satellite under niri (installed by the
  # home-manager niri module).
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  security.polkit.enable = true;

  # Allow nils to trigger the dedicated mbsync unit from neomutt without
  # exposing the sops credentials or requiring an interactive polkit prompt.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "mbsync.service" &&
          subject.user == "nils") {
        return polkit.Result.YES;
      }
    });
  '';
  security.rtkit.enable = true;
  security.pam.services.swaylock.text = "auth include login";

  security.pki.certificateFiles =
    if builtins.pathExists ./cacerts then
      map (file: ./. + "/cacerts/${file}") (builtins.attrNames (builtins.readDir ./cacerts))
    else
      [ ];

  programs.dconf.enable = true;

  programs.niri.enable = true;

  # Register sway as a fallback session for the greeter. Niri (the primary)
  # is registered by programs.niri, which also mkDefault's defaultSession to
  # "niri" — greetd ignores that setting, so tuigreet alone decides (with
  # --remember-session persisting the last manual choice).
  services.displayManager.sessionPackages = [ pkgs.sway ];

  services.greetd = {
    enable = true;
    # tuigreet is a text-based greeter; this binds greetd to tty1 with
    # TTYReset/TTYVHangup and journals stderr, so boot/systemd messages can't
    # clobber the TUI on VT1.
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session";
        user = "greeter";
      };
    };
  };

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
    packages = [ pkgs.gcr_3 ];
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

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    dockerSocket.enable = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
