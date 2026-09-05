;;; bk-git.el --- Version control -*- lexical-binding: t; -*-

;; From lua/plugins/gitblame.lua and lazygit.lua.  Emacs has VC built in, which
;; covers what fugitive and git-messenger were for: `vc-annotate' is blame,
;; `vc-print-log' is the file history, `vc-diff' is the diff.  Magit is the
;; famous third-party option and is genuinely better, but it is a large package
;; and the built-in covers this config's bindings.
;;
;; No equivalent of vim-gitgutter or mini.diff is set up: gutter marks need
;; diff-hl, which would be another package.  `vc-diff' and `diff-hl' are the two
;; ways to see the same information; this config uses the former.

;;; Code:

(setq vc-handled-backends '(Git)          ; the only one in use, and it speeds startup
      vc-git-diff-switches '("--histogram")
      vc-annotate-background-mode nil
      vc-command-messages nil)

;; Magit. Built-in VC still handles the small things bound below, blame and file
;; history, but anything involving staging, rebasing or reading a branch is
;; Magit's job.
(with-eval-after-load 'magit
  (setq magit-diff-refine-hunk 'all          ; word-level diffs, like gitgutter's
        magit-save-repository-buffers 'dontask
        magit-bury-buffer-function #'magit-restore-window-configuration
        magit-log-arguments '("-n64" "--graph" "--decorate")))

;; lazygit does not belong inside Emacs.  term.el is a weak terminal emulator and
;; makes a mess of full-screen TUIs: broken panel borders, and box-drawing
;; characters printed as raw octal escapes.  eat or vterm would render it
;; properly, but a real terminal renders it best, so this hands it to tmux and
;; leaves Emacs out of the terminal-emulator business.
(defun bk-git-lazygit ()
  "Open lazygit in a new tmux window, in this project's root."
  (interactive)
  (unless (executable-find "lazygit")
    (user-error "lazygit is not installed"))
  (unless (getenv "TMUX")
    (user-error "Not inside tmux; run lazygit in a terminal instead"))
  (let ((root (or (when-let* ((p (project-current nil))) (project-root p))
                  default-directory)))
    (call-process "tmux" nil nil nil
                  "new-window" "-c" (expand-file-name root) "lazygit")))

;; git-blame.nvim's GitBlameOpenCommitURL opened the commit in a browser.  VC has
;; no forge support, so this asks git for the remote and builds the URL, which
;; keeps it to the two forges in use rather than pulling in browse-at-remote.
(defun bk-git-browse-commit ()
  "Open the commit that last touched the current line in a browser."
  (interactive)
  (unless buffer-file-name
    (user-error "No file to blame"))
  (let* ((line (line-number-at-pos))
         (sha (string-trim
               (shell-command-to-string
                (format "git blame -L %d,%d --porcelain -- %s 2>/dev/null | head -1 | cut -d' ' -f1"
                        line line (shell-quote-argument buffer-file-name)))))
         (remote (string-trim
                  (shell-command-to-string "git remote get-url origin 2>/dev/null"))))
    (cond
     ((or (string-empty-p sha) (string-match-p "\\`0+\\'" sha))
      (message "Line is not committed yet"))
     ((string-empty-p remote)
      (message "No origin remote"))
     (t
      (let ((base (thread-last remote
                               (replace-regexp-in-string "\\`git@\\([^:]+\\):" "https://\\1/")
                               (replace-regexp-in-string "\\.git\\'" ""))))
        (browse-url (format "%s/commit/%s" base sha)))))))

(provide 'bk-git)
;;; bk-git.el ends here
