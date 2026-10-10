{
  pkgs,
  config,
  ...
}:

let
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;

    text =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        gsettings set $gnome_schema gtk-theme 'Adwaita-dark'
        gsettings set $gnome_schema color-scheme 'prefer-dark'
      '';
  };

  npm-groovy-lint = pkgs.callPackage ./derivations/npm-groovy-lint/default.nix { pkgs = pkgs; };

  inkscape-silhouette = pkgs.callPackage ./derivations/inkscape/inkscape-silhouette.nix {
    pkgs = pkgs;
  };

  yktotp-jsonapi = pkgs.callPackage ./derivations/yktotp/yktotp-jsonapi.nix { pkgs = pkgs; };

  browser-launcher = pkgs.callPackage ./derivations/browser-launcher { pkgs = pkgs; };

  microsandbox = pkgs.callPackage ./derivations/microsandbox { };

  # Combine .NET SDK 9 and 10 into a single SDK that contains both runtimes
  # This allows csharp-ls (which needs .NET 10) and .NET 9 projects to coexist
  dotnet-combined = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnet-sdk_9
    pkgs.dotnet-sdk_10
  ];

  mailAccount = "nils" + "@" + "famalex.de";

in
{
  home.username = "nils";

  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    google-chrome
    pulseaudio
    pavucontrol
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    dejavu_fonts
    liberation_ttf
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
    playerctl
    lua51Packages.luarocks
    lua51Packages.lua
    lua-language-server
    stylua
    texliveMedium
    mupdf
    xdg-utils
    slack
    nil
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    glib
    gsettings-desktop-schemas
    libappindicator
    configure-gtk
    gopass
    gopass-jsonapi
    git-credential-gopass
    yubikey-manager
    solaar
    dig
    htop
    feh
    grim
    slurp
    gimp
    freemind
    freeplane
    feh
    nodejs_24
    tailwindcss-language-server
    typescript-language-server
    dockerfile-language-server
    pnpm
    dotnet-combined
    omnisharp-roslyn
    jetbrains.rider
    tree
    ncdu
    wtype
    wlopm
    fuzzel
    jq
    libreoffice
    tenv
    terraform-ls
    terraform-docs
    tflint
    restic
    zig
    zls
    (inkscape-with-extensions.override { inkscapeExtensions = [ inkscape-silhouette ]; })
    browser-launcher
    glow
    python3
    pyright
    mpv
    kubectl
    k9s
    kubectx
    kubernetes-helm
    stern
    nixfmt
    nixd
    npm-groovy-lint
    haskellPackages.fourmolu
    haskellPackages.stack
    haskellPackages.cabal-install
    ghostty
    handy
    vscode-langservers-extracted
    ausweisapp
    urlscan
    llm
    git-absorb
    mosh
    csharpier
    csharp-ls
    tailscale
    gnupg
    obs-studio
    libnotify
    brightnessctl
    gh
    uv
    zoxide
    fzf
    bubblewrap
    inotify-info
    llm-agents.nono
    llm-agents.pi
    llm-agents.herdr
    libsecret
    microsandbox
    obsidian
  ];

  home.sessionVariables =
    let
      schema = pkgs.gsettings-desktop-schemas;
      schemadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in
    {
      XDG_DATA_DIRS = schemadir + ":$XDG_DATA_DIRS";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      DOTNET_ROOT = "${dotnet-combined}/share/dotnet";
      PATH = "$HOME/.dotnet/tools:$PATH";
    };

  home.shellAliases = {
    sway = "sway > ~/.local/var/log/sway.log 2>&1";
    groot = ''cd "$(git root)"'';
    # opencode-gh = ''export GITHUB_TOKEN="$(gh auth token)" && opencode'';
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    initExtra = ''
      # export shell_stack="B''${shell_stack}"
      # export PS1="[\u@\h \W] ''${shell_stack}\n\$ "
      [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
    '';
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
    };
    themeFile = "OneDark";
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      alias = {
        root = "rev-parse --show-toplevel";
      };
      init = {
        defaultBranch = "main";
      };
      credential = {
        helper = "gopass";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      # Enable shared PC/SC mode so both GnuPG and ykman can access YubiKey
      pcsc-shared = true;
      # Disable direct CCID to force use of pcscd for better compatibility
      disable-ccid = true;
    };
  };

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
          "niri/workspaces"
          "custom/media"
        ];
        modules-center = [
          "sway/window"
          "niri/window"
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
          "niri/language"
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
          format = ''<span style="italic">{}</span>'';
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
            off = ''<span color="#f53c3c"></span> '';
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
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
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
    events = {
      "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
    };
    timeouts = [
      {
        timeout = 120;
        command = "${pkgs.wlopm}/bin/wlopm --off '*'";
        resumeCommand = "${pkgs.wlopm}/bin/wlopm --on '*'";
      }
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
  };

  services.kanshi = {
    enable = true;
    settings = [
      {
        output.criteria = "eDP-1";
        output.scale = 1.3;
      }
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
        ];
      }
      {
        profile.name = "docked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Dell Inc. DELL U2719D 92WTV13";
            status = "enable";
            position = "1477,0";
          }
          {
            criteria = "Dell Inc. DELL U2719D FHMTLS2";
            status = "enable";
            position = "4037,0";
          }
        ];
      }
      {
        profile.name = "docked2";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Dell Inc. DELL U2719D JFSKNS2";
            status = "enable";
            position = "1477,0";
          }
          {
            criteria = "Dell Inc. DELL U2719D CCSKNS2";
            status = "enable";
            position = "4037,0";
          }
        ];
      }
      {
        profile.name = "ultrawide";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Dell Inc. DELL U3824DW HVPMZR3";
            status = "enable";
          }
        ];
      }
      {
        profile.name = "single";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "*";
            status = "enable";
            position = "1477,0";
          }
        ];
      }
    ];
  };

  services.mako = {
    enable = true;
    settings.default-timeout = 30000;
  };

  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;
    config = {
      modifier = "Mod4";
      terminal = "kitty -d $(${pkgs.swaycwd}/bin/swaycwd)";
      input = {
        "*" = {
          xkb_numlock = "enabled";
          xkb_options = "compose:ralt";
        };
      };
      menu = "fuzzel";
      fonts = {
        names = [ "FiraCode Nerd Font" ];
      };
      bars = [ { command = "${pkgs.waybar}/bin/waybar"; } ];
      floating.titlebar = false;
      window.titlebar = false;
      startup = [
        {
          command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway";
          always = true;
        }
      ];
    };
    extraSessionCommands = ''
      export XDG_CURRENT_DESKTOP=sway
    '';
    extraConfig = ''
      # Move workspaces
      bindsym Mod4+Control+Shift+l move workspace to output right
      bindsym Mod4+Control+Shift+h move workspace to output left

      # Brightness
      bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
      bindsym XF86MonBrightnessUp exec brightnessctl set +5%

      # Volume
      bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'
      bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'
      bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'

      # Locking
      bindsym Mod4+Shift+s exec swaylock

      # Set output for docked/undocked mode
      bindsym Mod4+Shift+d exec swaymsg 'output "Dell Inc. DELL U2719D 92WTV13" position 0 0' && swaymsg 'output "Dell Inc. DELL U2719D FHMTLS2" position 2560 0' && swaymsg 'output eDP-1 disable'
      bindsym Mod4+Shift+u exec swaymsg 'output "eDP-1" enable'

      # YubiKey OTP
      bindsym Mod4+o exec ~/.local/bin/yk-otp.sh

      # gopass
      bindsym Mod4+p exec ~/.local/bin/gopass-menu.sh
      bindsym Mod4+Shift+p exec ~/.local/bin/gopass-type.sh

      # NetworkManager
      bindsym Mod4+c exec ~/.local/bin/nm-menu.sh

      # Browser launcher
      bindsym Mod4+g exec browser-launcher

      # Handy speech-to-text (global shortcut capture is broken on sway;
      # signal the running instance instead, see Handy issue #1870)
      bindsym Alt+space exec handy --toggle-transcription

      # configure gtk
      exec_always configure-gtk
      exec handy --start-hidden

      exec_always systemctl --user restart kanshi.service
    '';
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
  };

  wayland.windowManager.niri = {
    enable = true;
    systemd.enable = true;
    settings = {
      prefer-no-csd = { };
      hotkey-overlay.skip-at-startup = { };
      input.keyboard = {
        numlock = { };
        xkb.options = "compose:ralt";
      };
      binds = {
        # Programs
        "Mod+T" = {
          _props.hotkey-overlay-title = "Open a Terminal";
          spawn = [ "kitty" ];
        };
        "Mod+D" = {
          _props.hotkey-overlay-title = "Run an Application: fuzzel";
          spawn = [ "fuzzel" ];
        };
        "Mod+Shift+S" = {
          _props.hotkey-overlay-title = "Lock the Screen";
          spawn = [ "swaylock" ];
        };
        "Super+Alt+L" = {
          _props.hotkey-overlay-title = "Lock the Screen";
          spawn = [ "swaylock" ];
        };

        # Windows and columns
        "Mod+Shift+Slash".show-hotkey-overlay = { };
        "Mod+Q" = {
          _props.repeat = false;
          close-window = { };
        };
        "Mod+O" = {
          _props.repeat = false;
          toggle-overview = { };
        };
        "Mod+H" = {
          focus-column-left = { };
        };
        "Mod+J" = {
          focus-window-down = { };
        };
        "Mod+K" = {
          focus-window-up = { };
        };
        "Mod+L" = {
          focus-column-right = { };
        };
        "Mod+Left" = {
          focus-column-left = { };
        };
        "Mod+Down" = {
          focus-window-down = { };
        };
        "Mod+Up" = {
          focus-window-up = { };
        };
        "Mod+Right" = {
          focus-column-right = { };
        };
        "Mod+Ctrl+H" = {
          move-column-left = { };
        };
        "Mod+Ctrl+J" = {
          move-window-down = { };
        };
        "Mod+Ctrl+K" = {
          move-window-up = { };
        };
        "Mod+Ctrl+L" = {
          move-column-right = { };
        };
        "Mod+Ctrl+Left" = {
          move-column-left = { };
        };
        "Mod+Ctrl+Down" = {
          move-window-down = { };
        };
        "Mod+Ctrl+Up" = {
          move-window-up = { };
        };
        "Mod+Ctrl+Right" = {
          move-column-right = { };
        };
        "Mod+Home" = {
          focus-column-first = { };
        };
        "Mod+End" = {
          focus-column-last = { };
        };
        "Mod+Ctrl+Home" = {
          move-column-to-first = { };
        };
        "Mod+Ctrl+End" = {
          move-column-to-last = { };
        };

        # Monitors (workspace to monitor replaces sway's move workspace to output)
        "Mod+Shift+H" = {
          focus-monitor-left = { };
        };
        "Mod+Shift+J" = {
          focus-monitor-down = { };
        };
        "Mod+Shift+K" = {
          focus-monitor-up = { };
        };
        "Mod+Shift+L" = {
          focus-monitor-right = { };
        };
        "Mod+Shift+Left" = {
          focus-monitor-left = { };
        };
        "Mod+Shift+Down" = {
          focus-monitor-down = { };
        };
        "Mod+Shift+Up" = {
          focus-monitor-up = { };
        };
        "Mod+Shift+Right" = {
          focus-monitor-right = { };
        };
        "Mod+Ctrl+Shift+H" = {
          move-column-to-monitor-left = { };
        };
        "Mod+Ctrl+Shift+J" = {
          move-column-to-monitor-down = { };
        };
        "Mod+Ctrl+Shift+K" = {
          move-column-to-monitor-up = { };
        };
        "Mod+Ctrl+Shift+L" = {
          move-column-to-monitor-right = { };
        };
        "Mod+Ctrl+Shift+Left" = {
          move-column-to-monitor-left = { };
        };
        "Mod+Ctrl+Shift+Down" = {
          move-column-to-monitor-down = { };
        };
        "Mod+Ctrl+Shift+Up" = {
          move-column-to-monitor-up = { };
        };
        "Mod+Ctrl+Shift+Right" = {
          move-column-to-monitor-right = { };
        };

        # Workspaces
        "Mod+U" = {
          focus-workspace-down = { };
        };
        "Mod+I" = {
          focus-workspace-up = { };
        };
        "Mod+Page_Down" = {
          focus-workspace-down = { };
        };
        "Mod+Page_Up" = {
          focus-workspace-up = { };
        };
        "Mod+Ctrl+U" = {
          move-column-to-workspace-down = { };
        };
        "Mod+Ctrl+I" = {
          move-column-to-workspace-up = { };
        };
        "Mod+Ctrl+Page_Down" = {
          move-column-to-workspace-down = { };
        };
        "Mod+Ctrl+Page_Up" = {
          move-column-to-workspace-up = { };
        };
        "Mod+Shift+U" = {
          move-workspace-down = { };
        };
        "Mod+Shift+I" = {
          move-workspace-up = { };
        };
        "Mod+Shift+Page_Down" = {
          move-workspace-down = { };
        };
        "Mod+Shift+Page_Up" = {
          move-workspace-up = { };
        };

        # Mouse wheel
        "Mod+WheelScrollDown" = {
          _props.cooldown-ms = 150;
          focus-workspace-down = { };
        };
        "Mod+WheelScrollUp" = {
          _props.cooldown-ms = 150;
          focus-workspace-up = { };
        };
        "Mod+Ctrl+WheelScrollDown" = {
          _props.cooldown-ms = 150;
          move-column-to-workspace-down = { };
        };
        "Mod+Ctrl+WheelScrollUp" = {
          _props.cooldown-ms = 150;
          move-column-to-workspace-up = { };
        };
        "Mod+WheelScrollLeft" = {
          focus-column-left = { };
        };
        "Mod+WheelScrollRight" = {
          focus-column-right = { };
        };
        "Mod+Shift+WheelScrollDown" = {
          focus-column-right = { };
        };
        "Mod+Shift+WheelScrollUp" = {
          focus-column-left = { };
        };
        "Mod+Ctrl+WheelScrollLeft" = {
          move-column-left = { };
        };
        "Mod+Ctrl+WheelScrollRight" = {
          move-column-right = { };
        };
        "Mod+Ctrl+Shift+WheelScrollDown" = {
          move-column-right = { };
        };
        "Mod+Ctrl+Shift+WheelScrollUp" = {
          move-column-left = { };
        };

        # Workspace indices
        "Mod+1" = {
          focus-workspace = [ 1 ];
        };
        "Mod+2" = {
          focus-workspace = [ 2 ];
        };
        "Mod+3" = {
          focus-workspace = [ 3 ];
        };
        "Mod+4" = {
          focus-workspace = [ 4 ];
        };
        "Mod+5" = {
          focus-workspace = [ 5 ];
        };
        "Mod+6" = {
          focus-workspace = [ 6 ];
        };
        "Mod+7" = {
          focus-workspace = [ 7 ];
        };
        "Mod+8" = {
          focus-workspace = [ 8 ];
        };
        "Mod+9" = {
          focus-workspace = [ 9 ];
        };
        "Mod+Ctrl+1" = {
          move-column-to-workspace = [ 1 ];
        };
        "Mod+Ctrl+2" = {
          move-column-to-workspace = [ 2 ];
        };
        "Mod+Ctrl+3" = {
          move-column-to-workspace = [ 3 ];
        };
        "Mod+Ctrl+4" = {
          move-column-to-workspace = [ 4 ];
        };
        "Mod+Ctrl+5" = {
          move-column-to-workspace = [ 5 ];
        };
        "Mod+Ctrl+6" = {
          move-column-to-workspace = [ 6 ];
        };
        "Mod+Ctrl+7" = {
          move-column-to-workspace = [ 7 ];
        };
        "Mod+Ctrl+8" = {
          move-column-to-workspace = [ 8 ];
        };
        "Mod+Ctrl+9" = {
          move-column-to-workspace = [ 9 ];
        };

        # Column layout
        "Mod+BracketLeft" = {
          consume-or-expel-window-left = { };
        };
        "Mod+BracketRight" = {
          consume-or-expel-window-right = { };
        };
        "Mod+Comma" = {
          consume-window-into-column = { };
        };
        "Mod+Period" = {
          expel-window-from-column = { };
        };
        "Mod+R" = {
          switch-preset-column-width = { };
        };
        "Mod+Shift+R" = {
          switch-preset-column-width-back = { };
        };
        "Mod+Ctrl+Shift+R" = {
          switch-preset-window-height = { };
        };
        "Mod+Ctrl+R" = {
          reset-window-height = { };
        };
        "Mod+F" = {
          maximize-column = { };
        };
        "Mod+Shift+F" = {
          fullscreen-window = { };
        };
        "Mod+M" = {
          maximize-window-to-edges = { };
        };
        "Mod+Ctrl+F" = {
          expand-column-to-available-width = { };
        };
        "Mod+C" = {
          center-column = { };
        };
        "Mod+Ctrl+C" = {
          center-visible-columns = { };
        };
        "Mod+Minus" = {
          set-column-width = [ "-10%" ];
        };
        "Mod+Equal" = {
          set-column-width = [ "+10%" ];
        };
        "Mod+Shift+Minus" = {
          set-window-height = [ "-10%" ];
        };
        "Mod+Shift+Equal" = {
          set-window-height = [ "+10%" ];
        };
        "Mod+V" = {
          toggle-window-floating = { };
        };
        "Mod+Shift+V" = {
          switch-focus-between-floating-and-tiling = { };
        };
        "Mod+W" = {
          toggle-column-tabbed-display = { };
        };

        # Screenshots
        "Print" = {
          screenshot = { };
        };
        "Ctrl+Print" = {
          screenshot-screen = { };
        };
        "Alt+Print" = {
          screenshot-window = { };
        };

        # Quit and inhibitors
        "Mod+Escape" = {
          _props.allow-inhibiting = false;
          toggle-keyboard-shortcuts-inhibit = { };
        };
        "Mod+Shift+E" = {
          quit = { };
        };
        "Ctrl+Alt+Delete" = {
          quit = { };
        };
        "Mod+Shift+P" = {
          _props.hotkey-overlay-title = "Power Off Monitors";
          power-off-monitors = { };
        };

        # Brightness
        "XF86MonBrightnessDown" = {
          _props.allow-when-locked = true;
          spawn = [
            "brightnessctl"
            "set"
            "5%-"
          ];
        };
        "XF86MonBrightnessUp" = {
          _props.allow-when-locked = true;
          spawn = [
            "brightnessctl"
            "set"
            "+5%"
          ];
        };

        # Volume
        "XF86AudioRaiseVolume" = {
          _props.allow-when-locked = true;
          spawn-sh = "pactl set-sink-volume @DEFAULT_SINK@ +1%";
        };
        "XF86AudioLowerVolume" = {
          _props.allow-when-locked = true;
          spawn-sh = "pactl set-sink-volume @DEFAULT_SINK@ -1%";
        };
        "XF86AudioMute" = {
          _props.allow-when-locked = true;
          spawn-sh = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };
        "XF86AudioMicMute" = {
          _props.allow-when-locked = true;
          spawn-sh = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        };

        # Media keys
        "XF86AudioPlay" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl play-pause";
        };
        "XF86AudioStop" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl stop";
        };
        "XF86AudioPrev" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl previous";
        };
        "XF86AudioNext" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl next";
        };

        # YubiKey OTP
        "Mod+Shift+o" = {
          _props.hotkey-overlay-title = "YubiKey OTP";
          spawn-sh = "$HOME/.local/bin/yk-otp.sh";
        };

        # gopass
        "Mod+p" = {
          spawn-sh = "$HOME/.local/bin/gopass-menu.sh";
        };
        "Mod+Ctrl+p" = {
          spawn-sh = "$HOME/.local/bin/gopass-type.sh";
        };

        # NetworkManager
        "Mod+n" = {
          spawn-sh = "$HOME/.local/bin/nm-menu.sh";
        };

        # Browser launcher
        "Mod+g" = {
          spawn = [ "browser-launcher" ];
        };

        # Handy speech-to-text
        "Alt+Space" = {
          spawn = [
            "handy"
            "--toggle-transcription"
          ];
        };
      };
      _children = [
        { spawn-at-startup._args = [ "waybar" ]; }
        { spawn-at-startup._args = [ "configure-gtk" ]; }
        {
          spawn-at-startup._args = [
            "handy"
            "--start-hidden"
          ];
        }
        {
          window-rule._children = [
            {
              match._props = {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              };
              open-floating = {
                _args = [ true ];
              };
            }
          ];
        }
      ];
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
    };
    gtk4.theme = null;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "*.msb" = {
        User = "root";
        StrictHostKeyChecking = "accept-new";
        ProxyCommand = ''sh -c 'exec msb ssh serve "''\${1%%.msb}" --stdio' _ %h'';
      };
    };
  };

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

  home.file.".config/google-chrome/NativeMessagingHosts/de.nilsalex.yktotp.json".text = ''
    {
      "name": "de.nilsalex.yktotp",
      "description": "Retrieve a TOTP form a YubiKey",
      "path": "${yktotp-jsonapi}/bin/yktotp-jsonapi",
      "type": "stdio",
      "allowed_origins": [
        "chrome-extension://onhoikdmimbconmfoflbcdababjkpcim/"
      ]
    }
  '';

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };

  home.file.".mozilla/native-messaging-hosts/com.justwatch.gopass.json".text = ''
    {
      "name": "com.justwatch.gopass",
      "description": "Gopass wrapper to search and return passwords",
      "path": "/home/nils/.config/gopass/gopass_wrapper.sh",
      "type": "stdio",
      "allowed_extensions": [
        "{eec37db0-22ad-4bf1-9068-5ae08df8c7e9}"
      ]
    }
  '';

  home.file.".mozilla/native-messaging-hosts/de.nilsalex.yktotp.json".text = ''
    {
      "name": "de.nilsalex.yktotp",
      "description": "Retrieve a TOTP form a YubiKey",
      "path": "${yktotp-jsonapi}/bin/yktotp-jsonapi",
      "type": "stdio",
      "allowed_extensions": [
        "extension@yktotp"
      ]
    }
  '';

  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
      ];
      userSettings = {
        "window.titleBarStyle" = "custom";
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.readline = {
    enable = true;
    bindings = {
      "\\e[A" = "history-search-backward";
      "\\e[B" = "history-search-forward";
    };
  };

  programs.awscli = {
    enable = true;
  };

  programs.java = {
    enable = true;
  };

  accounts.email.accounts.personal = {
    primary = true;
    address = mailAccount;
    realName = "Nils Alex";
    userName = mailAccount;
    passwordCommand = "${pkgs.gopass}/bin/gopass show -o personal/email/nils@famalex.de";
    imap = {
      host = "mail.your-server.de";
      port = 993;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };
    smtp = {
      host = "mail.your-server.de";
      port = 465;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };
    neomutt = {
      enable = true;
      extraMailboxes = [
        "Drafts"
        "Junk"
        "Notes"
        "Sent"
        "Trash"
        "spambucket"
      ];
    };
    mbsync = {
      enable = true;
      create = "maildir";
    };
    notmuch = {
      enable = true;
      neomutt.enable = true;
    };
  };

  programs.neomutt =
    let
      mailcap_file = pkgs.writeText "mailcap" ''
        text/html; ${pkgs.lynx}/bin/lynx %s; nametemplate=%s.html
        text/html; ${pkgs.lynx}/bin/lynx -dump %s; nametemplate=%s.html; copiousoutput
        application/pdf; ${pkgs.mupdf}/bin/mupdf %s
        image/*; ${pkgs.feh}/bin/feh %s
      '';
    in
    {
      enable = true;
      sidebar = {
        enable = true;
      };
      sort = "threads";
      settings = {
        sort_browser = "reverse-date";
        sort_aux = "last-date-received";
        mailcap_path = "${mailcap_file}";
        envelope_from = "yes";
        edit_headers = "yes";
        mail_check_stats = "yes";
      };
      binds = [
        {
          key = "g";
          action = "noop";
        }
        {
          key = "gg";
          action = "first-entry";
        }
        {
          key = "G";
          action = "last-entry";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "R";
          action = "group-reply";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "\\CP";
          action = "sidebar-prev";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "\\CN";
          action = "sidebar-next";
        }
        {
          map = [
            "index"
            "pager"
          ];
          key = "\\CO";
          action = "sidebar-open";
        }
      ];
      macros = [
        {
          map = [
            "index"
            "pager"
          ];
          key = "<f5>";
          action = "<shell-escape>${pkgs.isync}/bin/mbsync -V -a<enter>";
        }
        {
          map = [ "index" ];
          key = "S";
          action = "<tag-prefix><enter-command>unset resolve<enter><tag-prefix><clear-flag>N<tag-prefix><enter-command>set resolve<enter><tag-prefix><save-message>=Junk<enter>";
        }
        {
          map = [ "pager" ];
          key = "S";
          action = "<save-message>=Junk<enter>";
        }
        {
          map = [ "index" ];
          key = "t";
          action = "c=<tab><tab><tab>";
        }
        {
          action = "<pipe-message> ${pkgs.urlscan}/bin/urlscan<Enter>";
          key = "\\Cb";
          map = [
            "index"
            "pager"
          ];
        }
        {
          action = "<pipe-entry> ${pkgs.urlscan}/bin/urlscan<Enter>";
          key = "\\Cb";
          map = [
            "attach"
            "compose"
          ];
        }
      ];
    };

  programs.mbsync = {
    enable = true;
  };

  programs.notmuch = {
    enable = true;
  };

  programs.msmtp = {
    enable = true;
  };

  programs.claude-code = {
    enable = false;
    settings = {
      env = {
        CLAUDE_CODE_ENABLE_TELEMETRY = "0";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };
    };
  };

  programs.zoxide = {
    enable = true;
  };

  services.mbsync = {
    enable = true;
  };

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "x-scheme-handler/http" = [ "google-chrome.desktop;" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop;" ];
      "x-scheme-handler/chrome" = [ "google-chrome.desktop;" ];
      "text/html" = [ "google-chrome.desktop;" ];
      "application/x-extension-htm" = [ "google-chrome.desktop;" ];
      "application/x-extension-html" = [ "google-chrome.desktop;" ];
      "application/x-extension-shtml" = [ "google-chrome.desktop;" ];
      "application/xhtml+xml" = [ "google-chrome.desktop;" ];
      "application/x-extension-xhtml" = [ "google-chrome.desktop;" ];
      "application/x-extension-xht" = [ "google-chrome.desktop;" ];
      "image/png" = [ "gimp.desktop;" ];
    };
    defaultApplications = {
      "application/pdf" = [ "mupdf.desktop" ];
      "text/html" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      "application/x-extension-htm" = [ "google-chrome.desktop" ];
      "application/x-extension-html" = [ "google-chrome.desktop" ];
      "application/x-extension-shtml" = [ "google-chrome.desktop" ];
      "application/xhtml+xml" = [ "google-chrome.desktop" ];
      "application/x-extension-xhtml" = [ "google-chrome.desktop" ];
      "application/x-extension-xht" = [ "google-chrome.desktop" ];
    };
  };

  home.file.".config/urlscan/config.json" = {
    text = ''
      {
          "palettes": {
              "default": [
                  [
                      "header",
                      "black",
                      "light gray",
                      "standout"
                  ],
                  [
                      "footer",
                      "black",
                      "light gray",
                      "standout"
                  ],
                  [
                      "search",
                      "black",
                      "light gray",
                      "standout"
                  ],
                  [
                      "msgtext",
                      "",
                      ""
                  ],
                  [
                      "msgtext:ellipses",
                      "white",
                      "black"
                  ],
                  [
                      "urlref:number:braces",
                      "white",
                      "black"
                  ],
                  [
                      "urlref:number",
                      "white",
                      "black",
                      "standout"
                  ],
                  [
                      "urlref:url",
                      "white",
                      "black",
                      "standout"
                  ],
                  [
                      "url:sel",
                      "black",
                      "light gray",
                      "bold"
                  ]
              ]
          }
      }
    '';
  };

  programs.opencode-profiles = {
    enable = true;
    package = pkgs.llm-agents.opencode;
    profiles.super = {
      extends = "default";
      settings = {
        plugin = [
          "superpowers@git+https://github.com/obra/superpowers.git"
        ];
      };
    };
    profiles.default = {
      context = ''
        You are on NixOS. If executables are missing, try `nix shell nixpkgs#package -c ...` or similar commands.
      '';
      #
      # ## Impact assessment before design
      #
      # Before proposing approaches for any new feature, improvement, or optimization, quantify the concrete benefit:
      # - What specific metric improves?
      # - By how much?
      # - Who benefits and in what scenario?
      #
      # If the benefit is vague or zero, recommend not doing it. "Do nothing" is always a valid option — evaluate it with the same rigor as any proposed approach.
      #
      # Don't let conceptual elegance (cleaner separation, better abstraction) override a lack of practical improvement.
      # skills = ./skills;
      skills = null;
      settings = {
        autoshare = false;
        autoupdate = false;
        disabled_providers = [ "opencode" ];
        lsp = { };
        permission = {
          bash = "ask";
          edit = "ask";
        };
        plugin = [
          "@tngtech/opencode-skainet@latest"
        ];
        provider = {
          anthropic.options.baseURL = "https://taia.tngtech.com/proxy/anthropic/v1";
          deepseek.options.baseURL = "https://taia.tngtech.com/proxy/deepseek";
          mistral.options.baseURL = "https://taia.tngtech.com/proxy/mistral/v1";
          openai.options.baseURL = "https://taia.tngtech.com/proxy/openai/v1";
          xai.options.baseURL = "https://taia.tngtech.com/proxy/x-ai/v1";
        };
        share = "disabled";
        small_model = "trustedtokens/Qwen/Qwen3.6-35B-A3B-FP8";
        # mcp = {
        #   dotnet-source-mcp = {
        #     type = "local";
        #     command = [ "dotnet-source-mcp" ];
        #     environment = {
        #       GITHUB_TOKEN = "{env:GITHUB_TOKEN}";
        #     };
        #   };
        #   github = {
        #     type = "remote";
        #     url = "https://api.githubcopilot.com/mcp/";
        #     enabled = true;
        #     oauth = false;
        #     headers = {
        #       Authorization = "Bearer {env:GITHUB_TOKEN}";
        #     };
        #   };
        # };
      };
    };
  };

  home.file.".config/io.datasette.llm/extra-openai-models.yaml" = {
    text = ''
      - model_id: chimera
        model_name: tngtech/DeepSeek-TNG-R1T2-Chimera
        api_base: "https://chat.model.tngtech.com/v1"
        api_key_name: tng-ai-token
        can_stream: true
      - model_id: llama-3.3-70b
        model_name: meta-llama/Llama-3.3-70B-Instruct
        api_base: "https://chat.model.tngtech.com/v1"
        api_key_name: tng-ai-token
        can_stream: true
      - model_id: deepseek
        model_name: deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
        api_base: "https://chat.model.tngtech.com/v1"
        api_key_name: tng-ai-token
        can_stream: true
      - model_id: gpt-4o
        model_name: gpt-4o
        api_base: "https://taia.tngtech.com/proxy/openai/v1"
        api_key_name: tng-ai-token
        can_stream: true
    '';
  };

  home.file.".config/io.datasette.llm/logs-off" = {
    text = "";
  };

  home.file.".config/io.datasette.llm/default_model.txt" = {
    text = "chimera";
  };

  home.file.".local/bin/yk-otp.sh" = {
    text = ''
      #!/usr/bin/env bash
      accounts=$(${pkgs.yubikey-manager}/bin/ykman oath accounts list 2>/dev/null)
      account=$(echo "$accounts" | ${pkgs.fuzzel}/bin/fuzzel --dmenu -p "YubiKey OTP:")
      [ -n "$account" ] && ${pkgs.yubikey-manager}/bin/ykman oath accounts code "$account" -s | ${pkgs.wl-clipboard}/bin/wl-copy \
          && ${pkgs.libnotify}/bin/notify-send "OTP copied" "$account"
    '';
    executable = true;
  };

  home.file.".local/bin/gopass-menu.sh" = {
    text = ''
      #!/usr/bin/env bash
      entries=$(${pkgs.gopass}/bin/gopass ls --flat 2>/dev/null)
      entry=$(echo "$entries" | ${pkgs.fuzzel}/bin/fuzzel --dmenu -p "gopass:")
      [ -n "$entry" ] && ${pkgs.gopass}/bin/gopass show -c "$entry" 2>/dev/null \
          && ${pkgs.libnotify}/bin/notify-send "Password copied" "$entry"
    '';
    executable = true;
  };

  home.file.".local/bin/gopass-type.sh" = {
    text = ''
      #!/usr/bin/env bash
      entries=$(${pkgs.gopass}/bin/gopass ls --flat 2>/dev/null)
      entry=$(echo "$entries" | ${pkgs.fuzzel}/bin/fuzzel --dmenu -p "gopass:")
      [ -n "$entry" ] && sleep 2 && ${pkgs.gopass}/bin/gopass show -o "$entry" 2>/dev/null | ${pkgs.wtype}/bin/wtype - \
          && ${pkgs.libnotify}/bin/notify-send "Password typed" "$entry"
    '';
    executable = true;
  };

  home.file.".local/bin/nm-menu.sh" = {
    text = ''
      #!/usr/bin/env bash
      nmcli=${pkgs.networkmanager}/bin/nmcli
      menu=${pkgs.fuzzel}/bin/fuzzel

      all=$($nmcli -t -f NAME connection)
      active=$($nmcli -t -f NAME connection show --active)

      entries=""
      while IFS= read -r conn; do
        if echo "$active" | grep -q "^''${conn}$"; then
          entries="$entries$conn [up]"$'\n'
        else
          entries="$entries$conn [down]"$'\n'
        fi
      done <<< "$all"

      selection=$(echo -n "$entries" | $menu --dmenu -p "Network:")
      [ -z "$selection" ] && exit 0

      conn=$(echo "$selection" | sed 's/ \[up\]\| \[down\]$//')

      if echo "$selection" | grep -q "\[up\]$"; then
        $nmcli c down "$conn" && ${pkgs.libnotify}/bin/notify-send "Network" "$conn disconnected"
      else
        $nmcli c up "$conn" && ${pkgs.libnotify}/bin/notify-send "Network" "$conn connected"
      fi
    '';
    executable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
    config = {
      sway = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };
    };
  };
}
