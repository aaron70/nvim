{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    wrappers.url = "github:BirdeeHub/nix-wrapper-modules";
    wrappers.inputs.nixpkgs.follows = "nixpkgs";
    import-tree.url = "github:vic/import-tree";
  };

  outputs =
    {
      self,
      nixpkgs,
      wrappers,
      ...
    }@inputs:
    let
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      module = nixpkgs.lib.modules.importApply ./module.nix inputs;
      moduleWrapped = module // { config.settings.config_directory = nixpkgs.lib.mkForce ./.; };
      wrapperWrapped = wrappers.lib.evalModule moduleWrapped;
      wrapper = wrappers.lib.evalModule module;
    in
    {
      wrapperModules = {
        neovim = module;
        default = moduleWrapped;
      };
      wrappers = {
        neovim = wrapper.config;
        default = wrapperWrapped.config;
      };
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          neovim = self.wrappers.neovim.wrap { inherit pkgs; };
          default = self.wrappers.default.wrap { inherit pkgs; };
          formatter = pkgs.alejandra;
        }
      );
      # home manager and nixos modules
      # `wrappers.neovim.enable = true`
      # You can set any of the options.
      # But that is how you enable it.
      nixosModules = {
        default = wrappers.lib.getInstallModule {
          name = "neovim";
          value = moduleWrapped;
        };
        neovim = wrappers.lib.getInstallModule {
          name = "neovim";
          value = module;
        };
      };
      homeModules = {
        # they produce generically importable modules
        default = self.nixosModules.default;
        neovim = self.nixosModules.neovim;
      };
    };
}
