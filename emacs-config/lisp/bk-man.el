;;; bk-man.el --- Man pages -*- lexical-binding: t; -*-

;; Neovim ships a man plugin and sets `keywordprg' to `:Man', so K on a word
;; opened its man page in a split wherever no LSP hover took the key first.
;; Neither lua/vim/options.lua nor ../vim-config ever set `keywordprg', so that
;; came for free and there is nothing to port; this file is what gets it back.
;;
;; Evil binds K in `evil-motion-state-map' to `evil-lookup', and
;; `evil-lookup-func' defaults to `woman' -- a pure-elisp roff renderer that
;; walks the manpath itself.  man.el runs the real man(1) instead, which means
;; man_db.conf, MANSECT and .so includes are all handled by the thing that owns
;; them, and groff does the rendering rather than an approximation of it.

;;; Code:

(require 'man)

;; man-db's SECTION order in man_db.conf is "1 n l 8 3 0 2 5 4 9 6 7": section 3
;; is searched before 2, and the POSIX pages in man3p match on the 3.  So `man
;; socket' lands on socket(3p), the POSIX Programmer's Manual, when what C on
;; Linux wants is socket(2), the system call -- different text, and only the
;; section 2 page documents Linux-only flags like SOCK_CLOEXEC.  Section 2 goes
;; first here, then 3 for the library functions, then the rest of the default
;; order.
;;
;; This is `Man-switches' rather than a `setenv' of MANSECT so it stays inside
;; man.el.  MANSECT in `process-environment' would follow every subprocess Emacs
;; starts, including the shell under `M-x shell', where `man kill' silently
;; becoming kill(2) instead of kill(1) is a surprise.
(setq Man-switches "-S 2:3:1:8:n:l:0:5:4:9:6:7")

;; An explicit section still wins over the list above, so `C-u K' then "3p
;; socket" or "socket(3p)" reaches the POSIX page.

;; Vim's K jumped straight to the page and put the cursor in it.  `friendly'
;; displays the buffer without selecting it, so this uses `aggressive'.
(setq Man-notify-method 'aggressive)

;; nil means fill to the window; `Man-width-max' keeps that at 80 columns in a
;; wide window, which is what the pages are written for.
(setq Man-width nil
      Man-width-max 80)

(defun bk-man (&optional prompt)
  "Show the man page for the word at point.
Prompt when there is no word there, or when PROMPT is non-nil, which is
the prefix argument interactively.  The prompt takes a section the way
man(1) and man.el do: \"3 printf\" or \"printf(3)\"."
  (interactive "P")
  (let ((topic (and (not prompt) (Man-default-man-entry))))
    (if (and topic (not (string-empty-p topic)))
        (man topic)
      (call-interactively #'man))))

;; K outside an Eglot buffer.  bk-keys.el binds K locally to `bk-lsp-hover'
;; wherever a language server attached, so between the two K means the same
;; thing it meant in Neovim: ask the server if there is one, otherwise man.
(setq evil-lookup-func #'bk-man)

(provide 'bk-man)
;;; bk-man.el ends here
