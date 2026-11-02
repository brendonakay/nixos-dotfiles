;;; bk-review.el --- Review a branch's changes in the editor -*- lexical-binding: t; -*-

;; Claude Code writes the code and commits it; this is for reading the result
;; without going to GitHub for it.  The scope is everything between a base ref
;; and the working tree, which is the same set a pull request would show, so it
;; covers committed work and anything still unstaged.
;;
;; The point of doing it here rather than in a TUI is that the files are just
;; files: RET opens the real buffer, so Eglot, xref, gd and gr all work, and the
;; changed region is only where you start reading rather than all you can see.
;;
;; Everything is built in.  git is called with `call-process', the list is a
;; `special-mode' buffer with clickable rows, diffs use `diff-mode', and the
;; entities under each file come from `imenu', which every major mode already
;; implements.  No package, and nothing parsed that git will not say plainly.
;;
;; The list is sorted newest first by modification time and rebuilt on a timer
;; while it is on screen, so it can sit in a window while Claude works: the
;; file being edited rises to the top and is highlighted.  mtime rather than
;; commit time because most of what Claude touches is not committed yet, and
;; reading it is a stat per file rather than a git log per file.

;;; Code:

(require 'imenu)
(require 'subr-x)

(defvar bk-review-base nil
  "Base ref to compare against, or nil to work it out.
nil means the merge base with the first of origin/HEAD, main or master
that exists, which is the branch point.  Set it per project with
dir-locals, or pass a prefix argument to `bk-review' to be asked.")

(defvar bk-review-recent-seconds 120
  "Files modified within this many seconds are highlighted.")

(defvar bk-review-refresh-interval 3
  "Seconds between checks for changes while a review buffer is visible.")

(defface bk-review-recent '((t :inherit warning :weight bold))
  "Face for files modified within `bk-review-recent-seconds'.")

(defface bk-review-added
  '((((background dark)) :background "#2f3d2f" :extend t)
    (t :background "#e3f2e3" :extend t))
  "Background for lines added since the base, in `bk-review-diff-mode'.
Background only, so the line keeps its syntax highlighting.")

(defface bk-review-removed '((t :inherit diff-removed :extend t))
  "Face for the removed lines `bk-review-diff-mode' shows inline.")

(defvar-local bk-review--base nil
  "Commit this buffer was last drawn against.
Resolved again from `bk-review--ref' and `bk-review--scope' on every
refresh, so it follows main when main moves and HEAD when you commit.")
(defvar-local bk-review--ref nil "Ref asked for, or nil to use the branch point.")
(defvar-local bk-review--scope 'branch
  "`branch' for everything since the base, `uncommitted' for since HEAD.")
(defvar-local bk-review--root nil "Repository root this buffer was built from.")
(defvar-local bk-review--expanded nil "Files whose entities are shown.")
(defvar-local bk-review--sort 'recent "How the list is ordered: `recent' or `path'.")
(defvar-local bk-review--signature nil "What the buffer last rendered, to skip no-op redraws.")

;;; git

(defun bk-review--git (root &rest args)
  "Run git ARGS in ROOT and return stdout, or nil if git failed."
  (let ((default-directory (file-name-as-directory root)))
    (with-temp-buffer
      (when (zerop (apply #'call-process "git" nil (list t nil) nil args))
        (buffer-string)))))

(defun bk-review--lines (root &rest args)
  "Run git ARGS in ROOT and return stdout as a list of non-empty lines."
  (when-let* ((out (apply #'bk-review--git root args)))
    (split-string out "\n" t)))

(defun bk-review--root ()
  "Return the repository root for `default-directory', or signal."
  (or (locate-dominating-file default-directory ".git")
      (user-error "Not inside a git repository")))

(defun bk-review--default-base (root)
  "Return the merge base of HEAD and ROOT's main branch."
  (let ((main (seq-find (lambda (ref) (bk-review--git root "rev-parse" "--verify" "--quiet" ref))
                        '("origin/HEAD" "origin/main" "main" "origin/master" "master"))))
    (or (when main
          (string-trim (or (bk-review--git root "merge-base" "HEAD" main) "")))
        ;; A repository with no other branch: everything since the first commit.
        (string-trim (or (bk-review--git root "rev-list" "--max-parents=0" "HEAD") "")))))

(defun bk-review--resolve-base (root ref scope)
  "Return the commit to diff against in ROOT, or nil if there is none.
SCOPE `uncommitted' means HEAD; otherwise REF, or the branch point when
REF is nil."
  (let ((sha (cond ((eq scope 'uncommitted)
                    (bk-review--git root "rev-parse" "--verify" "--quiet" "HEAD"))
                   (ref (bk-review--git root "rev-parse" "--verify" "--quiet" (concat ref "^{commit}")))
                   (t (bk-review--default-base root)))))
    (when sha
      (let ((sha (string-trim sha)))
        (unless (string-empty-p sha) sha)))))

(defun bk-review--update-base ()
  "Resolve `bk-review--base' again; return non-nil if it moved."
  (let ((base (or (bk-review--resolve-base bk-review--root bk-review--ref bk-review--scope)
                  (user-error "Could not work out a base ref; set bk-review-base"))))
    (unless (equal base bk-review--base)
      (setq bk-review--base base))))

(defun bk-review--changed-files (root base)
  "Return a list of (STATUS PATH ADDED DELETED MTIME) for changes since BASE.
MTIME is the file's modification time as a float, or nil when the file is
gone from disk.
Untracked files are included, since a new file is the most interesting
thing a review can contain."
  (let (files)
    ;; Tracked: numstat gives counts, name-status gives the letter.
    (let ((status (make-hash-table :test #'equal)))
      (dolist (line (bk-review--lines root "diff" "--name-status" base))
        (let ((parts (split-string line "\t")))
          ;; Renames arrive as R100 old new; the new name is what to open.
          (puthash (car (last parts)) (substring (car parts) 0 1) status)))
      (dolist (line (bk-review--lines root "diff" "--numstat" base))
        (pcase-let ((`(,added ,deleted . ,rest) (split-string line "\t")))
          (let ((path (car (last rest))))
            (push (list (gethash path status "M") path
                        (if (equal added "-") 0 (string-to-number added))
                        (if (equal deleted "-") 0 (string-to-number deleted))
                        (bk-review--mtime root path))
                  files)))))
    (dolist (path (bk-review--lines root "ls-files" "--others" "--exclude-standard"))
      (push (list "?" path
                  (with-temp-buffer
                    (let ((full (expand-file-name path root)))
                      (if (file-readable-p full)
                          (progn (insert-file-contents full) (count-lines (point-min) (point-max)))
                        0)))
                  0
                  (bk-review--mtime root path))
            files))
    files))

(defun bk-review--mtime (root path)
  "Return PATH's modification time as a float, or nil if it does not exist."
  (when-let* ((attrs (file-attributes (expand-file-name path root))))
    (float-time (file-attribute-modification-time attrs))))

(defun bk-review--sorted (files order)
  "Return FILES sorted by ORDER, `recent' or `path'.
Newest first for `recent'; deleted files have no mtime and go last."
  (sort (copy-sequence files)
        (if (eq order 'path)
            (lambda (a b) (string< (nth 1 a) (nth 1 b)))
          (lambda (a b)
            (let ((ta (or (nth 4 a) 0)) (tb (or (nth 4 b) 0)))
              (if (= ta tb) (string< (nth 1 a) (nth 1 b)) (> ta tb)))))))

(defun bk-review--age (mtime)
  "Return a short label for how long ago MTIME was.
Coarse on purpose: the label is part of the redraw signature, so a
finer one would redraw the list every tick."
  (if (null mtime)
      ""
    (let ((secs (- (float-time) mtime)))
      (cond ((< secs 60) "now")
            ((< secs 3600) (format "%dm" (/ secs 60)))
            ((< secs 86400) (format "%dh" (/ secs 3600)))
            (t (format "%dd" (/ secs 86400)))))))

(defun bk-review--recent-p (mtime)
  "Non-nil when MTIME is within `bk-review-recent-seconds'."
  (and mtime (< (- (float-time) mtime) bk-review-recent-seconds)))

(defun bk-review--changed-lines (root base path status)
  "Return the changed line numbers in PATH, on the new side."
  (if (equal status "?")
      '(1)
    (let (lines)
      (dolist (line (bk-review--lines root "diff" "-U0" base "--" path))
        ;; @@ -old,n +new,n @@
        (when (string-match "\\`@@ -[0-9,]+ \\+\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? @@" line)
          (let ((start (string-to-number (match-string 1 line)))
                (count (if (match-string 2 line) (string-to-number (match-string 2 line)) 1)))
            (dotimes (i (max count 1))
              (push (+ start i) lines)))))
      (or (nreverse lines) '(1)))))

(defun bk-review--file-diff (root base path status &rest args)
  "Return the diff of PATH since BASE, passing ARGS to git diff.
An untracked file (STATUS \"?\") is diffed against /dev/null, so it reads
as one big addition.  That form exits 1 whenever there is a difference,
which `bk-review--git' would treat as failure."
  (if (equal status "?")
      (let ((default-directory (file-name-as-directory root)))
        (with-temp-buffer
          (when (memq (apply #'call-process "git" nil (list t nil) nil "diff" "--no-index"
                             (append args (list "--" "/dev/null" path)))
                      '(0 1))
            (buffer-string))))
    (apply #'bk-review--git root "diff" (append args (list base "--" path)))))

;;; Entities

(defun bk-review--entities (root path lines)
  "Return (NAMES . NOTE) for the definitions in PATH touching LINES.
NAMES is a list of qualified names; NOTE explains an empty list rather
than leaving the reader guessing, which is the whole reason TAB looked
like it worked on some files and not others."
  (let ((full (expand-file-name path root)))
    (cond
     ((not (file-readable-p full)) (cons nil "file is not readable"))
     ((file-directory-p full) (cons nil "directory"))
     (t
      (with-temp-buffer
        (insert-file-contents full)
        ;; imenu needs the major mode, but not its hooks: those would start
        ;; Eglot and flymake against a temporary buffer.  `delay-mode-hooks' is
        ;; the macro, not a variable to bind.
        (let ((buffer-file-name full)
              (enable-local-variables nil))
          (delay-mode-hooks (ignore-errors (set-auto-mode))))
        (let* ((mode major-mode)
               (index (ignore-errors (imenu--make-index-alist t)))
               ;; Tree-sitter modes group the index under category names --
               ;; "Class", "Function", "Interface" -- which are not containers
               ;; and only clutter a qualified name.
               (bk-review--categories (mapcar #'car (bound-and-true-p treesit-simple-imenu-settings)))
               (defs (sort (bk-review--flatten index)
                           (lambda (a b) (< (cdr a) (cdr b)))))
               (last-line (line-number-at-pos (point-max)))
               found)
          ;; A definition runs until the next one starts, so a changed line
          ;; between the two belongs to it.  imenu gives only the start of each;
          ;; the next start is the only honest guess available without a parser
          ;; per language.
          (let ((rest defs))
            (while rest
              (let* ((this (car rest))
                     (start (line-number-at-pos (cdr this)))
                     (end (if (cdr rest) (line-number-at-pos (cdr (cadr rest))) (1+ last-line))))
                (when (seq-find (lambda (l) (and (>= l start) (< l end))) lines)
                  (push (car this) found)))
              (setq rest (cdr rest))))
          (setq found (nreverse (delete-dups found)))
          (cons found
                (cond
                 (found nil)
                 ((eq mode 'fundamental-mode)
                  (format "no major mode for %s" (file-name-nondirectory path)))
                 ((null defs)
                  (format "%s has no imenu index" mode))
                 (t (format "%d definition%s in %s, none on the %d changed line%s"
                            (length defs) (if (= 1 (length defs)) "" "s") mode
                            (length lines) (if (= 1 (length lines)) "" "s")))))))))))

(defun bk-review--clean-name (name)
  "Strip imenu's decoration from NAME.
python-mode appends \" (class)\" and \" (def)\", which is noise once the
names are qualified."
  (replace-regexp-in-string " ([a-z]+)\\'" "" name))

(defvar bk-review--categories nil
  "Imenu section names that are categories rather than containers.")

(defun bk-review--flatten (index &optional prefix)
  "Flatten imenu INDEX into (QUALIFIED-NAME . POSITION) pairs.
PREFIX is the enclosing section's name.  Carrying it is the point: modes
nest methods under their class, so dropping it loses every class name and
leaves behind leaves like \"*class definition*\"."
  (let (out)
    (dolist (entry index)
      (when (consp entry)
        (let* ((raw (car entry))
               (rest (cdr entry))
               (name (bk-review--clean-name raw))
               ;; imenu wraps a container's own position in asterisks, as in
               ;; python-mode's "*class definition*".  That is the class itself,
               ;; so it takes the class's name.
               (qualified (cond
                           ;; A container's own position: imenu marks it with a
                           ;; name in asterisks, tree-sitter modes with an empty
                           ;; one.  Either way it is the container itself.
                           ((and prefix (or (string-blank-p name)
                                            (string-match-p "\\`\\*.*\\*\\'" raw)))
                            prefix)
                           ;; A tree-sitter category, not a container.
                           ((and (null prefix) (member raw bk-review--categories)) nil)
                           (prefix (concat prefix "." name))
                           (t name))))
          (cond
           ((equal raw "*Rescan*") nil)
           ;; A nested section: recurse, carrying this name down.
           ((and (consp rest) (consp (car rest)))
            (setq out (append out (bk-review--flatten rest qualified))))
           ;; A plain leaf.
           ((or (markerp rest) (numberp rest))
            (push (cons qualified rest) out))
           ;; imenu's "special" item form: (NAME POSITION FUNCTION . ARGS).
           ((and (consp rest) (or (markerp (car rest)) (numberp (car rest))))
            (push (cons qualified (car rest)) out))))))
    (nreverse out)))

;;; Buffer

(defun bk-review--file-at-point ()
  "Return the review entry at point, or signal."
  (or (get-text-property (point) 'bk-review-entry)
      (user-error "No file on this line")))

(defun bk-review-mouse-visit (event)
  "Open the file on the row clicked in EVENT, as RET does."
  (interactive "e")
  (mouse-set-point event)
  (bk-review-visit))

;; The whole row is the click target, not just the path.  A `keymap' text
;; property is consulted before Evil's state maps, which would otherwise take
;; the click; `follow-link' turns a mouse-1 click into the mouse-2 bound here,
;; the same route a button takes.
(defvar-keymap bk-review-row-map
  :doc "Mouse bindings for a file row in `bk-review-mode'."
  "<mouse-2>" #'bk-review-mouse-visit)

(defun bk-review--insert-entry (entry root base)
  "Insert one ENTRY for the file list."
  (pcase-let ((`(,status ,path ,added ,deleted ,mtime) entry))
    (let ((start (point))
          (recent (bk-review--recent-p mtime)))
      (insert "  " (propertize (format "%-2s" status)
                               'face (pcase status
                                       ("A" 'diff-added) ("?" 'diff-added)
                                       ("D" 'diff-removed) (_ 'diff-changed)))
              " "
              (propertize (format "%4s" (bk-review--age mtime))
                          'face (if recent 'bk-review-recent 'shadow))
              "  ")
      (insert (propertize path 'face (if recent 'bk-review-recent 'default)))
      (insert (propertize (format "  +%d" added) 'face 'diff-added))
      (insert (propertize (format " -%d" deleted) 'face 'diff-removed))
      (add-text-properties start (point) (list 'keymap bk-review-row-map
                                               'follow-link t
                                               'mouse-face 'highlight
                                               'help-echo "mouse-1: open with the diff inline"))
      (insert "\n")
      (when (member path bk-review--expanded)
        (pcase-let ((`(,names . ,note)
                     (bk-review--entities
                      root path (bk-review--changed-lines root base path status))))
          (if names
              (dolist (name names)
                (insert "       " (propertize name 'face 'font-lock-function-name-face) "\n"))
            (insert "       " (propertize (or note "nothing found") 'face 'shadow) "\n"))))
      (put-text-property start (point) 'bk-review-entry entry))))

(defun bk-review--render (root base files)
  "Render FILES into the current buffer."
  (let ((inhibit-read-only t)
        (line (line-number-at-pos))
        ;; The list reorders as files change, so follow the file rather than
        ;; the line number.
        (path (nth 1 (get-text-property (point) 'bk-review-entry))))
    (setq files (bk-review--sorted files bk-review--sort))
    (erase-buffer)
    (insert (propertize (format "Review  %s\n" (abbreviate-file-name root)) 'face 'bold))
    (insert (propertize (format "since   %s %s" (substring base 0 (min 12 (length base)))
                                (if (eq bk-review--scope 'uncommitted) "(HEAD, uncommitted only)"
                                  (or bk-review--ref "(branch point)")))
                        'face 'shadow))
    (when-let* ((branch (bk-review--git root "rev-parse" "--abbrev-ref" "HEAD")))
      (insert (propertize (format "   on %s" (string-trim branch)) 'face 'shadow)))
    (insert "\n\n")
    (if (null files)
        (insert "  No changes since the base.\n")
      (dolist (entry files)
        (bk-review--insert-entry entry root base))
      (insert "\n")
      (insert (propertize (format "  %d file%s changed\n" (length files)
                                  (if (= 1 (length files)) "" "s"))
                          'face 'shadow)))
    (insert (propertize (format "\n  RET open   d diff   TAB entities   s sort (%s)   u scope (%s)   r refresh   q quit\n"
                                bk-review--sort bk-review--scope)
                        'face 'shadow))
    (goto-char (point-min))
    (let ((match (and path
                      (text-property-search-forward
                       'bk-review-entry path
                       (lambda (want entry) (equal want (nth 1 entry)))))))
      (if match
          (goto-char (prop-match-beginning match))
        (goto-char (point-min))
        (forward-line (1- line))))))

(defun bk-review-refresh ()
  "Rebuild the review list."
  (interactive)
  (bk-review--update-base)
  (let ((files (bk-review--changed-files bk-review--root bk-review--base)))
    (setq bk-review--signature (bk-review--signature files))
    (bk-review--render bk-review--root bk-review--base files)))

(defun bk-review--signature (files)
  "Return what a render of FILES would show, for comparing against the last one."
  (list bk-review--base bk-review--scope bk-review--sort bk-review--expanded
        (mapcar (lambda (f) (list f (bk-review--age (nth 4 f))
                                  (bk-review--recent-p (nth 4 f))))
                files)))

;;; Live updates

(defvar bk-review--timer nil "Timer that keeps visible review and diff buffers current.")

(defun bk-review--tick ()
  "Redraw each visible review buffer whose files have changed.
Also redraw each visible `bk-review-diff-mode' buffer whose base moved,
which is how a commit clears the inline diff: the file is unchanged, so
neither save nor revert fires."
  (let ((reviews (seq-filter (lambda (b) (eq (buffer-local-value 'major-mode b) 'bk-review-mode))
                             (buffer-list)))
        (diffs (seq-filter (lambda (b) (buffer-local-value 'bk-review-diff-mode b))
                           (buffer-list))))
    (if (and (null reviews) (null diffs))
        (progn (cancel-timer bk-review--timer)
               (setq bk-review--timer nil))
      (dolist (buffer diffs)
        (when (get-buffer-window buffer t)
          (with-current-buffer buffer
            (with-demoted-errors "bk-review: %S"
              (when (bk-review--update-base)
                (bk-review--diff-draw))))))
      (dolist (buffer reviews)
        (when-let* ((window (get-buffer-window buffer t)))
          (with-current-buffer buffer
            (with-demoted-errors "bk-review: %S"
              (bk-review--update-base)
              (let ((files (bk-review--changed-files bk-review--root bk-review--base)))
                (unless (equal (bk-review--signature files) bk-review--signature)
                  ;; A timer runs with the buffer's own point, not the
                  ;; window's, so carry the window's across the redraw.
                  (goto-char (window-point window))
                  (setq bk-review--signature (bk-review--signature files))
                  (bk-review--render bk-review--root bk-review--base files)
                  (set-window-point window (point)))))))))))

(defun bk-review--start-timer ()
  "Start the live-update timer unless it is already running."
  (unless bk-review--timer
    (setq bk-review--timer
          (run-with-timer bk-review-refresh-interval bk-review-refresh-interval
                          #'bk-review--tick))))

(defun bk-review-toggle-sort ()
  "Switch between newest-first and path order."
  (interactive)
  (setq bk-review--sort (if (eq bk-review--sort 'recent) 'path 'recent))
  (bk-review-refresh))

(defvar bk-review-diff-mode)            ; defined with the inline diff below

(defun bk-review-toggle-scope ()
  "Switch between the whole branch and uncommitted changes only.
Inline diffs opened from this repository switch with it."
  (interactive)
  (let ((scope (if (eq bk-review--scope 'branch) 'uncommitted 'branch))
        (root bk-review--root))
    (setq bk-review--scope scope)
    (bk-review-refresh)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and bk-review-diff-mode (equal bk-review--root root))
          (setq bk-review--scope scope)
          (bk-review--update-base)
          (bk-review--diff-draw))))
    (message "Review: %s" (if (eq scope 'branch) "whole branch" "uncommitted only"))))

(defun bk-review-visit ()
  "Open the file at point at its first change, with the diff shown inline.
The real file buffer, so the language server and xref work in it."
  (interactive)
  (pcase-let ((`(,status ,path . ,_) (bk-review--file-at-point)))
    (let ((root bk-review--root)
          (ref bk-review--ref)
          (scope bk-review--scope)
          (lines (bk-review--changed-lines bk-review--root bk-review--base path status)))
      (pop-to-buffer (find-file-noselect (expand-file-name path root)))
      (setq bk-review--root root
            bk-review--ref ref
            bk-review--scope scope)
      (bk-review-diff-mode 1)
      (goto-char (point-min))
      (forward-line (1- (car lines))))))

(defun bk-review-diff ()
  "Show the diff for the file at point."
  (interactive)
  (pcase-let ((`(,status ,path . ,_) (bk-review--file-at-point)))
    (let ((root bk-review--root) (base bk-review--base))
      (with-current-buffer (get-buffer-create "*Review Diff*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (or (bk-review--file-diff root base path status) ""))
          (goto-char (point-min)))
        (diff-mode)
        (setq default-directory (file-name-as-directory root))
        (pop-to-buffer (current-buffer))))))

(defun bk-review-toggle-entities ()
  "Show or hide the definitions the change touches for the file at point."
  (interactive)
  (pcase-let ((`(,_ ,path . ,_) (bk-review--file-at-point)))
    (setq bk-review--expanded
          (if (member path bk-review--expanded)
              (delete path bk-review--expanded)
            (cons path bk-review--expanded)))
    (bk-review-refresh)))

(defvar-keymap bk-review-mode-map
  :doc "Keymap for `bk-review-mode'."
  "RET" #'bk-review-visit
  "d"   #'bk-review-diff
  "TAB" #'bk-review-toggle-entities
  "s"   #'bk-review-toggle-sort
  "u"   #'bk-review-toggle-scope
  "r"   #'bk-review-refresh)

;; Evil's state keymaps live in `emulation-mode-map-alists', which is consulted
;; before any major mode map, so the bindings above never fire while Evil is in
;; normal state: RET runs `evil-ret' and just moves down a line, d is the delete
;; operator, TAB is `evil-jump-forward'.  The same rule that makes Evil win over
;; corfu-map in bk-completion.el.  Binding them through `evil-define-key' puts
;; them in Evil's own map for this mode, which does win.
;;
;; g is deliberately left alone so gg still goes to the top; refresh is r, which
;; is `evil-replace' elsewhere and useless in a read-only buffer, as s is
;; `evil-substitute' and u is `evil-undo'.  j, k and q
;; already do the right thing and are not touched.
(with-eval-after-load 'evil
  (evil-define-key '(normal motion) bk-review-mode-map
    (kbd "RET") #'bk-review-visit
    "d"         #'bk-review-diff
    (kbd "TAB") #'bk-review-toggle-entities
    "s"         #'bk-review-toggle-sort
    "u"         #'bk-review-toggle-scope
    "r"         #'bk-review-refresh
    "q"         #'quit-window))

(define-derived-mode bk-review-mode special-mode "Review"
  "Major mode for reviewing everything a branch changed."
  (setq-local truncate-lines t))

;;; Inline diff

;; ANCHOR: inline diff in the real file buffer.
;; A unified diff drawn over the file itself rather than in a separate
;; buffer: added lines are tinted, removed lines appear as read-only text
;; above where they were, and each gets a + or - in the left margin, which
;; works in a terminal where the fringe does not exist.  Overlays only, so
;; the buffer text is untouched and Eglot and editing behave as normal.

(defvar-local bk-review--hunk-starts nil
  "Buffer positions where each hunk begins, for `bk-review-next-hunk'.")

(defun bk-review--hunks (diff)
  "Parse a -U0 DIFF into a list of (START COUNT REMOVED).
START and COUNT are the new side of each hunk; REMOVED is the old lines."
  (let (hunks)
    (dolist (line (split-string diff "\n"))
      (cond
       ((string-match "\\`@@ -[0-9,]+ \\+\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? @@" line)
        (push (list (string-to-number (match-string 1 line))
                    (if (match-string 2 line) (string-to-number (match-string 2 line)) 1)
                    nil)
              hunks))
       ;; Lines before the first hunk are headers, where --- is not a removal.
       ((and hunks (string-prefix-p "-" line))
        (setf (nth 2 (car hunks)) (append (nth 2 (car hunks)) (list (substring line 1)))))))
    (nreverse hunks)))

(defun bk-review--margin (char face)
  "Return CHAR as a left-margin display string in FACE."
  (propertize " " 'display `((margin left-margin) ,(propertize char 'face face))))

(defun bk-review--diff-overlay (beg end &rest props)
  "Make an overlay from BEG to END tagged as ours, with PROPS."
  (let ((ov (make-overlay beg end nil t nil)))
    (overlay-put ov 'bk-review-diff t)
    (while props
      (overlay-put ov (pop props) (pop props)))
    ov))

(defun bk-review--diff-clear ()
  "Remove the inline diff from the current buffer."
  (remove-overlays (point-min) (point-max) 'bk-review-diff t)
  (setq bk-review--hunk-starts nil))

(defun bk-review--draw-removed (removed)
  "Show the REMOVED lines above the line at point.
They hang off the end of the line above rather than the start of this
one: a line number is drawn where a buffer line starts, so text put in
front of this line would take its number."
  (let ((lines (mapcar (lambda (text)
                         (concat (bk-review--margin "-" 'diff-indicator-removed)
                                 (propertize text 'face 'bk-review-removed)))
                       removed)))
    (if (bobp)
        (bk-review--diff-overlay (point) (point) 'before-string
                                 (mapconcat (lambda (l) (concat l "\n")) lines))
      ;; Before the previous line's newline, or after a last line that lacks one.
      (let ((pos (if (bolp) (1- (point)) (point))))
        (bk-review--diff-overlay pos pos 'after-string
                                 (mapconcat (lambda (l) (concat "\n" l)) lines))))))

(defun bk-review--diff-draw ()
  "Draw the changes since `bk-review--base' over the current buffer."
  (bk-review--diff-clear)
  (when-let* ((file buffer-file-name)
              (path (file-relative-name file bk-review--root))
              (status (if (bk-review--git bk-review--root "ls-files" "--error-unmatch" "--" path) "M" "?"))
              (diff (bk-review--file-diff bk-review--root bk-review--base path status "-U0")))
    (save-excursion
      (save-restriction
        (widen)
        (pcase-dolist (`(,start ,count ,removed) (bk-review--hunks diff))
          ;; git numbers a pure deletion by the line before it.
          (goto-char (point-min))
          (forward-line (if (zerop count) start (1- start)))
          (push (point) bk-review--hunk-starts)
          (when removed
            (bk-review--draw-removed removed))
          (unless (zerop count)
            (let ((beg (point)))
              (dotimes (_ count)
                (bk-review--diff-overlay (point) (point) 'before-string
                                         (bk-review--margin "+" 'diff-indicator-added))
                (forward-line 1))
              (bk-review--diff-overlay beg (point) 'face 'bk-review-added))))))
    (setq bk-review--hunk-starts (sort bk-review--hunk-starts #'<))))

(defun bk-review--set-margins ()
  "Apply `left-margin-width' to every window showing this buffer."
  (dolist (window (get-buffer-window-list nil nil t))
    (set-window-margins window left-margin-width right-margin-width)))

(define-minor-mode bk-review-diff-mode
  "Show the changes since the review base inline in this file.
Redraws on save and on revert, so edits made outside Emacs show up as
auto-revert picks them up, and when the base moves, so a commit clears
what it committed in the `uncommitted' scope."
  :lighter " Diff"
  (if bk-review-diff-mode
      (progn
        (unless bk-review--root
          (setq bk-review--root (expand-file-name (bk-review--root))
                bk-review--ref bk-review-base))
        (bk-review--update-base)
        (bk-review--start-timer)
        (setq-local left-margin-width 1)
        (bk-review--set-margins)
        (bk-review--diff-draw)
        (add-hook 'after-save-hook #'bk-review--diff-draw nil t)
        (add-hook 'after-revert-hook #'bk-review--diff-draw nil t))
    (bk-review--diff-clear)
    (remove-hook 'after-save-hook #'bk-review--diff-draw t)
    (remove-hook 'after-revert-hook #'bk-review--diff-draw t)
    (kill-local-variable 'left-margin-width)
    (bk-review--set-margins)))

(defun bk-review-next-hunk ()
  "Move to the start of the next change."
  (interactive)
  (let ((here (line-end-position)))
    (goto-char (or (seq-find (lambda (p) (> p here)) bk-review--hunk-starts)
                   (user-error "No later change")))))

(defun bk-review-previous-hunk ()
  "Move to the start of the previous change."
  (interactive)
  (let ((here (line-beginning-position)))
    (goto-char (or (seq-find (lambda (p) (< p here)) (reverse bk-review--hunk-starts))
                   (user-error "No earlier change")))))

;; Vim's diff-mode motions.  A minor-mode key, so ]c and [c mean this only in
;; a buffer showing the diff.
(with-eval-after-load 'evil
  (evil-define-minor-mode-key '(normal motion) 'bk-review-diff-mode
    "]c" #'bk-review-next-hunk
    "[c" #'bk-review-previous-hunk))

;;;###autoload
(defun bk-review (&optional ask)
  "Review everything changed since the base ref.
With a prefix argument ASK, prompt for the ref."
  (interactive "P")
  (let ((root (expand-file-name (bk-review--root)))
        (ref (if ask (read-string "Base ref: " (or bk-review-base "main")) bk-review-base)))
    (with-current-buffer (get-buffer-create "*Review*")
      (bk-review-mode)
      (setq bk-review--root root
            bk-review--ref ref
            bk-review--expanded nil)
      (bk-review-refresh)
      (bk-review--start-timer)
      (pop-to-buffer (current-buffer)))))

(provide 'bk-review)
;;; bk-review.el ends here
