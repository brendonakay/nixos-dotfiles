;;; bk-format.el --- Format on save -*- lexical-binding: t; -*-

;; From lua/plugins/conform.lua by way of ../vim-config/config/format.vim, which
;; used ALE for the same job.  There is no built-in equivalent and apheleia would
;; be another package, so this is hand rolled: roughly forty lines that shell the
;; buffer through an external formatter, with the same fallback to the language
;; server that conform's lspFallback provided.

;;; Code:

(defconst bk-format-commands
  '((html-mode        . ("prettier" "--stdin-filepath"))
    (mhtml-mode       . ("prettier" "--stdin-filepath"))
    (css-mode         . ("prettier" "--stdin-filepath"))
    (css-ts-mode      . ("prettier" "--stdin-filepath"))
    (js-mode          . ("prettier" "--stdin-filepath"))
    (js-ts-mode       . ("prettier" "--stdin-filepath"))
    (typescript-ts-mode . ("prettier" "--stdin-filepath"))
    (tsx-ts-mode      . ("prettier" "--stdin-filepath"))
    (markdown-mode    . ("prettier" "--stdin-filepath"))
    (markdown-ts-mode . ("prettier" "--stdin-filepath"))
    (yaml-mode        . ("yamlfmt" "-in"))
    (yaml-ts-mode     . ("yamlfmt" "-in"))
    (python-mode      . ("ruff" "format" "-"))
    (python-ts-mode   . ("ruff" "format" "-"))
    (lua-mode         . ("stylua" "-"))
    (lua-ts-mode      . ("stylua" "-"))
    (nix-mode         . ("nixfmt"))
    (nix-ts-mode      . ("nixfmt"))
    (sh-mode          . ("shfmt" "-i" "2"))
    (bash-ts-mode     . ("shfmt" "-i" "2"))
    (haskell-mode     . ("ormolu" "--stdin-input-file")))
  "Major mode to formatter command.
A command ending in a flag that takes the file name gets it appended.
`conform.lua' listed yamllint for yaml, which only lints, so yaml is
formatted by yamlfmt alone.  Its terragrunt and liquidsoap entries are
dropped: neither formatter is installed.")

(defun bk-format--command ()
  "Return the formatter command for this buffer, or nil."
  (when-let* ((entry (alist-get major-mode bk-format-commands))
              (program (car entry)))
    (when (executable-find program)
      ;; --stdin-filepath and --stdin-input-file both want the file name next.
      (if (string-match-p "stdin" (or (car (last entry)) ""))
          (append entry (list (or buffer-file-name "-")))
        entry))))

(defun bk-format-buffer ()
  "Format the buffer with an external formatter, or the language server.
A formatter that fails leaves the buffer untouched rather than replacing
it with an error message."
  (interactive)
  (if-let* ((command (bk-format--command)))
      (let ((output (generate-new-buffer " *bk-format*"))
            (errors (make-temp-file "bk-format-err")))
        (unwind-protect
            (if (zerop (apply #'call-process-region
                              (point-min) (point-max) (car command)
                              nil (list output errors) nil (cdr command)))
                ;; replace-buffer-contents makes the smallest edit that gets
                ;; there, so point, markers and the scroll position all survive.
                (replace-buffer-contents output)
              (message "%s failed: %s" (car command)
                       (string-trim (with-temp-buffer
                                      (insert-file-contents errors)
                                      (buffer-string)))))
          (kill-buffer output)
          (delete-file errors)))
    ;; conform's lspFallback: no external formatter, so ask the server, but only
    ;; if it actually advertises formatting.
    (when (and (fboundp 'eglot-managed-p) (eglot-managed-p)
               (eglot-server-capable :documentFormattingProvider))
      (eglot-format-buffer))))

(add-hook 'before-save-hook #'bk-format-buffer)

(provide 'bk-format)
;;; bk-format.el ends here
