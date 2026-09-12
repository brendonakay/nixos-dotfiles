;;; bk-options.el --- Editor settings -*- lexical-binding: t; -*-

;; From lua/vim/options.lua by way of ../vim-config/config/options.vim.  Where a
;; Vim option has no Emacs counterpart it is called out in a comment rather than
;; left silently missing.

;;; Code:

(require 'seq)

;; Put the startup threshold back, from early-init.el.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1)))

;; State files, all under bk-cache-directory rather than the config directory.
(setq auto-save-list-file-prefix (expand-file-name "auto-save/" bk-cache-directory)
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" bk-cache-directory) t))
      backup-directory-alist `((".*" . ,(expand-file-name "backup/" bk-cache-directory)))
      custom-file (expand-file-name "custom.el" bk-cache-directory)
      recentf-save-file (expand-file-name "recentf" bk-cache-directory)
      savehist-file (expand-file-name "history" bk-cache-directory)
      save-place-file (expand-file-name "places" bk-cache-directory)
      transient-history-file (expand-file-name "transient-history" bk-cache-directory)
      project-list-file (expand-file-name "projects" bk-cache-directory))

;; 'noswapfile'.  Emacs equivalents are the lock files and the backup copies.
(setq create-lockfiles nil)

;; 'undofile' has no equivalent: Emacs undo is per-session and is not persisted
;; to disk by any built-in.  Undo is a tree here rather than a line, so
;; undo-redo covers the common case that undotree was for.

;; 'updatetime'
(setq idle-update-delay 0.1
      eldoc-idle-delay 0.1)

;; 'relativenumber' and 'number'
(setq display-line-numbers-type 'relative)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

;; 'scrolloff', and scrolling that moves a line at a time rather than half a page
(setq scroll-margin 8
      scroll-conservatively 101
      scroll-preserve-screen-position t
      auto-window-vscroll nil)

;; 'cursorline'.  'cursorcolumn' has no built-in equivalent and is not ported.
(add-hook 'prog-mode-hook #'hl-line-mode)
(add-hook 'text-mode-hook #'hl-line-mode)

;; 'ignorecase' and 'smartcase'.  Evil applies the smartcase half for its own
;; searches, see bk-evil.el.
(setq case-fold-search t
      read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t)

;; 'splitbelow' and 'splitright'
(setq split-height-threshold nil
      split-width-threshold 160)

;; 'nowrap'
(setq-default truncate-lines t)

;; 'tabstop', 'shiftwidth', 'expandtab', 'autoindent'
(setq-default tab-width 4
              indent-tabs-mode nil)
(electric-indent-mode 1)

;; 'textwidth'
(setq-default fill-column 80)

;; 'modeline'.  File-local variables are always honoured in Emacs; this only
;; stops it asking about the risky ones every time.
(setq enable-local-variables t)

;; 'mouse=a', for terminal frames.  GUI frames have the mouse already.
(unless (display-graphic-p)
  (xterm-mouse-mode 1))

;; Vim's 'autoread'
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)

;; Emacs defaults worth changing, none of which have a Vim counterpart because
;; Vim already behaves this way.
(setq use-short-answers t                     ; y/n rather than yes/no
      require-final-newline t
      sentence-end-double-space nil
      ring-bell-function #'ignore
      what-cursor-show-names t
      confirm-kill-emacs nil
      vc-follow-symlinks t                    ; the whole config is symlinks
      native-comp-async-report-warnings-errors 'silent
      uniquify-buffer-name-style 'forward)

;; Native compilation output belongs in the cache too.
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" bk-cache-directory)))

;; Session state.  Vim did this with 'viminfo' and 'undofile'.
(savehist-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 200)
(winner-mode 1)                               ; undo a window layout change
(delete-selection-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-context-when-offscreen 'overlay)

;; which-key is built in as of Emacs 30.  This is the thing which-key.nvim did
;; that vim-which-key could not: it opens by itself after a delay.
(setq which-key-idle-delay 0.3)               ; matches Vim's 'timeoutlen' of 300
(which-key-mode 1)

;; repeat-mode covers what vim-repeat did for plugin operators.
(repeat-mode 1)

;; editorconfig-mode is built in as of Emacs 30, and covers vim-sleuth's job
;; wherever a project has an .editorconfig.
(when (fboundp 'editorconfig-mode)
  (editorconfig-mode 1))

;; Tree-sitter.  Emacs 30 needs grammars installed out of band, so the ts modes
;; are only used where a grammar is actually present.  Emacs 31 can fetch them.
(setq treesit-font-lock-level 4)

;; typescript-ts-mode and tsx-ts-mode do register .ts and .tsx themselves, but
;; from a top-level form guarded by `treesit-ready-p', not from an autoload --
;; so the registration only happens once something loads the file, and nothing
;; does.  Left alone, .ts and .tsx open in fundamental-mode with the grammars
;; sitting right there.  Requiring it lets Emacs's own guard make the call.
(when (treesit-language-available-p 'typescript)
  (require 'typescript-ts-mode nil t))

;; .js and .json already have non-tree-sitter modes and will keep using them
;; unless told otherwise.  `major-mode-remap-alist' is the supported way to say
;; so, and it leaves the old mode in place if a grammar ever goes missing.
;; javascript-mode is an alias for js-mode and is the symbol auto-mode-alist
;; actually carries, so both spellings need an entry.
(defun bk-ts-imenu-name (node)
  "Return NODE's name, read from its name field.
`js--treesit-defun-name', which typescript-ts-mode uses, only knows
lexical_declaration, function_declaration, method_definition and
class_declaration.  Anything else gets no name and is dropped from the
index, which is why interfaces, type aliases and enums never appeared."
  (when-let* ((name (treesit-node-child-by-field-name node "name")))
    (treesit-node-text name t)))

(defun bk-ts-imenu-settings ()
  "Index TypeScript type definitions, which the built-in settings omit.
typescript-ts-mode indexes only Function, Variable and Class.  In
TypeScript the types are the abstractions worth seeing, so they go in
too.  Added as advice rather than from a mode hook on purpose: callers
that set the major mode under `delay-mode-hooks' -- bk-review does, to
avoid starting Eglot in a temporary buffer -- never run the hooks, but
they do run the mode function, and advice with it."
  (dolist (entry `(("Interface" "\\`interface_declaration\\'" nil bk-ts-imenu-name)
                   ("Type" "\\`type_alias_declaration\\'" nil bk-ts-imenu-name)
                   ("Enum" "\\`enum_declaration\\'" nil bk-ts-imenu-name)))
    (unless (assoc (car entry) treesit-simple-imenu-settings)
      (setq-local treesit-simple-imenu-settings
                  (append treesit-simple-imenu-settings (list entry))))))

;; typescript-ts-mode and tsx-ts-mode both derive from this one, so advising it
;; covers both.
(with-eval-after-load 'typescript-ts-mode
  (advice-add 'typescript-ts-base-mode :after #'bk-ts-imenu-settings))

(dolist (pair '((javascript-mode . js-ts-mode)
                (js-mode . js-ts-mode)
                (js-json-mode . json-ts-mode)))
  (when (treesit-language-available-p
         (if (eq (cdr pair) 'json-ts-mode) 'json 'javascript))
    (add-to-list 'major-mode-remap-alist pair)))

;; Spell checking for prose, from the markdown ftplugin.  flyspell shells out to
;; aspell, which ../emacs/default.nix installs.
(setq ispell-program-name (or (executable-find "aspell") "aspell")
      ispell-dictionary "en_US"
      ispell-extra-args '("--sug-mode=ultra"))
(dolist (hook '(markdown-mode-hook markdown-ts-mode-hook text-mode-hook))
  (add-hook hook #'flyspell-mode))
(add-hook 'markdown-mode-hook (lambda () (setq-local fill-column 80)))

(provide 'bk-options)
;;; bk-options.el ends here
