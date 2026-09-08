;;; bk-container.el --- Language servers inside a container -*- lexical-binding: t; -*-

;; Some projects have to build against a userspace that is not this machine's.
;; The CS6200 coursework is the case this was written for: the class ships an
;; Ubuntu 22.04 image built on gradescope/auto-builds, and the grader runs there,
;; so what matters is what gcc 11.4 and glibc 2.35 make of the code -- not what
;; this system's gcc 15.3 and glibc 2.42 do.
;;
;; The kernel is not part of that difference.  A container shares the host's
;; kernel, so `uname -r' inside the Ubuntu image reports this NixOS kernel and
;; every syscall, /proc entry and scheduling behaviour is the same one.  Only the
;; userspace above it differs, which is exactly the part clangd reads.
;;
;; So clangd runs in the container, over `docker exec', while Emacs stays here
;; editing the bind-mounted files directly.  Nothing is copied and nothing is
;; remote: the files under the mount are ordinary local files to Emacs.

;;; Code:

(require 'eglot)

(defvar bk-container-alist
  '(("~/OMSCS/CS6200" . "cs6200-dev"))
  "Alist of (DIRECTORY . IMAGE).
A C buffer anywhere under DIRECTORY gets its language server from a
running container of IMAGE rather than from this machine.  One entry
covers every repo under it -- the coursework has the class environment
and each project in repos of their own, and they all want the same
Ubuntu.  The container has to bind-mount DIRECTORY, or an ancestor of it,
and have clangd installed; ../README.md has the Dockerfile and the run
command.")

(defun bk-container--entry (dir)
  "Return the `bk-container-alist' entry covering DIR, or nil."
  (seq-find (lambda (entry)
              (string-prefix-p (file-name-as-directory
                                (expand-file-name (car entry)))
                               (file-name-as-directory (expand-file-name dir))))
            bk-container-alist))

(defun bk-container--id (image)
  "Return the id of a running container of IMAGE, or nil."
  (with-temp-buffer
    (when (zerop (call-process "docker" nil t nil "ps"
                               "--filter" (concat "ancestor=" image)
                               "--filter" "status=running"
                               "--format" "{{.ID}}"))
      (let ((id (car (split-string (buffer-string) "\n" t))))
        (and id (not (string-empty-p id)) id)))))

(defun bk-container--mounts (id)
  "Return the bind mounts of container ID as a list of (SOURCE . DESTINATION)."
  (with-temp-buffer
    (when (zerop (call-process "docker" nil t nil "inspect" id "--format"
                               "{{range .Mounts}}{{.Source}}\t{{.Destination}}\n{{end}}"))
      (goto-char (point-min))
      (let (mounts)
        (while (not (eobp))
          (let ((line (buffer-substring-no-properties
                       (line-beginning-position) (line-end-position))))
            (when (string-match "\\`\\(.+\\)\t\\(.+\\)\\'" line)
              (push (cons (directory-file-name (match-string 1 line))
                          (directory-file-name (match-string 2 line)))
                    mounts)))
          (forward-line 1))
        (nreverse mounts)))))

(defun bk-container--mountpoint (id root)
  "Return the path inside container ID that holds ROOT, or nil.
The mount does not have to be of ROOT itself: mounting one directory that
holds several coursework repos is the tidier arrangement, so the deepest
mount containing ROOT wins and the rest of the path is appended to its
destination."
  (let* ((want (directory-file-name (expand-file-name root)))
         (best (car (sort (seq-filter
                           (lambda (m)
                             (or (string-equal (car m) want)
                                 (string-prefix-p (file-name-as-directory (car m))
                                                  (file-name-as-directory want))))
                           (bk-container--mounts id))
                          (lambda (a b) (> (length (car a)) (length (car b))))))))
    (when best
      (concat (cdr best) (substring want (length (car best)))))))

(defun bk-container--link (id root mount)
  "Make ROOT resolve to MOUNT inside container ID.
Eglot sends absolute paths, and they are this machine's: the buffer is a
local file under the bind mount.  clangd on the other side has the same
bytes at a different path, so a symlink at the host path pointing at the
mount makes both names work and no path translation is needed anywhere.
It is recreated on every connect because a fresh container will not have
it."
  ;; `expand-file-name' first: the roots in `bk-container-alist' are written
  ;; with a tilde, and `shell-quote-argument' escapes it to \~ so the container
  ;; shell would take it literally and make a directory called ~ in $PWD.
  (unless (string-equal (directory-file-name (expand-file-name root))
                        (directory-file-name mount))
    (let ((link (directory-file-name (expand-file-name root))))
      (call-process "docker" nil nil nil "exec" id "sh" "-c"
                    (format "mkdir -p %s && ln -sfn %s %s"
                            (shell-quote-argument
                             (file-name-directory link))
                            (shell-quote-argument mount)
                            (shell-quote-argument link))))))

(defun bk-container-clangd (&optional _interactive project)
  "Return the clangd command for PROJECT, or for `default-directory'.
Falls back to this machine's clangd when the directory is not a container
one or the container is not running, so a C file outside the coursework,
or the coursework with nothing started, still gets a server.

The argument list is not optional decoration.  Eglot calls a function
contact from two places and they do not agree: `eglot--connect' calls it
with no arguments, while `eglot--guess-contact' reads `func-arity' and
calls it with (INTERACTIVE PROJECT) for anything whose maximum arity is
not exactly 1.  A nullary function therefore loads fine and then fails
with wrong-number-of-arguments the moment a C file is opened.  Two
optional arguments satisfy both."
  (let* ((dir (or (and project (project-root project)) default-directory))
         (entry (bk-container--entry dir))
         (id (and entry (bk-container--id (cdr entry))))
         (mount (and id (bk-container--mountpoint id (car entry)))))
    (cond
     ((and id mount)
      (bk-container--link id (car entry) mount)
      ;; --header-insertion=never: clangd's automatic #include on completion
      ;; guesses badly on coursework that is deliberately spare about headers.
      (list "docker" "exec" "-i" id "clangd" "--header-insertion=never"))
     (entry
      (message "bk-container: no running %s container; using local clangd"
               (cdr entry))
      (list "clangd" "--header-insertion=never"))
     (t (list "clangd" "--header-insertion=never")))))

;; Prepended, so this wins over Eglot's own c-mode entry.  bk-lsp.el's typos-lsp
;; catch-all is appended and stays behind both.
(add-to-list 'eglot-server-programs
             '((c-mode c-ts-mode c++-mode c++-ts-mode) . bk-container-clangd))

(defvar bk-container-compile-command "make "
  "The command `bk-container-compile' offers, before it is wrapped.
Deliberately not `compile-command'.  `compile' assigns whatever it is
given to that variable, and what it is given here is the whole
`docker exec ... sh -c ...' line; reading the default back out of it
would wrap that line again on the next call, and again on the one after,
each time escaping the previous layer.")

(defun bk-container-compile (command)
  "Run COMMAND in the container, from this project's directory in it.
The compiler that matters is the one the build is graded or shipped on,
so <leader>c's `compile' is the wrong tool inside a container project: it
would build with this machine's gcc.  Errors are still parsed into a
compilation buffer, and the paths in them match because the file names
agree on both sides."
  (interactive
   (list (read-shell-command "Compile in container: "
                             bk-container-compile-command)))
  (setq bk-container-compile-command command)
  (let* ((entry (or (bk-container--entry default-directory)
                    (user-error "Not under a container project")))
         (id (or (bk-container--id (cdr entry))
                 (user-error "No running %s container" (cdr entry))))
         (mount (bk-container--mountpoint id (car entry))))
    (bk-container--link id (car entry) mount)
    ;; Let-bound so `compile' assigns the wrapped line to a binding that ends
    ;; with this form, leaving <leader>c's own default alone as well.
    (let ((compile-command compile-command))
      (compile (format "docker exec -w %s %s sh -c %s"
                       (shell-quote-argument (expand-file-name default-directory))
                       id
                       (shell-quote-argument command))))))

(defun bk-container-shell ()
  "Open a shell in this project's container, in a new tmux window.
Same reasoning as `bk-git-lazygit': a real terminal for a real terminal
job, rather than asking Emacs to be a terminal emulator."
  (interactive)
  (let* ((entry (or (bk-container--entry default-directory)
                    (user-error "Not under a container project")))
         (id (or (bk-container--id (cdr entry))
                 (user-error "No running %s container" (cdr entry)))))
    (unless (getenv "TMUX")
      (user-error "Not inside tmux; run docker exec in a terminal instead"))
    (call-process "tmux" nil nil nil "new-window"
                  (format "docker exec -it -w %s %s /bin/bash"
                          (shell-quote-argument (expand-file-name default-directory))
                          id))))

(provide 'bk-container)
;;; bk-container.el ends here
