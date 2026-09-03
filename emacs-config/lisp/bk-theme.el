;;; bk-theme.el --- Everforest, following the system appearance -*- lexical-binding: t; -*-

;; From lua/plugins/auto-dark-mode.lua and colorschemes.lua.  The palette and the
;; two themes are hand written in this repo, see lisp/everforest-palette.el and
;; themes/, because nixpkgs has no Emacs everforest package.
;;
;; The Vim configs poll `defaults read -g AppleInterfaceStyle' on a timer, since
;; Vim has no hook for the system theme.  A GUI Emacs on macOS does have one, so
;; this uses the hook when it exists and falls back to polling in a terminal.

;;; Code:

(defconst bk-theme-dark 'everforest-dark)
(defconst bk-theme-light 'everforest-light)

(defun bk-theme--system-appearance ()
  "Return `dark' or `light' for the current macOS appearance."
  (cond
   ;; GUI frames on the NS build get told directly.
   ((boundp 'ns-system-appearance)
    (if (eq ns-system-appearance 'dark) 'dark 'light))
   ((not (executable-find "defaults")) 'dark)
   ;; AppleInterfaceStyle only exists while dark mode is on.
   ((string-match-p
     "dark"
     (downcase (or (ignore-errors
                     (with-output-to-string
                       (call-process "defaults" nil standard-output nil
                                     "read" "-g" "AppleInterfaceStyle")))
                   "")))
    'dark)
   (t 'light)))

(defun bk-theme-apply (&optional appearance)
  "Load the theme matching APPEARANCE, defaulting to the system setting."
  (let* ((appearance (or appearance (bk-theme--system-appearance)))
         (theme (if (eq appearance 'dark) bk-theme-dark bk-theme-light)))
    (unless (custom-theme-enabled-p theme)
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t))))

;; Themes in this repo are not signed, and asking about it on every start is
;; noise.
(setq custom-safe-themes t)

(bk-theme-apply)

(if (boundp 'ns-system-appearance-change-functions)
    (add-hook 'ns-system-appearance-change-functions #'bk-theme-apply)
  ;; Terminal frames have no hook, so poll on the same 30 second interval the
  ;; Vim config uses.
  (run-with-timer 30 30 #'bk-theme-apply))

(provide 'bk-theme)
;;; bk-theme.el ends here
