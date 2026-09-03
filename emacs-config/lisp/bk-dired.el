;;; bk-dired.el --- Dired -*- lexical-binding: t; -*-

;; The file browser.  This is the one place where moving to Emacs is a straight
;; upgrade rather than a port: Dired does what netrw does, and wdired does what
;; oil.nvim did.  `C-x C-q' in a Dired buffer makes the listing editable, so you
;; rename by editing text and delete by killing lines, then `C-c C-c' to apply.
;; That was the feature lost when oil.nvim became netrw.

;;; Code:

(require 'dired)

(setq dired-listing-switches "-alh --group-directories-first"
      dired-dwim-target t                 ; guess the other window as the copy target
      dired-recursive-copies 'always
      dired-recursive-deletes 'top
      dired-auto-revert-buffer t
      dired-kill-when-opening-new-dired-buffer t
      dired-free-space nil
      delete-by-moving-to-trash t)

;; macOS ls does not understand --group-directories-first.  GNU ls arrives as
;; gls with coreutils, which ../emacs/default.nix installs.
(when-let* ((gls (executable-find "gls")))
  (setq insert-directory-program gls))

;; wdired should let you rename symlink targets too, not just names.
(setq wdired-allow-to-change-permissions t
      wdired-allow-to-redirect-links t)

(provide 'bk-dired)
;;; bk-dired.el ends here
