;;; early-init.el --- Runs before the package system and the first frame -*- lexical-binding: t; -*-

;; Nix puts every package on the load path, but it does not load their
;; autoloads: the site-start.el nixpkgs generates only extends `load-path'.
;; package.el's startup activation is what reads each package's autoloads file,
;; and without it a .nix file opens in fundamental-mode because nothing ever
;; registered nix-mode in `auto-mode-alist'.  So activation stays on.
;;
;; Nothing is ever fetched: Nix owns the package set.  package-user-dir is
;; pointed at the cache so package.el does not create an elpa tree inside the
;; version-controlled config directory.
(setq package-user-dir
      (expand-file-name "emacs/elpa/" (or (getenv "XDG_CACHE_HOME") "~/.cache/")))

;; Startup spends most of its time in garbage collection.  Raise the threshold
;; for init and put it back in bk-options.el once the session is up.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Suppress the flash of default UI before the theme loads.
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil
      frame-inhibit-implied-resize t)

(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;;; early-init.el ends here
