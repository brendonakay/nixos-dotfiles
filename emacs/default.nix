{ pkgs, config, lib, ... }:

let
  # Linked out of the store so edits take effect on restart without a rebuild,
  # the same way vim/default.nix links vim-config.
  # TODO: Make this generic per system.
  configDir = "/Users/bkay/Workspace/nixos-dotfiles/emacs-config";

  # haskell-language-server. Off by default because it is 797 MiB to download and
  # 7.6 GiB unpacked, across 680 store paths. Eglot already knows how to start it
  # (eglot-server-programs has haskell-mode) and bk-lsp.el already sends the
  # ormolu and lens settings, so this flag is the only thing standing between
  # here and working Haskell LSP.
  enableHaskellLsp = false;

  # emacs-nox is the build with no GUI at all. The default pkgs.emacs on darwin
  # is a Cocoa build, so running `emacs` in a terminal makes it negotiate with
  # the macOS window server and open a window elsewhere, which is what made
  # startup look like a hang. With nox there is no GUI code path to take.
  #
  # Every package this config loads. Nix puts them on the load path, so
  # package.el never runs and nothing is fetched at startup; early-init.el sets
  # package-enable-at-startup to nil to match.
  #
  # The list is deliberately short. Everything else the Vim config needed a
  # plugin for is built into Emacs 30: Eglot for LSP, Dired for the file
  # browser, project.el and fido-vertical-mode for the fuzzy finder, VC for git,
  # flymake for diagnostics, which-key, editorconfig, repeat-mode, treesit, and
  # the mode line.
  emacs = pkgs.emacs-nox.pkgs.withPackages (epkgs: [
    # Modal editing. Emacs ships viper, which emulates vi rather than Vim: no
    # text objects, no visual block, no operator composition. This is the whole
    # reason the config transfers.
    epkgs.evil
    # Bindings for the modes Evil does not cover: Dired, help, compilation.
    # Comment this out to feel where Evil's seams actually are.
    epkgs.evil-collection
    # vim-surround
    epkgs.evil-surround

    # Emacs ships no Haskell mode, and Eglot needs a major mode to attach to.
    # Brings haskell-interactive-mode, the GHCi integration with jumpable
    # errors that has no Vim equivalent.
    epkgs.haskell-mode

    # nvim-dap's replacement. Needs nothing outside Emacs, unlike vimspector,
    # which wanted a +python3 Vim and a 1.4 GiB closure.
    epkgs.dape

    # Emacs ships no Nix mode either, and this repo is mostly Nix.
    epkgs.nix-mode

    # The reason a lot of people use Emacs at all. Native buffers rather than a
    # TUI in a terminal emulator, so there is nothing for term.el to mangle, and
    # evil-collection already ships its vim bindings. Pulls dash, with-editor
    # and magit-section; transient it needs is built in.
    epkgs.magit

    # The completion UI. Corfu's popup is a child frame, which a terminal frame
    # cannot host, so corfu-terminal draws it with overlays instead and pulls in
    # popon to do it. Both are needed here because this Emacs is emacs-nox and
    # every frame is a terminal frame.
    epkgs.corfu
    epkgs.corfu-terminal

    # Tree-sitter grammars. Emacs 30 ships the ts modes but no grammars, and
    # typescript-ts-mode only registers .ts in auto-mode-alist when
    # (treesit-ready-p 'typescript) -- so without these, .ts and .tsx open in
    # fundamental-mode. Picked rather than with-all-grammars, which is 238 MiB
    # against 2 MiB for these four. tsx is its own grammar, not part of
    # typescript.
    (epkgs.treesit-grammars.with-grammars (g: with g; [
      tree-sitter-typescript
      tree-sitter-tsx
      tree-sitter-javascript
      tree-sitter-json
    ]))

    # Emacs 30 ships no markdown mode at all, so .md files land in
    # fundamental-mode: no highlighting, and none of the prose settings in
    # bk-options.el fire because they hang off text-mode-hook. Emacs 31 has a
    # built-in markdown-ts-mode, which would make this package unnecessary.
    epkgs.markdown-mode
  ]);
  # Startup is about a second, which is a second too long to pay in every tmux
  # pane. This connects to a daemon instead, and -a '' starts one on first use,
  # so there is no launchd agent to manage and nothing running until it is
  # wanted. After that it opens instantly.
  e = pkgs.writeShellScriptBin "e" ''
    exec ${emacs}/bin/emacsclient --tty --alternate-editor="" "$@"
  '';
in
{
  home.packages = [
    emacs
    e

    # GNU ls, for dired-listing-switches --group-directories-first. The ls in
    # macOS does not understand it.
    pkgs.coreutils

    # Search, behind project-find-file and project-find-regexp.
    pkgs.ripgrep
    pkgs.fd

    # Opened in a terminal buffer by <leader>lg.
    pkgs.lazygit

    # Language servers. Eglot's own eglot-server-programs already knows how to
    # start every one of these, so bk-lsp.el only has to add typos-lsp.
    pkgs.pyright
    pkgs.ruff
    pkgs.nil
    pkgs.typos-lsp
    pkgs.lua-language-server

    # JavaScript and TypeScript. Eglot already knows how to start this for
    # js-mode, js-ts-mode, typescript-ts-mode and tsx-ts-mode, so bk-lsp.el
    # needs no entry for it. typescript is here because the server drives
    # tsserver from it.
    pkgs.typescript-language-server
    pkgs.typescript

    # Formatters, from the list in conform.lua. bk-format.el shells out to them.
    pkgs.prettier
    pkgs.stylua
    pkgs.nixfmt
    pkgs.shfmt
    pkgs.yamlfmt

    # Spell checking for prose. Vim had its own spell checker built in; flyspell
    # shells out to aspell.
    (pkgs.aspellWithDicts (d: [ d.en ]))

    # The Python debug adapter dape drives, from debugging.lua. This has to be
    # the same Python version as nvim.nix uses: both put bin/debugpy in the
    # profile, and two different versions collide in home-manager's buildEnv.
    pkgs.python312Packages.debugpy
  ]
  ++ lib.optional enableHaskellLsp pkgs.haskell-language-server;

  # Emacs writes plenty into ~/.config/emacs at runtime, so the directory itself
  # stays a real one that home-manager owns, and only these entries are links
  # into the repo. init.el redirects the noisy state to ~/.cache/emacs anyway.
  #
  # lisp/ and themes/ are linked as directories because Emacs never writes into
  # them. That is the opposite of ~/.vim/after, where everforest generates a
  # syntax cache.
  home.file = {
    ".config/emacs/early-init.el".source =
      config.lib.file.mkOutOfStoreSymlink "${configDir}/early-init.el";
    ".config/emacs/init.el".source =
      config.lib.file.mkOutOfStoreSymlink "${configDir}/init.el";
    ".config/emacs/lisp".source =
      config.lib.file.mkOutOfStoreSymlink "${configDir}/lisp";
    ".config/emacs/themes".source =
      config.lib.file.mkOutOfStoreSymlink "${configDir}/themes";
  };
}
