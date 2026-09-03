;;; bk-lsp.el --- Eglot -*- lexical-binding: t; -*-

;; From lua/plugins/lsp.lua by way of ../vim-config/config/lsp.vim.  Eglot is
;; built in as of Emacs 29, and its `eglot-server-programs' already covers every
;; server that config registered by hand except typos-lsp: pyright, ruff, gopls,
;; nil, lua-language-server, typescript-language-server, and
;; haskell-language-server-wrapper.  So this file mostly turns things off.
;;
;; One real regression from the Vim config: Eglot does not implement codeLens.
;; The HLS type-signature and import lenses that lsp.vim enabled through
;; g:lsp_document_code_lens_enabled have no equivalent here.

;;; Code:

(require 'eglot)

;; options.lua turned virtual text off and opened a float on CursorHold.  Eglot
;; and Eldoc between them do the same: diagnostics get an underline plus the echo
;; area, and Eldoc shows the doc at point.
(setq eglot-autoshutdown t
      eglot-sync-connect 1
      eglot-events-buffer-config '(:size 0 :format full)  ; no event log unless debugging
      eglot-extend-to-xref t
      eglot-report-progress nil)

;; The diagnostic float, from the CursorHold autocommand.
(setq eldoc-echo-area-use-multiline-p 3
      ;; nil, not t: the idle hint should land in the echo area, the way Vim put
      ;; hover text on the command line.  With t, Eldoc goes quiet whenever the
      ;; doc buffer happens to be visible.
      eldoc-echo-area-prefer-doc-buffer nil
      flymake-no-changes-timeout 0.1        ; 'updatetime'
      flymake-show-diagnostics-at-end-of-line nil
      flymake-fringe-indicator-position 'left-fringe)

;; Left to itself, `eldoc-doc-buffer' takes half the frame.  Keep it to a third,
;; pinned at the bottom, and never let it steal the selected window.
(add-to-list 'display-buffer-alist
             '("\\*eldoc\\(\\|.*\\)\\*"
               (display-buffer-at-bottom)
               (window-height . 0.33)
               (dedicated . t)
               (body-function . select-window)))

;; K in Vim showed hover text in a float that went away on its own.  The nearest
;; well-behaved equivalent: ask the server, show the doc window only when there
;; is something in it, and say so plainly when there is not, rather than opening
;; an empty buffer over a third of the frame.  q closes it, via evil-collection.
(defun bk-lsp-hover ()
  "Show documentation for the thing at point."
  (interactive)
  (if (not (bound-and-true-p eldoc-mode))
      (message "No documentation source here")
    ;; Ask for a refresh, then look at what Eldoc actually has.
    (eldoc t)
    (let ((buffer (and (fboundp 'eldoc-doc-buffer) (eldoc-doc-buffer))))
      (if (and (buffer-live-p buffer)
               (> (buffer-size buffer) 0))
          (display-buffer buffer)
        (message "No documentation at point")))))

;; typos-lsp is the only server the Vim config registered that Eglot does not
;; know about.  It is a catch-all for prog-mode and text-mode, but MUST be
;; appended (the trailing t): eglot--lookup-mode returns the first matching
;; entry, and since clangd, nil, pyright etc. all attach to prog-mode-derived
;; modes, a prepended catch-all shadows every real language server -- Eglot
;; runs only one server per buffer, so it would start typos-lsp instead of the
;; language server and K/gd/ca would do nothing.  Appended, the specific
;; built-in servers win and typos-lsp only covers modes with no other server.
(add-to-list 'eglot-server-programs
             '((prog-mode text-mode) . ("typos-lsp")) t)

;; The haskell block from lsp.lua: no GHC install, ormolu for formatting, and the
;; two lens plugins on.  The lenses will not render, see the note above, but they
;; still drive the code actions HLS offers.
(setq-default eglot-workspace-configuration
              '(:haskell (:formattingProvider "ormolu"
                          :installGhc :json-false
                          :plugin (:ghcide-type-lenses (:globalOn t)
                                   :importLens (:globalOn t)))
                :typos (:diagnosticSeverity "Hint")))

;; Start Eglot wherever a server is configured for the major mode.  The Vim
;; config's executable() guards are unnecessary here: Eglot reports a missing
;; binary once and moves on.
(defun bk-lsp-maybe-start ()
  "Start Eglot if a server is configured for this buffer and a project exists."
  (when (and buffer-file-name
             (not (bound-and-true-p eglot--managed-mode))
             (eglot--lookup-mode major-mode))
    (ignore-errors (eglot-ensure))))

(dolist (hook '(python-mode-hook python-ts-mode-hook
                haskell-mode-hook
                nix-mode-hook nix-ts-mode-hook
                go-mode-hook go-ts-mode-hook
                lua-mode-hook lua-ts-mode-hook
                typescript-ts-mode-hook tsx-ts-mode-hook
                js-mode-hook js-ts-mode-hook))
  (add-hook hook #'bk-lsp-maybe-start))

(provide 'bk-lsp)
;;; bk-lsp.el ends here
