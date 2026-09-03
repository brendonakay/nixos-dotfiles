;;; bk-clipboard.el --- System clipboard from a terminal frame -*- lexical-binding: t; -*-

;; A GUI Emacs talks to the system clipboard for free.  A terminal frame does
;; not: `display-selections-p' is nil and `interprogram-cut-function' is
;; `gui-select-text', which does nothing without a window system.  Left alone,
;; every Evil yank and `bk-keys-yank-file-path' would stay inside Emacs.
;;
;; Vim solved the same problem by being compiled with +clipboard.  Here it is a
;; pair of functions that shell out.  The command is chosen per platform so the
;; config still works on the Linux machine.

;;; Code:

(defconst bk-clipboard-commands
  '(("pbcopy"  . "pbpaste")              ; macOS
    ("wl-copy" . "wl-paste")             ; Wayland
    ("xclip"   . "xclip"))               ; X11, needs the flags below
  "Copy and paste commands, in the order they are tried.")

(defun bk-clipboard--pair ()
  "Return (COPY-ARGS . PASTE-ARGS) for the first available clipboard tool."
  (catch 'found
    (dolist (pair bk-clipboard-commands)
      (when (executable-find (car pair))
        (throw 'found
               (pcase (car pair)
                 ("xclip" '(("xclip" "-selection" "clipboard")
                            . ("xclip" "-selection" "clipboard" "-o")))
                 ("wl-copy" '(("wl-copy") . ("wl-paste" "--no-newline")))
                 (_ '(("pbcopy") . ("pbpaste")))))))
    nil))

(defvar bk-clipboard--last nil
  "The last text this Emacs put on the clipboard.")

(defun bk-clipboard-cut (text)
  "Send TEXT to the system clipboard."
  (when-let* ((cmd (car (bk-clipboard--pair))))
    (setq bk-clipboard--last text)
    ;; Synchronous on purpose.  With start-process the write is asynchronous, so
    ;; killing Emacs right after a yank loses it, and clipboard payloads are
    ;; small enough that blocking is not worth worrying about.
    (let ((coding-system-for-write 'utf-8))
      (with-temp-buffer
        (insert text)
        (apply #'call-process-region (point-min) (point-max)
               (car cmd) nil nil nil (cdr cmd))))))

(defun bk-clipboard-paste ()
  "Return the system clipboard contents.
Returns nil when the clipboard still holds what this Emacs put there,
which stops the kill ring filling up with duplicates of its own entries."
  (when-let* ((cmd (cdr (bk-clipboard--pair))))
    (let* ((coding-system-for-read 'utf-8)
           (text (with-output-to-string
                   (apply #'call-process (car cmd) nil standard-output nil (cdr cmd)))))
      (unless (or (string-empty-p text)
                  (string= text bk-clipboard--last))
        text))))

;; Only in a terminal frame.  A GUI Emacs, on this machine or another, keeps its
;; native clipboard support.
(unless (display-graphic-p)
  (when (bk-clipboard--pair)
    (setq interprogram-cut-function #'bk-clipboard-cut
          interprogram-paste-function #'bk-clipboard-paste
          select-enable-clipboard t)))

(provide 'bk-clipboard)
;;; bk-clipboard.el ends here
