;;; everforest-light-theme.el --- Everforest hard light -*- lexical-binding: t; -*-
;;; Code:
(require 'everforest-palette)

(deftheme everforest-light "Everforest, hard light variant.")

(apply #'custom-theme-set-faces 'everforest-light
       (everforest-face-specs everforest-palette-light))

(custom-theme-set-variables
 'everforest-light
 `(ansi-color-names-vector
   [,(alist-get 'bg1 everforest-palette-light)
    ,(alist-get 'red everforest-palette-light)
    ,(alist-get 'green everforest-palette-light)
    ,(alist-get 'yellow everforest-palette-light)
    ,(alist-get 'blue everforest-palette-light)
    ,(alist-get 'purple everforest-palette-light)
    ,(alist-get 'aqua everforest-palette-light)
    ,(alist-get 'fg everforest-palette-light)]))

(provide-theme 'everforest-light)
;;; everforest-light-theme.el ends here
