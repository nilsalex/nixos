{ pkgs, ... }:

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

  mailAccount = "nils" + "@" + "famalex.de";

in
{
  home.username = "nils";
  home.homeDirectory = "/home/nils";

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
    bemenu
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
    stylua
    texlive.combined.scheme-medium
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
    nodejs_22
    tailwindcss-language-server
    nodePackages.typescript-language-server
    dockerfile-language-server
    nodePackages.pnpm
    playwright-driver.browsers
    dotnet-sdk_9
    omnisharp-roslyn
    jetbrains.rider
    tree
    ncdu
    wtype
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
    glow
    python3
    pyright
    mpv
    kubectl
    k9s
    kubectx
    kubernetes-helm
    stern
    nixfmt-rfc-style
    npm-groovy-lint
    haskellPackages.fourmolu
    haskellPackages.stack
    haskellPackages.cabal-install
    ghostty
    vscode-langservers-extracted
    ausweisapp
    urlscan
    llm
    git-absorb
    mosh
    csharpier
  ];

  home.sessionVariables =
    let
      schema = pkgs.gsettings-desktop-schemas;
      schemadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in
    {
      XDG_DATA_DIRS = schemadir + ":$XDG_DATA_DIRS";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      DOTNET_ROOT = "${pkgs.dotnet-sdk_9}/share/dotnet";
    };

  home.shellAliases = {
    sway = "sway > ~/.local/var/log/sway.log 2>&1";
    groot = ''cd "$(git root)"'';
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
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    pinentry.package = pkgs.pinentry-gnome3;
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
        modules-center = [ "sway/window" ];
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
      menu = "bemenu-run";
      fonts = {
        names = [ "FiraCode Nerd Font" ];
      };
      bars = [ { command = "${pkgs.waybar}/bin/waybar"; } ];
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
      exec_always configure-gtk

      exec_always systemctl --user restart kanshi.service
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
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
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

  programs.direnv.enable = true;

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
        text/html; ${pkgs.elinks}/bin/elinks %s; nametemplate=%s.html
        text/html; ${pkgs.elinks}/bin/elinks -dump %s; nametemplate=%s.html; copiousoutput
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

}
