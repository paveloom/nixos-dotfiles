{
  inputs,
  pkgs,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      systemd-boot.enable = true;
    };
    tmp = {
      useTmpfs = true;
    };
  };

  environment = {
    gnome.excludePackages = with pkgs; [
      gnome-contacts
      gnome-maps
      gnome-music
      gnome-photos
      gnome-shell-extensions
      gnome-software
      gnome-tour
      gnome-weather
    ];
    shells = [pkgs.fish];
    systemPackages = with pkgs; [
      nautilus-python
    ];
  };

  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      corefonts
      nerd-fonts.jetbrains-mono
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    keyboard.zsa.enable = true;
    sane = {
      enable = true;
      extraBackends = with pkgs; [
        sane-airscan
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.paveloom = import ./home.nix;
  };

  i18n.defaultLocale = "en_US.UTF-8";

  imports = with inputs; [
    home-manager.nixosModules.home-manager
    nix-index-database.nixosModules.nix-index
  ];

  networking = {
    firewall.allowedTCPPorts = [43695];
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  nix = {
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    registry.nixpkgs = {
      flake = inputs.nixpkgs;
      from = {
        id = "nixpkgs";
        type = "indirect";
      };
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      max-jobs = 1;
    };
  };

  nixpkgs.config.allowUnfree = true;

  programs = {
    command-not-found.enable = false;
    direnv.enable = true;
    evolution.enable = true;
    fish.enable = true;
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
    gamemode.enable = true;
    geary.enable = false;
    git.enable = true;
    gnupg.agent.enable = true;
    mosh.enable = true;
    nano.syntaxHighlight = true;
    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
    nix-ld.enable = true;
    steam.enable = true;
    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
  };

  security.rtkit.enable = true;

  services = {
    envfs.enable = true;
    ipp-usb.enable = true;
    logind.lidSwitch = "ignore";
    nixseparatedebuginfod.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      extraConfig = let
        rate = 48000;
        quantum = 32;
        req = "${toString quantum}/${toString rate}";
      in {
        pipewire."92-low-latency" = {
          context.properties = {
            default.clock.rate = rate;
            default.clock.quantum = quantum;
            default.clock.min-quantum = quantum;
            default.clock.max-quantum = quantum;
          };
        };
        pipewire-pulse."92-low-latency" = {
          pulse.properties = {
            pulse.min.frag = req;
            pulse.min.quantum = req;
            pulse.min.req = req;
          };
          stream.properties = {
            node.latency = req;
          };
        };
      };
    };
    printing = {
      drivers = with pkgs; [
        canon-cups-ufr2
        carps-cups
        gutenprint
        gutenprintBin
      ];
      enable = true;
      logLevel = "debug";
    };
    resolved.enable = true;
    udev.extraRules = ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="*",GROUP="users", MODE="0660"
    '';
    webdav-server-rs = {
      enable = true;
      settings = {
        server.listen = ["0.0.0.0:43695" "[::]:43695"];
        accounts = {
          auth-type = "htpasswd.default";
          acct-type = "unix";
        };
        htpasswd.default = {
          htpasswd = pkgs.writeText "htpasswd" ''
            paveloom:$2y$05$lz3OON32dnM4KesHRuktz.grFpwe6fD2.v.JmafrQATdd.PvZ9VwK
          '';
        };
        location = [
          {
            route = ["/*path"];
            directory = "~/Public/WebDAV";
            handler = "filesystem";
            methods = ["webdav-rw"];
            autoindex = true;
            auth = "true";
            setuid = true;
            hide-symlinks = false;
          }
        ];
      };
    };
    xserver = {
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
      enable = true;
      excludePackages = [pkgs.xterm];
      xkb = {layout = "us,ru";};
    };
  };

  system = {
    fsPackages = [pkgs.bindfs];
    stateVersion = "24.05";
  };

  systemd = {
    extraConfig = ''
      DefaultTimeoutStopSec=15s
    '';
    packages = with pkgs; [
      amneziawg-tools
    ];
    services."awg-quick@awg0" = {
      overrideStrategy = "asDropin";
      wantedBy = ["machines.target"];
    };
  };

  time.timeZone = "Europe/Moscow";

  users = {
    users.paveloom = {
      createHome = true;
      extraGroups = [
        "docker"
        "keys"
        "libvirtd"
        "lp"
        "networkmanager"
        "scanner"
        "wheel"
        "wireshark"
      ];
      home = "/home/paveloom";
      isNormalUser = true;
      name = "paveloom";
      packages = with pkgs; [
        acpi
        amdgpu_top
        amneziawg-tools
        appimage-run
        asciinema
        aspell
        aspellDicts.en
        aspellDicts.ru
        audacious
        authenticator
        bat
        bottles
        d-spy
        dconf-editor
        dive
        docker-credential-helpers
        dua
        fd
        (ffmpeg_7.override {
          withFdkAac = true;
          withUnfree = true;
          withWebp = true;
        })
        file
        firefox
        foliate
        fontforge-gtk
        fopnu
        fzf
        gamescope
        gimp
        gnome-extension-manager
        gnome-frog
        gnome-icon-theme
        gnome-sound-recorder
        gnome-tweaks
        gnomeExtensions.appindicator
        gnomeExtensions.clipboard-history
        gnomeExtensions.dash-to-dock
        gnomeExtensions.hot-edge
        gnomeExtensions.just-perfection
        gnomeExtensions.media-controls
        gnomeExtensions.memento-mori
        gnomeExtensions.vitals
        gnucash
        google-chrome
        goverlay
        gparted
        gucharmap
        hunspell
        hunspellDicts.en_US
        hunspellDicts.ru_RU
        inkscape
        jetbrains.goland
        jetbrains.phpstorm
        jetbrains.pycharm-professional
        jetbrains.webstorm
        julia
        keepassxc
        lazydocker
        lazygit
        libnotify
        libreoffice
        libva-utils
        mangohud
        monero-gui
        mpv
        nekoray
        neovim
        newsflash
        nix-tree
        obs-studio
        patchelf
        picard
        protonup-qt
        quodlibet-full
        (retroarch.withCores (cores:
          with cores; [
            bsnes
            dolphin
            gpsp
            melonds
            mesen
            mgba
            mupen64plus
            sameboy
          ]))
        ripgrep
        shortwave
        streamrip
        subtitleedit
        tdesktop
        tor-browser
        trash-cli
        tree
        unrar
        unzip
        virt-manager
        virtiofsd
        (vivaldi.override {
          enableWidevine = true;
          proprietaryCodecs = true;
        })
        vscode
        wally-cli
        wezterm
        wget
        wl-clipboard
        xclip
        zed-editor
        zip
      ];
      shell = pkgs.fish;
    };
  };

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  zramSwap = {
    algorithm = "zstd";
    enable = true;
    memoryPercent = 50;
  };
}
