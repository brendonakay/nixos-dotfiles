;;; bk-modeline.el --- Mode line -*- lexical-binding: t; -*-

;; From lua/plugins/lualine.lua by way of ../vim-config/config/statusline.vim.
;; Sections follow lualine.lua: state and branch on the left, then the file name;
;; diagnostics, LSP server, macro recording, encoding, line ending and major mode
;; on the right.
;;
;; Emacs has no equivalent of lualine's globalstatus, the same way Vim has no
;; 'laststatus' 3.  Each window keeps its own mode line.

;;; Code:

(require 'seq)

(defun bk-modeline--state ()
  "Return the Evil state, styled like lualine's mode section."
  (if (not (bound-and-true-p evil-local-mode))
      ""
    (let* ((state (symbol-name evil-state))
           (face (pcase evil-state
                   ('normal 'bk-modeline-normal-state)
                   ('insert 'bk-modeline-insert-state)
                   ((or 'visual 'operator) 'bk-modeline-visual-state)
                   ('replace 'bk-modeline-replace-state)
                   (_ 'bk-modeline-other-state))))
      (propertize (upcase state) 'face face))))

(defun bk-modeline--branch ()
  "Return the current VC branch, lualine's branch section."
  (if (and vc-mode buffer-file-name)
      (propertize (string-trim (substring-no-properties vc-mode)) 'face 'bk-modeline-branch)
    ""))

(defun bk-modeline--file ()
  "Return the file name relative to the project, lualine's path = 1."
  (let* ((root (and (fboundp 'project-current)
                    (when-let* ((p (project-current nil)))
                      (project-root p))))
         (name (cond
                ((and buffer-file-name root)
                 (file-relative-name buffer-file-name root))
                (buffer-file-name (abbreviate-file-name buffer-file-name))
                (t (buffer-name)))))
    (concat name
            (when (buffer-modified-p) " [+]")
            (when buffer-read-only " [RO]"))))

(defun bk-modeline--diagnostics ()
  "Return Flymake counts, lualine's diagnostics section."
  (if (not (bound-and-true-p flymake-mode))
      ""
    (let ((counts (make-hash-table :test #'eq)))
      (dolist (d (flymake-diagnostics))
        (let ((type (flymake-diagnostic-type d)))
          (puthash type (1+ (gethash type counts 0)) counts)))
      (string-join
       (seq-filter
        #'identity
        (mapcar (lambda (pair)
                  (let ((n (gethash (car pair) counts 0)))
                    (when (> n 0)
                      (propertize (format "%s%d" (cdr pair) n)
                                  'face (car pair)))))
                '((:error . "E") (:warning . "W") (:note . "H"))))
       " "))))

(defun bk-modeline--server ()
  "Return the Eglot server name, lualine's LSP client section."
  (if (and (fboundp 'eglot-current-server) (eglot-current-server))
      (propertize (format "%s" (eglot-project-nickname (eglot-current-server)))
                  'face 'eglot-mode-line)
    ""))

(defun bk-modeline--recording ()
  "Return the macro recording indicator, lualine's reg_recording section."
  (if defining-kbd-macro
      (propertize "Recording" 'face 'bk-modeline-recording)
    ""))

(defun bk-modeline--eol ()
  "Return the line ending style, lualine's fileformat section."
  (pcase (coding-system-eol-type buffer-file-coding-system)
    (0 "unix")
    (1 "dos")
    (2 "mac")
    (_ "")))

(defun bk-modeline--join (&rest parts)
  "Join non-empty PARTS with a single space."
  (string-join (seq-remove #'string-empty-p (delq nil parts)) " "))

(setq-default
 mode-line-format
 '(:eval
   (let* ((left (bk-modeline--join (bk-modeline--state)
                                   (bk-modeline--branch)
                                   (bk-modeline--file)))
          (right (bk-modeline--join (bk-modeline--diagnostics)
                                    (bk-modeline--server)
                                    (bk-modeline--recording)
                                    (symbol-name buffer-file-coding-system)
                                    (bk-modeline--eol)
                                    (format-mode-line mode-name)))
          ;; Leave room for the right side plus a trailing space.
          (fill (max 1 (- (window-width) (length left) (length right) 1))))
     (concat " " left (make-string fill ?\s) right " "))))

(provide 'bk-modeline)
;;; bk-modeline.el ends here
