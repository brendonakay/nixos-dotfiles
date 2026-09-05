;;; bk-todo.el --- Highlight TODO keywords -*- lexical-binding: t; -*-

;; From lua/plugins/todo-comments.lua by way of ../vim-config/config/todo.vim.
;; Emacs highlights the word TODO in comments already, through
;; `font-lock-keyword-face' on some modes, but not the rest of the vocabulary and
;; not consistently.  This adds them as font-lock keywords in every prog-mode
;; buffer, and `bk-todo-list' fills a grep buffer, which is what the Vim :Todo
;; command did with :vimgrep.

;;; Code:

(defface bk-todo-note '((t :inherit font-lock-doc-face :weight bold))
  "Face for NOTE and TEST keywords.")
(defface bk-todo-todo '((t :inherit warning :weight bold))
  "Face for TODO and PERF keywords.")
(defface bk-todo-warn '((t :inherit warning :weight bold))
  "Face for WARN keywords.")
(defface bk-todo-error '((t :inherit error :weight bold))
  "Face for FIXME, BUG and HACK keywords.")

(defconst bk-todo-keywords
  '(("FIXME" . bk-todo-error)
    ("BUG"   . bk-todo-error)
    ("HACK"  . bk-todo-error)
    ("TODO"  . bk-todo-todo)
    ("PERF"  . bk-todo-todo)
    ("WARN"  . bk-todo-warn)
    ("WARNING" . bk-todo-warn)
    ("NOTE"  . bk-todo-note)
    ("TEST"  . bk-todo-note))
  "Keyword to face, matching the groups todo-comments.nvim used.")

(defun bk-todo--font-lock-keywords ()
  "Return font-lock keywords for `bk-todo-keywords'."
  (mapcar (lambda (pair)
            (list (concat "\\<\\(" (car pair) "\\)\\(?::\\)?\\>")
                  1 `',(cdr pair) 'prepend))
          bk-todo-keywords))

(defun bk-todo-mode-enable ()
  "Highlight the keywords in this buffer."
  (font-lock-add-keywords nil (bk-todo--font-lock-keywords) 'append)
  (when font-lock-mode
    (font-lock-flush)))

(add-hook 'prog-mode-hook #'bk-todo-mode-enable)
(add-hook 'conf-mode-hook #'bk-todo-mode-enable)

(defun bk-todo-list ()
  "List every keyword in the project, like the Vim :Todo command."
  (interactive)
  (let ((regexp (concat "\\<\\(" (mapconcat #'car bk-todo-keywords "\\|") "\\)\\>")))
    (if-let* ((project (project-current nil)))
        (project-find-regexp regexp)
      (rgrep regexp "*" default-directory))))

(provide 'bk-todo)
;;; bk-todo.el ends here
