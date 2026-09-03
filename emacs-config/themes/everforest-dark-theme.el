;;; everforest-dark-theme.el --- Everforest hard dark -*- lexical-binding: t; -*-
;;; Code:
(require 'everforest-palette)

(deftheme everforest-dark "Everforest, hard dark variant.")

(apply #'custom-theme-set-faces 'everforest-dark
       (everforest-face-specs everforest-palette-dark))

(custom-theme-set-variables
 'everforest-dark
 `(ansi-color-names-vector
   [,(alist-get 'bg1 everforest-palette-dark)
    ,(alist-get 'red everforest-palette-dark)
    ,(alist-get 'green everforest-palette-dark)
    ,(alist-get 'yellow everforest-palette-dark)
    ,(alist-get 'blue everforest-palette-dark)
    ,(alist-get 'purple everforest-palette-dark)
    ,(alist-get 'aqua everforest-palette-dark)
    ,(alist-get 'fg everforest-palette-dark)]))

(provide-theme 'everforest-dark)
;;; everforest-dark-theme.el ends here
