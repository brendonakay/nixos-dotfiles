{ pkgs, config, lib, ... }:

let
  # The config is linked out of the store so edits take effect without a rebuild,
  # the same way nvim.nix links nvim-config-lua. Vim's own directory layout is
  # used: ~/.vim/vimrc is found automatically, ~/.vim is first on 'runtimepath'
  # and ~/.vim/after is last, so the vimrc needs no path setup of its own.
  # TODO: Make this generic per system.
  configDir = "/Users/bkay/Workspace/nixos-dotfiles/vim-config";

  # GitHub Copilot. nixpkgs marks copilot.vim unfree and non-redistributable, so
  # /etc/nix-darwin/flake.nix has to allow that one package by name. Turning this
  # off is the only change needed to drop the unfree allowance.
  enableCopilot = true;

  # nvim-dap's replacement, vimspector, needs a Vim built with +python3. That
  # swaps pkgs.vim for an override whose closure is 1.4 GiB rather than 90 MiB,
  # so it is off by default. vimspector also wants a .vimspector.json per
  # project, where dap-python configured itself from the Python toolchain.
  enableDebugger = false;

  # Plain pkgs.vim has no +python3. The override adds it without dragging in the
  # X11 and GTK stack; darwinSupport keeps +clipboard, which guiSupport = false
  # would otherwise turn off.
  vimPackage =
    if enableDebugger then
      pkgs.vim-full.override {
        guiSupport = false;
        luaSupport = false;
        rubySupport = false;
        perlSupport = false;
        tclSupport = false;
        cscopeSupport = false;
        pythonSupport = true;
        darwinSupport = true;
      }
    else
      pkgs.vim;

  # Vim 8 native packages, loaded by the `packloadall` at the end of the vimrc.
  # The attribute name becomes the directory name.
  plugins =
    with pkgs.vimPlugins;
    {
      # Colorschemes. The rest of colorschemes.lua is Lua-only.
      inherit everforest papercolor-theme;

      # UI
      inherit lightline-vim vim-devicons undotree vim-which-key;

      # Editing
      inherit vim-commentary vim-surround vim-repeat vim-sleuth;

      # Search. File browsing is netrw, which Vim ships.
      inherit fzf-wrapper fzf-vim;

      # Git
      inherit vim-fugitive vim-rhubarb git-messenger-vim vim-gitgutter;

      # LSP, completion and formatting. asyncomplete-buffer is left out: it ships
      # no license, so nixpkgs marks it unfree.
      inherit vim-lsp ale;
      inherit asyncomplete-vim asyncomplete-lsp-vim asyncomplete-file-vim;
      inherit vim-vsnip vim-vsnip-integ;

      # Markdown
      inherit vim-markdown markdown-preview-nvim;
    }
    // lib.optionalAttrs enableCopilot {
      # Needs Vim 9.0.0185 or newer.
      inherit copilot-vim;
    }
    // lib.optionalAttrs enableDebugger {
      inherit vimspector;
    };
in
{
  home.packages = [
    # Vim itself, which makes this the `vim` on PATH: the per-user profile comes
    # before /run/current-system/sw/bin, so this wins over the pkgs.vim in
    # environment.systemPackages. Both are the same derivation anyway unless
    # enableDebugger is on, in which case this is the +python3 build.
    vimPackage

    # Search, behind fzf.vim and :Rg.
    pkgs.fzf
    pkgs.ripgrep
    pkgs.fd

    # Opened in a popup terminal by <leader>lg.
    pkgs.lazygit

    # Language servers registered in vim-config/config/lsp.vim. The servers for
    # Go, Haskell, templ and HTML are registered there too but not installed
    # here; lsp.vim skips any server whose binary is missing.
    pkgs.pyright
    pkgs.ruff
    pkgs.nil
    pkgs.typos-lsp
    pkgs.lua-language-server

    # ALE fixers, from the formatter list in conform.lua.
    pkgs.prettier
    pkgs.stylua
    pkgs.nixfmt
    pkgs.shfmt
    pkgs.yamlfmt
  ]
  ++ lib.optional enableCopilot pkgs.nodejs;

  home.file =
    {
      # Linked piece by piece rather than linking ~/.vim wholesale, because
      # home-manager owns ~/.vim/pack below and cannot manage entries inside a
      # directory that is itself an out-of-store symlink.
      ".vim/vimrc".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/vimrc";
      ".vim/config".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/config";

      # after/ is linked file by file, not as a directory. everforest with
      # g:everforest_better_performance generates a syntax cache and writes it to
      # a hardcoded ~/.vim/after/syntax, with no option to redirect it; linking
      # the directory would put those generated files inside the repo. Adding a
      # file under after/ means adding a line here.
      ".vim/after/ftplugin/markdown.vim".source =
        config.lib.file.mkOutOfStoreSymlink "${configDir}/after/ftplugin/markdown.vim";
    }
    // lib.mapAttrs' (
      name: plugin: lib.nameValuePair ".vim/pack/nix/start/${name}" { source = plugin; }
    ) plugins;
}
