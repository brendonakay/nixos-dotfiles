;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; Ported from the Vim config in ../vim-config, which was itself ported from the
;; Neovim config in ../nvim-config-lua.  README.md in this directory covers what
;; moved to an Emacs built-in, what needed a package, and what has no equivalent.
;;
;; ../emacs/default.nix installs Emacs with every package already on the load
;; path, and links this directory's files into ~/.config/emacs.  Nothing here
;; installs packages at runtime.

;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))

;; Emacs writes a lot of state.  Keep it out of the config directory, which is
;; version controlled, and out of the way generally.
(defconst bk-cache-directory
  (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache/"))
  "Where this config puts files Emacs generates.")
(make-directory bk-cache-directory t)

(require 'bk-options)
(require 'bk-clipboard)
(require 'bk-theme)
(require 'bk-modeline)
(require 'bk-evil)
(require 'bk-completion)
(require 'bk-lsp)
(require 'bk-container)
(require 'bk-format)
(require 'bk-dired)
(require 'bk-git)
(require 'bk-man)
(require 'bk-todo)
(require 'bk-haskell)
(require 'bk-debug)

;; Keys last, so every command they refer to is defined.
(require 'bk-keys)

;;; init.el ends here
