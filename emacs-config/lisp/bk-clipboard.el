;;; bk-clipboard.el --- System clipboard from a terminal frame -*- lexical-binding: t; -*-

;; Vim's default: y, d and p use the unnamed register, which never leaves the
;; editor, and only the + and * registers reach the system clipboard.  Emacs
;; defaults the other way, pushing every kill to the clipboard through
;; `interprogram-cut-function'.  This file turns that off and routes Evil's +
;; and * registers to the clipboard instead, so "+y and "+p work as in Vim.
;;
;; A GUI Emacs reaches the clipboard for free through `gui-set-selection'.  A
;; terminal frame does not: `display-selections-p' is nil and the selection
;; functions do nothing without a window system.  Vim solved the same problem
;; by being compiled with +clipboard.  Here it is a pair of functions that
;; shell out.  The command is chosen per platform so the config still works on
;; the Linux machine.

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

(defun bk-clipboard-cut (text)
  "Send TEXT to the system clipboard."
  (when-let* ((cmd (car (bk-clipboard--pair))))
    ;; Synchronous on purpose.  With start-process the write is asynchronous, so
    ;; killing Emacs right after a yank loses it, and clipboard payloads are
    ;; small enough that blocking is not worth worrying about.
    (let ((coding-system-for-write 'utf-8))
      (with-temp-buffer
        (insert text)
        (apply #'call-process-region (point-min) (point-max)
               (car cmd) nil nil nil (cdr cmd))))))

(defun bk-clipboard-paste ()
  "Return the system clipboard contents."
  (when-let* ((cmd (cdr (bk-clipboard--pair))))
    (let ((coding-system-for-read 'utf-8))
      (with-output-to-string
        (apply #'call-process (car cmd) nil standard-output nil (cdr cmd))))))

;; ANCHOR: kills stay inside Emacs, like Vim's unnamed register.
(setq interprogram-cut-function nil
      interprogram-paste-function nil)

(defun bk-clipboard--evil-set-register (orig register text)
  "Send the + and * registers to the system clipboard in a terminal frame.
ORIG is `evil-set-register', called with REGISTER and TEXT otherwise."
  (if (and (memq register '(?+ ?*)) (not (display-graphic-p)))
      (bk-clipboard-cut text)
    (funcall orig register text)))

(defun bk-clipboard--evil-get-register (orig register &rest args)
  "Read the + and * registers from the system clipboard in a terminal frame.
ORIG is `evil-get-register', called with REGISTER and ARGS otherwise."
  (if (and (memq register '(?+ ?*)) (not (display-graphic-p)))
      (let ((text (bk-clipboard-paste)))
        ;; Vim pastes clipboard text that ends in a newline linewise.
        (when (string-suffix-p "\n" text)
          (put-text-property 0 (length text) 'yank-handler
                             (list #'evil-yank-line-handler nil t) text))
        text)
    (apply orig register args)))

;; Only when a clipboard tool exists.  A GUI frame falls through to Evil's own
;; handling, which uses the native selection.
(when (bk-clipboard--pair)
  (advice-add 'evil-set-register :around #'bk-clipboard--evil-set-register)
  (advice-add 'evil-get-register :around #'bk-clipboard--evil-get-register))

(provide 'bk-clipboard)
;;; bk-clipboard.el ends here
