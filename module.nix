inputs: {
  wlib,
  pkgs,
  ...
}:
let
  userName = "aaronv";
  homeDir = if pkgs.stdenv.isDarwin then "/Users/${userName}" else "/home/${userName}";
in {
  imports = [wlib.wrapperModules.neovim];

  # choose a directory for your config.
  config.settings.config_directory = "${homeDir}/.config/nvim"; # Uses the configuration outside the nix-store (Mutable)
  # config.settings.config_directory = ./.; # Uses the configuration inside the nix-store (Inmutable)
  config.runtimePkgs = with pkgs; [
    # Dependencies
    gcc
    cargo
    lazygit
    git
    # NOTE: This two are used by dadbod, but maybe they should be installed by the host machine rather than go with neovim config, as some hosts might not need the other client
    # postgresql
    # mariadb

    # tree-sitter-cli
    tree-sitter

    # Language Servers
    lua-language-server
    nixd
    typescript
    tailwindcss-language-server
    vscode-langservers-extracted
    jdt-language-server
    gopls

    alejandra # Nix Formatter
  ];
  config.specs.general = {
    data = with pkgs.vimPlugins; [
      nvim-treesitter-textobjects
      nvim-treesitter.withAllGrammars
    ];
  };
  config.info.jdtls_path = "${pkgs.jdt-language-server}";
  # you can also use an impure path!
  # config.settings.config_directory = lib.generators.mkLuaInline "vim.fn.stdpath('config')";
  # config.settings.config_directory = "/home/<USER>/.config/nvim";
  # If you do that, it will not be provisioned by nix, but it will have normal reload for quick edits!

  # If you want to install multiple neovim derivations via home.packages or environment.systemPackages
  # in order to prevent path collisions:

  # set this to true:
  # config.settings.dont_link = true;

  # and make sure these dont share values:
  # config.binName = "nvim";
  # config.settings.aliases = [ ];
}
