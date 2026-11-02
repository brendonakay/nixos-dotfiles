;;; bk-evil.el --- Modal editing -*- lexical-binding: t; -*-

;; Evil is the one package in this config doing something Emacs has no built-in
;; answer for.  Emacs ships `viper', but it emulates vi rather than Vim: no text
;; objects, no visual block, no operator-pending composition.  Evil is the whole
;; reason this config can exist without relearning every key.
;;
;; evil-collection supplies bindings for the modes Evil does not cover, which is
;; where the seams show: Dired, help buffers, compilation, the debugger.  If the
;; point of trying Emacs is to judge whether those seams bother you, this is the
;; file to comment out first.

;;; Code:

(setq evil-want-keybinding nil          ; required before evil loads, for evil-collection
      evil-want-integration t
      evil-want-C-u-scroll t
      evil-want-Y-yank-to-eol t
      evil-split-window-below t         ; 'splitbelow'
      evil-vsplit-window-right t        ; 'splitright'
      evil-search-module 'evil-search   ; Vim-style / and ? rather than isearch
      evil-ex-search-case 'smart        ; 'ignorecase' plus 'smartcase'
      evil-shift-width 4                ; 'shiftwidth'
      evil-undo-system 'undo-redo       ; Emacs 28's linear redo over its undo tree
      evil-respect-visual-line-mode t
      evil-symbol-word-search t)

(require 'evil)
(evil-mode 1)

(require 'evil-collection)
(evil-collection-init)

;; vim-surround
(require 'evil-surround)
(global-evil-surround-mode 1)

;; vim-commentary's gc operator.  Evil has no built-in commenting operator, but
;; Emacs has had comment-dwim since forever, so this wires the two together
;; rather than adding evil-commentary.
(evil-define-operator bk-evil-comment (beg end)
  "Comment or uncomment the lines between BEG and END."
  :move-point nil
  (comment-or-uncomment-region beg end))

(evil-define-key '(normal visual) 'global "gc" #'bk-evil-comment)

;; gcc comes for free: doubling an operator's last key is linewise in Evil, the
;; same rule that makes dd and yy work.  Binding gcc explicitly is an error,
;; since gc is already a complete binding rather than a prefix.

;; ANCHOR: visual-line paste over the buffer's last line.
;; Evil's `evil-visual-paste' treats a selection ending at `point-max' as a
;; last line with no trailing newline: it deletes it, then pastes after the
;; line above.  When the file does end in a newline, that line above is the
;; empty one past the end, so the paste lands below a blank line instead of
;; replacing.  A temporary extra newline keeps the selection off `point-max',
;; so Evil takes its ordinary replace path.
(defun bk-evil--visual-paste-last-line (orig &rest args)
  "Call ORIG with ARGS, making a linewise paste over the last line replace it."
  (if (and (evil-visual-state-p)
           (eq (evil-visual-type) 'line)
           (= evil-visual-end (point-max))
           (eq (char-before (point-max)) ?\n))
      (let ((end (marker-position evil-visual-end)))
        (evil-with-single-undo
          (save-excursion (goto-char (point-max)) (insert "\n"))
          (set-marker evil-visual-end end)
          (unwind-protect (apply orig args)
            (save-excursion (goto-char (point-max)) (delete-char -1)))))
    (apply orig args)))

(advice-add 'evil-visual-paste :around #'bk-evil--visual-paste-last-line)

(provide 'bk-evil)
;;; bk-evil.el ends here
