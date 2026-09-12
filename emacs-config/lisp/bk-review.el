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
;; `special-mode' buffer with text buttons, diffs use `diff-mode', and the
;; entities under each file come from `imenu', which every major mode already
;; implements.  No package, and nothing parsed that git will not say plainly.

;;; Code:

(require 'imenu)
(require 'subr-x)

(defvar bk-review-base nil
  "Base ref to compare against, or nil to work it out.
nil means the merge base with the first of origin/HEAD, main or master
that exists, which is the branch point.  Set it per project with
dir-locals, or pass a prefix argument to `bk-review' to be asked.")

(defvar-local bk-review--base nil "Base ref this buffer was built from.")
(defvar-local bk-review--root nil "Repository root this buffer was built from.")
(defvar-local bk-review--expanded nil "Files whose entities are shown.")

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

(defun bk-review--changed-files (root base)
  "Return a list of (STATUS PATH ADDED DELETED) for changes since BASE.
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
                        (if (equal deleted "-") 0 (string-to-number deleted)))
                  files)))))
    (dolist (path (bk-review--lines root "ls-files" "--others" "--exclude-standard"))
      (push (list "?" path
                  (with-temp-buffer
                    (let ((full (expand-file-name path root)))
                      (if (file-readable-p full)
                          (progn (insert-file-contents full) (count-lines (point-min) (point-max)))
                        0)))
                  0)
            files))
    (sort files (lambda (a b) (string< (nth 1 a) (nth 1 b))))))

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

(defun bk-review--insert-entry (entry root base)
  "Insert one ENTRY for the file list."
  (pcase-let ((`(,status ,path ,added ,deleted) entry))
    (let ((start (point)))
      (insert "  " (propertize (format "%-2s" status)
                               'face (pcase status
                                       ("A" 'diff-added) ("?" 'diff-added)
                                       ("D" 'diff-removed) (_ 'diff-changed)))
              " ")
      (insert-text-button path 'face 'default 'follow-link t
                          'action (lambda (_) (bk-review-visit)))
      (insert (propertize (format "  +%d" added) 'face 'diff-added))
      (insert (propertize (format " -%d" deleted) 'face 'diff-removed))
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
        (line (line-number-at-pos)))
    (erase-buffer)
    (insert (propertize (format "Review  %s\n" (abbreviate-file-name root)) 'face 'bold))
    (insert (propertize (format "since   %s" (substring base 0 (min 12 (length base)))) 'face 'shadow))
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
    (insert (propertize "\n  RET open   d diff   TAB entities   r refresh   q quit\n" 'face 'shadow))
    (goto-char (point-min))
    (forward-line (1- line))))

(defun bk-review-refresh ()
  "Rebuild the review list."
  (interactive)
  (bk-review--render bk-review--root bk-review--base
                     (bk-review--changed-files bk-review--root bk-review--base)))

(defun bk-review-visit ()
  "Open the file at point at its first change.
The real file buffer, so the language server and xref work in it."
  (interactive)
  (pcase-let ((`(,status ,path ,_ ,_) (bk-review--file-at-point)))
    (let ((lines (bk-review--changed-lines bk-review--root bk-review--base path status)))
      (pop-to-buffer (find-file-noselect (expand-file-name path bk-review--root)))
      (goto-char (point-min))
      (forward-line (1- (car lines))))))

(defun bk-review-diff ()
  "Show the diff for the file at point."
  (interactive)
  (pcase-let ((`(,_ ,path ,_ ,_) (bk-review--file-at-point)))
    (let ((root bk-review--root) (base bk-review--base))
      (with-current-buffer (get-buffer-create "*Review Diff*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (or (bk-review--git root "diff" base "--" path)
                      ;; Untracked: show the file as one big addition.
                      (bk-review--git root "diff" "--no-index" "/dev/null" path)
                      ""))
          (goto-char (point-min)))
        (diff-mode)
        (setq default-directory (file-name-as-directory root))
        (pop-to-buffer (current-buffer))))))

(defun bk-review-toggle-entities ()
  "Show or hide the definitions the change touches for the file at point."
  (interactive)
  (pcase-let ((`(,_ ,path ,_ ,_) (bk-review--file-at-point)))
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
  "r"   #'bk-review-refresh)

;; Evil's state keymaps live in `emulation-mode-map-alists', which is consulted
;; before any major mode map, so the bindings above never fire while Evil is in
;; normal state: RET runs `evil-ret' and just moves down a line, d is the delete
;; operator, TAB is `evil-jump-forward'.  The same rule that makes Evil win over
;; corfu-map in bk-completion.el.  Binding them through `evil-define-key' puts
;; them in Evil's own map for this mode, which does win.
;;
;; g is deliberately left alone so gg still goes to the top; refresh is r, which
;; is `evil-replace' elsewhere and useless in a read-only buffer.  j, k and q
;; already do the right thing and are not touched.
(with-eval-after-load 'evil
  (evil-define-key '(normal motion) bk-review-mode-map
    (kbd "RET") #'bk-review-visit
    "d"         #'bk-review-diff
    (kbd "TAB") #'bk-review-toggle-entities
    "r"         #'bk-review-refresh
    "q"         #'quit-window))

(define-derived-mode bk-review-mode special-mode "Review"
  "Major mode for reviewing everything a branch changed."
  (setq-local truncate-lines t))

;;;###autoload
(defun bk-review (&optional ask)
  "Review everything changed since the base ref.
With a prefix argument ASK, prompt for the ref."
  (interactive "P")
  (let* ((root (expand-file-name (bk-review--root)))
         (base (cond (ask (read-string "Base ref: " (or bk-review-base "main")))
                     (bk-review-base)
                     (t (bk-review--default-base root)))))
    (when (string-empty-p base)
      (user-error "Could not work out a base ref; set bk-review-base"))
    (with-current-buffer (get-buffer-create "*Review*")
      (bk-review-mode)
      (setq bk-review--root root
            bk-review--base base
            bk-review--expanded nil)
      (bk-review-refresh)
      (pop-to-buffer (current-buffer)))))

(provide 'bk-review)
;;; bk-review.el ends here
