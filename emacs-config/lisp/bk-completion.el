;;; bk-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;; From lua/plugins/completion.lua and telescope.lua.  nvim-cmp becomes
;; completion-at-point, and telescope becomes the minibuffer with
;; fido-vertical-mode.  Both are built in, so nothing here is a package.

;;; Code:

;; The telescope replacement.  fido-vertical-mode is icomplete with flex
;; matching and a vertical list, which is close enough to a fuzzy picker that
;; vertico and consult are not needed to start with.
(fido-vertical-mode 1)
(setq icomplete-compute-delay 0
      icomplete-show-matches-on-no-input t)

;; Flex everywhere else too, and let orderless-style space-separated pieces work
;; via the built-in partial-completion style.
(setq completion-styles '(flex partial-completion basic)
      completion-category-overrides '((file (styles partial-completion basic))
                                      (eglot (styles flex basic)))
      completion-ignore-case t
      completions-detailed t)

;; In-buffer completion.  The built-ins get close but not to nvim-cmp: TAB opens
;; the *Completions* window at the bottom of the frame, and completion-preview-mode
;; shows a single inline candidate with nothing to move through.  Corfu is the
;; missing piece and nothing else, driving the same completion-at-point functions
;; Eglot and dabbrev already install.
(setq tab-always-indent 'complete
      completion-cycle-threshold nil
      completions-format 'one-column
      completions-max-height 15)

;; Soft require, the way bk-debug.el treats dape.  Corfu arrives with a
;; home-manager rebuild, not with an edit to this file, so between the two this
;; module has to keep loading: a hard `require' of a package that is not in the
;; profile yet aborts init.el and takes every later module with it.
(require 'corfu nil t)

(with-eval-after-load 'corfu
  (setq corfu-auto t               ; open by itself, the way cmp did
        corfu-auto-delay 0.1
        corfu-auto-prefix 2        ; two characters before it says anything
        corfu-cycle t              ; wrap from last candidate to first
        corfu-quit-no-match 'separator
        corfu-preselect 'prompt    ; nothing selected until C-n, so RET is safe
        corfu-count 12)
  (global-corfu-mode 1))

;; completion-preview-mode's ghost text would sit underneath the popup saying a
;; slightly different thing, so corfu replaces it where it is installed.  Where
;; it is not, the inline preview is still better than nothing.
(unless (featurep 'corfu)
  (when (fboundp 'completion-preview-mode)
    (add-hook 'prog-mode-hook #'completion-preview-mode)))

;; Vim's C-n and C-p complete in insert mode, and Evil binds them to
;; `evil-complete-next', a dabbrev expansion with no menu -- which is why the
;; keys appeared to do nothing at all.
;;
;; Corfu's own keymap remaps `next-line' and `previous-line', so it would pick
;; C-n and C-p up on its own if they reached the global binding.  They do not:
;; Evil's state keymaps live in `emulation-mode-map-alists', which is consulted
;; before `minor-mode-overriding-map-alist' where corfu installs `corfu-map'.
;; Evil wins, so the keys have to be taken here.
(defun bk-completion--corfu-active-p ()
  "Return non-nil when the corfu popup is up."
  (and (bound-and-true-p completion-in-region-mode)
       (bound-and-true-p corfu--candidates)))

(defun bk-completion-next ()
  "Move to the next candidate, opening the popup if it is not up yet."
  (interactive)
  (if (bk-completion--corfu-active-p)
      (corfu-next)
    (completion-at-point)))

(defun bk-completion-previous ()
  "Move to the previous candidate, opening the popup if it is not up yet."
  (interactive)
  (if (bk-completion--corfu-active-p)
      (corfu-previous)
    (completion-at-point)))

(with-eval-after-load 'evil
  (evil-define-key 'insert 'global
    (kbd "C-n") #'bk-completion-next
    (kbd "C-p") #'bk-completion-previous))

;; cmp's source list was path, LSP, snippets, buffer.  Eglot installs itself as a
;; capf, `dabbrev' covers buffer words, and file names complete on their own.
(setq dabbrev-case-fold-search nil
      dabbrev-check-all-buffers t)

;; LuaSnip's replacement is `abbrev' plus tempo, both built in.  Neither is set
;; up here: LSP servers supply snippets through Eglot, and nothing in the Neovim
;; config defined snippets of its own.

;; telescope.lua's file_ignore_patterns
(setq completion-ignored-extensions
      (append completion-ignored-extensions
              '(".mypy_cache/" "__pycache__/" ".ipynb" ".direnv/")))

;; project.el is the thing telescope's find_files leaned on.  Mark a directory as
;; a project root if it has any of these, not just a VCS directory.
(setq project-vc-extra-root-markers '(".project" "flake.nix" "cabal.project" "*.cabal" "pyproject.toml"))

(provide 'bk-completion)
;;; bk-completion.el ends here
