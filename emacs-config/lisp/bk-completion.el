;;; bk-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;; From lua/plugins/completion.lua and telescope.lua.  nvim-cmp becomes
;; completion-at-point, and telescope becomes the minibuffer with
;; fido-vertical-mode.  Both are built in, so nothing here is a package.

;;; Code:

;; The telescope replacement.  fido-vertical-mode is icomplete with flex
;; matching and a vertical list, which is close enough to a fuzzy picker that
;; vertico and consult are not needed to start with.
(fido-vertical-mode 1)
(setq icomplete-compute-delay 0
      icomplete-show-matches-on-no-input t)

;; Flex everywhere else too, and let orderless-style space-separated pieces work
;; via the built-in partial-completion style.
(setq completion-styles '(flex partial-completion basic)
      completion-category-overrides '((file (styles partial-completion basic))
                                      (eglot (styles flex basic)))
      completion-ignore-case t
      completions-detailed t)

;; In-buffer completion.  nvim-cmp's popup becomes the completion-at-point
;; interface; completion-preview-mode is Emacs 30's inline ghost text.
(setq tab-always-indent 'complete
      completion-cycle-threshold nil
      completions-format 'one-column
      completions-max-height 15)
(when (fboundp 'completion-preview-mode)
  (add-hook 'prog-mode-hook #'completion-preview-mode))

;; cmp's source list was path, LSP, snippets, buffer.  Eglot installs itself as a
;; capf, `dabbrev' covers buffer words, and file names complete on their own.
(setq dabbrev-case-fold-search nil
      dabbrev-check-all-buffers t)

;; LuaSnip's replacement is `abbrev' plus tempo, both built in.  Neither is set
;; up here: LSP servers supply snippets through Eglot, and nothing in the Neovim
;; config defined snippets of its own.

;; telescope.lua's file_ignore_patterns
(setq completion-ignored-extensions
      (append completion-ignored-extensions
              '(".mypy_cache/" "__pycache__/" ".ipynb" ".direnv/")))

;; project.el is the thing telescope's find_files leaned on.  Mark a directory as
;; a project root if it has any of these, not just a VCS directory.
(setq project-vc-extra-root-markers '(".project" "flake.nix" "cabal.project" "*.cabal" "pyproject.toml"))

(provide 'bk-completion)
;;; bk-completion.el ends here
