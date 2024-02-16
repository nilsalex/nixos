{ config, pkgs, ... }:

let
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;

    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
      gsettings set $gnome_schema gtk-theme 'Adwaita-dark'
      gsettings set $gnome_schema color-scheme 'prefer-dark'
    '';
  };

in {
  home.username = "nils";
  home.homeDirectory = "/home/nils";

  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    google-chrome
    pulseaudio
    pavucontrol
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    noto-fonts-extra
    dejavu_fonts
    liberation_ttf
    bemenu
    blender
    magic-wormhole
    prusa-slicer
    gcc
    dejavu_fonts
    font-awesome
    openmoji-color
    ripgrep
    fd
    gnumake
    unzip
    wget
    tree-sitter
    wl-clipboard
    lua-language-server
    texlive.combined.scheme-medium
    mupdf
    nodePackages.typescript-language-server
    zoom-us
    xdg_utils
    slack
    rnix-lsp
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    glib
    gsettings-desktop-schemas
    libappindicator
    configure-gtk
    gopass
    gopass-jsonapi
    thunderbird
    yubikey-manager
    solaar
    dig
    htop
    feh
    grim
    slurp
    gimp
    freeplane
    feh
    nodejs_21
    nodePackages."@tailwindcss/language-server"
    nodePackages.typescript-language-server
    nodePackages.dockerfile-language-server-nodejs
    playwright-driver.browsers
    dotnet-sdk_6
    jetbrains.rider
    tree
    wtype
    llm-ls
  ];
  
  home.sessionVariables = let
    schema = pkgs.gsettings-desktop-schemas;
    schemadir = "${schema}/share/gsettings-schemas/${schema.name}";
  in {
    NIXOS_OZONE_WL = "1";
    XDG_DATA_DIRS = schemadir + '':$XDG_DATA_DIRS'';
    _JAVA_AWT_WM_NONREPARENTING = "1";
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };

  home.shellAliases = {
    sway = "sway > ~/.local/var/log/sway.log 2>&1";
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    initExtra = ''
      export PS1='[\u@\h \W]\n\$ '
    '';
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
    };
    theme = "One Dark";
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    pinentryFlavor = "gnome3";
  };

  programs.gpg.enable = true;

  programs.swaylock = {
    enable = true;
    settings = {
      color = "000000";
    };
  };

  programs.waybar = {
    enable = true;
    settings = [
{
  position = "bottom";
  height = 16;
  spacing = 4;
  modules-left = [
    "sway/workspaces"
    "sway/mode"
    "sway/scratchpad"
    "custom/media"
  ];
  modules-center = [
    "sway/window"
  ];
  modules-right = [
    "mpd"
    "idle_inhibitor"
    "pulseaudio"
    "network"
    "cpu"
    "memory"
    "keyboard-state"
    "sway/language"
    "battery"
    "battery#bat2"
    "clock"
    "tray"
  ];
  keyboard-state = {
    numlock = true;
    capslock = true;
    format = "{name} {icon}";
    format-icons = {
      locked = "";
      unlocked = "";
    };
  };
  "sway/mode" = {
    format = "<span style=\"italic\">{}</span>";
  };
  "sway/scratchpad" = {
    format = "{icon} {count}";
    show-empty = false;
    format-icons = [
      ""
      ""
    ];
    tooltip = true;
    tooltip-format = "{app}: {title}";
  };
  mpd = {
    format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
    format-disconnected = "Disconnected ";
    format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
    unknown-tag = "N/A";
    interval = 2;
    consume-icons = {
      on = " ";
    };
    random-icons = {
      off = "<span color=\"#f53c3c\"></span> ";
      on = " ";
    };
    repeat-icons = {
      on = " ";
    };
    single-icons = {
      on = "1 ";
    };
    state-icons = {
      paused = "";
      playing = "";
    };
    tooltip-format = "MPD (connected)";
    tooltip-format-disconnected = "MPD (disconnected)";
  };
  idle_inhibitor = {
    format = "{icon}";
    format-icons = {
      activated = "";
      deactivated = "";
    };
  };
  tray = {
    spacing = 10;
  };
  clock = {
    tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    format-alt = "{:%Y-%m-%d}";
  };
  cpu = {
    format = "{usage}% ";
    tooltip = false;
  };
  memory = {
    format = "{}% ";
  };
  battery = {
    states = {
      warning = 30;
      critical = 15;
    };
    format = "{capacity}% {icon}";
    format-charging = "{capacity}% ";
    format-plugged = "{capacity}% ";
    format-alt = "{time} {icon}";
    format-icons = [
      ""
      ""
      ""
      ""
      ""
    ];
  };
  "battery#bat2" = {
    bat = "BAT2";
  };
  network = {
    format-wifi = "{essid} ({signalStrength}%) ";
    format-ethernet = "{ipaddr}/{cidr} ";
    tooltip-format = "{ifname} via {gwaddr} ";
    format-linked = "{ifname} (No IP) ";
    format-disconnected = "Disconnected ⚠";
    format-alt = "{ifname}: {ipaddr}/{cidr}";
  };
  pulseaudio = {
    format = "{volume}% {icon} {format_source}";
    format-bluetooth = "{volume}% {icon} {format_source}";
    format-bluetooth-muted = " {icon} {format_source}";
    format-muted = " {format_source}";
    format-source = "{volume}% ";
    format-source-muted = "";
    format-icons = {
      headphone = "";
      hands-free = "";
      headset = "";
      phone = "";
      portable = "";
      car = "";
      default = [
        ""
        ""
        ""
      ];
    };
    on-click = "pavucontrol";
  };
  "custom/media" = {
    format = "{icon} {}";
    return-type = "json";
    max-length = 40;
    format-icons = {
      spotify = "";
      default = "🎜";
    };
    escape = true;
    exec = "$HOME/.config/waybar/mediaplayer.py 2> /dev/null";
  };
}
    ];
  };

  services.swayidle = {
    enable = true;
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
    timeouts = [
      {
        timeout = 120;
        command = ''${pkgs.sway}/bin/swaymsg "output * dpms off"'';
        resumeCommand = ''${pkgs.sway}/bin/swaymsg "output * dpms on"'';
      }
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
  };

  services.kanshi = {
    enable = false;
    profiles = {
      undocked = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
        ];
      };
      docked = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Dell Inc. DELL U2719D 92WTV13";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Dell Inc. DELL U2719D FHMTLS2";
            status = "enable";
            position = "2560,0";
          }
        ];
      };
    };
  };

  services.mako = {
    enable = true;
    defaultTimeout = 30000;
  };

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "kitty -d $(${pkgs.swaycwd}/bin/swaycwd)";
      input = {
        "*" = {
          xkb_numlock = "enabled";
          xkb_options = "compose:ralt";
        };
      };
      output = {
        eDP-1 = {
          scale = "1.3";
        };
      };
      menu = "bemenu-run";
      fonts = {
        names = [ "FiraCode Nerd Font" ];
      };
      bars = [
        {
          command = "${pkgs.waybar}/bin/waybar";
        }
      ];
      floating.titlebar = false;
      window.titlebar = false;
    };
    extraConfig = ''
      # Move workspaces
      bindsym Mod4+Control+Shift+l move workspace to output right
      bindsym Mod4+Control+Shift+h move workspace to output left

      # Brightness
      bindsym XF86MonBrightnessDown exec light -U 5
      bindsym XF86MonBrightnessUp exec light -A 5

      # Volume
      bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'
      bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'
      bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'

      # Locking
      bindsym Mod4+Shift+s exec swaylock

      # Set output for docked/undocked mode
      bindsym Mod4+Shift+d exec swaymsg 'output "Dell Inc. DELL U2719D 92WTV13" position 0 0' && swaymsg 'output "Dell Inc. DELL U2719D FHMTLS2" position 2560 0' && swaymsg 'output eDP-1 disable'
      bindsym Mod4+Shift+u exec swaymsg 'output "eDP-1" enable'

      # # restart stuff
      # exec systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
      # exec systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr

      # configure gtk
      exec configure-gtk
    '';
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  programs.ssh.enable = true;

  home.file.".config/gopass/gopass_wrapper.sh" = {
    text = ''
#!/bin/sh

export GPG_TTY="$(tty)"

if [ -f ~/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
	source ~/.gpg-agent-info
	export GPG_AGENT_INFO
else
	eval $(gpg-agent --daemon)
fi

${pkgs.gopass-jsonapi}/bin/gopass-jsonapi listen

exit $?
  '';
    executable = true;
  };

  home.file.".config/google-chrome/NativeMessagingHosts/com.justwatch.gopass.json".text = ''
{
  "name": "com.justwatch.gopass",
  "description": "Gopass wrapper to search and return passwords",
  "path": "/home/nils/.config/gopass/gopass_wrapper.sh",
  "type": "stdio",
  "allowed_origins": [
      "chrome-extension://kkhfnlkhiapbiehimabddjbimfaijdhk/"
  ]
}
  '';

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      vscodevim.vim
    ];
    userSettings = {
      "window.titleBarStyle" = "custom";
    };
  };

  programs.direnv.enable = true;

  programs.readline = {
    enable = true;
    bindings = {
      "\\e[A" = "history-search-backward";
      "\\e[B" = "history-search-forward";
    };
  };
}
