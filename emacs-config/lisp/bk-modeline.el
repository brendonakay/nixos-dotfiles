;;; bk-modeline.el --- Mode line -*- lexical-binding: t; -*-

;; Built to match the lualine setup from lua/plugins/lualine.lua: a coloured
;; state block, the branch, then the file; and on the right the diagnostics, LSP
;; server, macro recording, encoding, line ending, major mode, scroll position
;; and line:column.
;;
;; The file name is the full path, not the project-relative one, because that is
;; what is wanted at a glance.  It is elided from the left when the window is too
;; narrow, so the end of the path survives rather than the beginning.
;;
;; Emacs has no equivalent of lualine's globalstatus, the same way Vim has no
;; 'laststatus' 3, so each window keeps its own mode line.

;;; Code:

(require 'seq)
(require 'vc-git)

;;; Faces
;;
;; Declared here so the module owns them; themes/everforest-*-theme.el overrides
;; the colours.  They need real definitions rather than theme-only specs because
;; `bk-modeline--sep' reads their backgrounds to colour the powerline joins, and
;; `face-attribute' rejects a face that was never defined.

(defface bk-modeline-normal-state '((t :inherit mode-line :weight bold))
  "Face for the Evil normal state indicator.")
(defface bk-modeline-insert-state '((t :inherit mode-line :weight bold))
  "Face for the Evil insert state indicator.")
(defface bk-modeline-visual-state '((t :inherit mode-line :weight bold))
  "Face for the Evil visual state indicator.")
(defface bk-modeline-replace-state '((t :inherit mode-line :weight bold))
  "Face for the Evil replace state indicator.")
(defface bk-modeline-other-state '((t :inherit mode-line :weight bold))
  "Face for any other Evil state, and for plain Emacs state.")
(defface bk-modeline-recording '((t :inherit mode-line :weight bold))
  "Face for the macro recording indicator.")
(defface bk-modeline-branch '((t :inherit mode-line))
  "Face for the version control branch segment.")
(defface bk-modeline-segment '((t :inherit mode-line))
  "Face for the right-hand information segment.")

(defvar bk-modeline-glyphs
  '((separator-right . "")     ; U+E0B0, powerline
    (separator-left  . "")     ; U+E0B2
    (branch          . "")     ; U+E0A0
    (file            . ""))    ; U+F15B
  "Nerd Font glyphs used in the mode line.
Set any of these to a plain string to drop the font dependency, for
instance (branch . \"git:\").  Per-language filetype icons would need the
nerd-icons package, so the major mode is shown as text instead.")

(defun bk-modeline--glyph (key)
  "Return the glyph for KEY."
  (or (alist-get key bk-modeline-glyphs) ""))

;;; Segments

(defun bk-modeline--state-face ()
  "Return the face for the current Evil state."
  (pcase (and (bound-and-true-p evil-local-mode) evil-state)
    ('normal 'bk-modeline-normal-state)
    ('insert 'bk-modeline-insert-state)
    ((or 'visual 'operator) 'bk-modeline-visual-state)
    ('replace 'bk-modeline-replace-state)
    (_ 'bk-modeline-other-state)))

(defun bk-modeline--state ()
  "Return the Evil state, lualine's mode section."
  (let ((state (if (bound-and-true-p evil-local-mode)
                   (upcase (symbol-name evil-state))
                 "EMACS")))
    (propertize (concat " " state " ") 'face (bk-modeline--state-face))))

(defvar bk-modeline--branch-cache (make-hash-table :test #'equal)
  "Directory to (TIME . BRANCH), so redisplay does not hit the disk every frame.")

(defconst bk-modeline--branch-ttl 3
  "Seconds a cached branch stays good.  Bounds how stale it can look.")

(defun bk-modeline--read-head (root)
  "Return the branch named in ROOT's .git/HEAD, or a short hash if detached."
  (let ((dotgit (expand-file-name ".git" root)))
    ;; In a worktree or submodule, .git is a file pointing at the real gitdir.
    (when (file-regular-p dotgit)
      (setq dotgit
            (with-temp-buffer
              (insert-file-contents dotgit)
              (when (re-search-forward "gitdir: \\(.*\\)" nil t)
                (expand-file-name (string-trim (match-string 1)) root)))))
    (when-let* ((head (and dotgit (expand-file-name "HEAD" dotgit))))
      (when (file-readable-p head)
        (with-temp-buffer
          (insert-file-contents head)
          (goto-char (point-min))
          (if (looking-at "ref: refs/heads/\\(.+\\)$")
              (match-string 1)
            (buffer-substring (point-min) (min (point-max) (+ (point-min) 8)))))))))

(defun bk-modeline--branch-name ()
  "Return the current branch, or nil.
`vc-mode' is only set for file buffers, so Dired and other directory
buffers read .git/HEAD instead.  That is a small file read rather than a
git subprocess, and it is cached, because this runs during redisplay."
  (if vc-mode
      ;; vc-mode is " Git:branch" or " Git-branch"; only the branch is wanted.
      (string-trim (replace-regexp-in-string
                    "\\` *Git[:-]" "" (substring-no-properties vc-mode)))
    (when-let* ((root (ignore-errors (vc-git-root (or default-directory "")))))
      (let* ((key (expand-file-name root))
             (hit (gethash key bk-modeline--branch-cache))
             (now (float-time)))
        (if (and hit (< (- now (car hit)) bk-modeline--branch-ttl))
            (cdr hit)
          (cdr (puthash key (cons now (bk-modeline--read-head key))
                        bk-modeline--branch-cache)))))))

(defun bk-modeline--branch ()
  "Return the VC branch segment, lualine's branch section."
  (when-let* ((branch (bk-modeline--branch-name)))
    (unless (string-empty-p branch)
      (propertize (format " %s %s " (bk-modeline--glyph 'branch) branch)
                  'face 'bk-modeline-branch))))

(defun bk-modeline--path (available)
  "Return the full path of this buffer, elided to fit AVAILABLE columns."
  (let* ((path (cond
                (buffer-file-name buffer-file-name)
                ((derived-mode-p 'dired-mode) (expand-file-name default-directory))
                (t (buffer-name))))
         (suffix (concat (when (buffer-modified-p) " [+]")
                         (when buffer-read-only " [RO]")))
         (room (max 12 (- available (string-width suffix)))))
    (concat
     (if (<= (string-width path) room)
         path
       ;; Keep the tail: the file name matters more than the leading directories.
       (concat "…" (substring path (- (length path) (1- room)))))
     suffix)))

(defun bk-modeline--diagnostics ()
  "Return Flymake counts, lualine's diagnostics section."
  (when (bound-and-true-p flymake-mode)
    (let ((counts (make-hash-table :test #'eq)))
      (dolist (d (flymake-diagnostics))
        (let ((type (flymake-diagnostic-type d)))
          (puthash type (1+ (gethash type counts 0)) counts)))
      (let ((parts (seq-filter
                    #'identity
                    (mapcar (lambda (pair)
                              (let ((n (gethash (car pair) counts 0)))
                                (when (> n 0)
                                  (propertize (format "%s%d" (cdr pair) n) 'face (car pair)))))
                            '((:error . "E") (:warning . "W") (:note . "H"))))))
        (when parts (string-join parts " "))))))

(defun bk-modeline--server ()
  "Return the Eglot server nickname, lualine's LSP client section."
  (when (and (fboundp 'eglot-current-server) (eglot-current-server))
    (propertize (format "%s" (eglot-project-nickname (eglot-current-server)))
                'face 'eglot-mode-line)))

(defun bk-modeline--recording ()
  "Return the macro recording indicator, lualine's reg_recording section."
  (when defining-kbd-macro
    (propertize "REC" 'face 'bk-modeline-recording)))

(defun bk-modeline--encoding ()
  "Return the coding system, lualine's encoding section."
  (let ((name (symbol-name (or buffer-file-coding-system 'undecided))))
    ;; utf-8-unix reads better as just utf-8; the line ending has its own segment.
    (replace-regexp-in-string "-\\(unix\\|dos\\|mac\\)\\'" "" name)))

(defun bk-modeline--eol ()
  "Return the line ending style, lualine's fileformat section."
  (pcase (coding-system-eol-type buffer-file-coding-system)
    (0 "unix") (1 "dos") (2 "mac") (_ "")))

(defun bk-modeline--filetype ()
  "Return the major mode, lualine's filetype section.
`mode-name' is a mode-line construct rather than a string in most modes,
and `format-mode-line' on it can come back empty, so the major mode
symbol is the last resort."
  (let* ((rendered (cond ((stringp mode-name) mode-name)
                         (t (format-mode-line mode-name))))
         (name (if (string-empty-p (string-trim rendered))
                   (replace-regexp-in-string "-mode\\'" "" (symbol-name major-mode))
                 (string-trim rendered))))
    (format "%s %s" (bk-modeline--glyph 'file) name)))

(defun bk-modeline--position ()
  "Return scroll position and line:column, lualine's location section."
  (let ((scroll (string-trim (format-mode-line "%p")))
        (here (format "%d:%d" (line-number-at-pos) (1+ (current-column)))))
    (if (string-empty-p scroll) here (concat scroll "  " here))))

;;; Assembly

(defun bk-modeline--sep (glyph from to)
  "Return separator GLYPH coloured to bridge face FROM into face TO."
  (propertize (bk-modeline--glyph glyph)
              'face `(:foreground ,(face-attribute from :background nil 'default)
                      :background ,(face-attribute to :background nil 'default))))

(defun bk-modeline--left ()
  "Return the left side of the mode line, and its width."
  (let* ((state (bk-modeline--state))
         (state-face (bk-modeline--state-face))
         (branch (bk-modeline--branch))
         (pieces
          (if branch
              (list state
                    (bk-modeline--sep 'separator-right state-face 'bk-modeline-branch)
                    branch
                    (bk-modeline--sep 'separator-right 'bk-modeline-branch 'mode-line)
                    " ")
            (list state
                  (bk-modeline--sep 'separator-right state-face 'mode-line)
                  " "))))
    (apply #'concat pieces)))

(defun bk-modeline--right ()
  "Return the right side of the mode line."
  (let* ((loose (seq-filter #'identity (list (bk-modeline--diagnostics)
                                             (bk-modeline--server)
                                             (bk-modeline--recording))))
         (segment (propertize
                   (format " %s  %s  %s  %s "
                           (bk-modeline--encoding) (bk-modeline--eol)
                           (bk-modeline--filetype) (bk-modeline--position))
                   'face 'bk-modeline-segment)))
    (concat (when loose (concat (string-join loose "  ") " "))
            (bk-modeline--sep 'separator-left 'bk-modeline-segment 'mode-line)
            segment)))

(defun bk-modeline-format ()
  "Return the mode line for the current window."
  (let* ((left (bk-modeline--left))
         (right (bk-modeline--right))
         (width (window-width))
         ;; What is left for the path, after both sides and a column of padding.
         (available (- width (string-width left) (string-width right) 1))
         (path (bk-modeline--path (max 12 available)))
         (fill (max 1 (- width (string-width left) (string-width path)
                         (string-width right)))))
    (concat left path (make-string fill ?\s) right)))

(setq-default mode-line-format '(:eval (bk-modeline-format)))

(provide 'bk-modeline)
;;; bk-modeline.el ends here
