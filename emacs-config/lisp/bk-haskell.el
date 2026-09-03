;;; bk-haskell.el --- Haskell -*- lexical-binding: t; -*-

;; haskell-mode is the second of the two packages here that Emacs has no
;; built-in answer for.  Emacs ships no Haskell mode at all, and Eglot needs a
;; major mode to attach to, so this is load bearing.
;;
;; The part worth the switch is `haskell-interactive-mode': a GHCi session per
;; Cabal project, with errors in the REPL output becoming jumpable locations in
;; the source buffer.  That is the SLIME lineage, and the Vim side has nothing
;; comparable.  Eglot handles types and diagnostics, exactly as vim-lsp did.

;;; Code:

(require 'haskell-mode nil t)
;; interactive-haskell-mode is defined in haskell-interactive-mode.el, which
;; requiring haskell-mode does not pull in.  Without this, opening any .hs file
;; fails with "File mode specification error: (void-function
;; interactive-haskell-mode)".
(require 'haskell-interactive-mode nil t)

(with-eval-after-load 'haskell-mode
  ;; Pick the REPL from the project: cabal, stack, or plain ghci.
  (setq haskell-process-type 'auto
        haskell-process-log t
        haskell-process-suggest-remove-import-lines t
        haskell-process-auto-import-loaded-modules t
        haskell-interactive-popup-errors nil    ; errors go to the REPL, not a popup
        haskell-interactive-mode-eval-mode 'haskell-mode)

  ;; ormolu on save comes from bk-format.el, matching conform.lua.  Turn off
  ;; haskell-mode's own on-save formatting so the two do not fight.
  (setq haskell-stylish-on-save nil
        haskell-mode-stylish-haskell-path nil)

  (when (fboundp 'interactive-haskell-mode)
    (add-hook 'haskell-mode-hook #'interactive-haskell-mode))
  (add-hook 'haskell-mode-hook #'haskell-indentation-mode))

(provide 'bk-haskell)
;;; bk-haskell.el ends here
