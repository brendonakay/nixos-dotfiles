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

;; lazygit.nvim ran lazygit in a floating window.  Emacs has no floating windows
;; and its `term' is a reasonable TUI host, so this gives lazygit a full frame
;; and restores the layout on exit.
(defun bk-git-lazygit ()
  "Run lazygit in a terminal buffer covering the frame."
  (interactive)
  (if (not (executable-find "lazygit"))
      (user-error "lazygit is not installed")
    (let ((default-directory (or (when-let* ((p (project-current nil)))
                                   (project-root p))
                                 default-directory)))
      (window-configuration-to-register ?l)
      (delete-other-windows)
      (term "lazygit")
      (rename-buffer "*lazygit*" t))))

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
