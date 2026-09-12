;;; bk-keys.el --- Leader bindings -*- lexical-binding: t; -*-

;; From lua/vim/keymaps.lua by way of ../vim-config/config/keymaps.vim.  Same
;; leader, same keys, pointed at Emacs commands.
;;
;; which-key is built in and opens by itself after `which-key-idle-delay', so
;; there is no <leader>? binding here: that existed only because vim-which-key
;; needed a key of its own.

;;; Code:

(require 'evil)

;; evil-set-leader binds SPC to a menu-item whose :filter looks up [leader].
;; The earlier config also set the *local* leader to SPC, whose second
;; evil-global-set-key overwrote SPC to look up [localleader] instead -- and
;; since nothing binds <localleader>, SPC resolved to nil and every leader key
;; silently did nothing. No <localleader> bindings exist, so just set the one
;; leader. A local leader, if ever wanted, must use a key that does not start
;; with SPC (binding "SPC x" would turn SPC into a prefix and break this again).
(evil-set-leader nil (kbd "SPC"))

;; NeoZoom.lua's toggle.  winner-mode remembers the layout, so this is just
;; delete-other-windows plus an undo.
(defvar bk-keys--zoomed nil)
(defun bk-keys-zoom-toggle ()
  "Fill the frame with this window, or put the layout back."
  (interactive)
  (if (and bk-keys--zoomed (= 1 (length (window-list))))
      (progn (winner-undo) (setq bk-keys--zoomed nil))
    (setq bk-keys--zoomed t)
    (delete-other-windows)))

;; Copy file path to system clipboard for sharing.
(defun bk-keys-yank-file-path ()
  "Copy the path of this file, relative to the project, to the clipboard."
  (interactive)
  (let* ((root (when-let* ((p (project-current nil))) (project-root p)))
         (path (cond
                ((and buffer-file-name root) (file-relative-name buffer-file-name root))
                (buffer-file-name (abbreviate-file-name buffer-file-name))
                (t (user-error "Buffer has no file")))))
    (kill-new path)
    (message "Copied %s to clipboard" path)))

(defmacro bk-keys-define (&rest bindings)
  "Bind normal-state leader keys from BINDINGS, a list of KEY COMMAND pairs."
  `(progn
     ,@(mapcar (lambda (pair)
                 `(evil-define-key 'normal 'global
                    (kbd ,(concat "<leader>" (car pair))) ,(cadr pair)))
               (seq-partition bindings 2))))

(bk-keys-define
 ;; Windows.  Evil already owns C-w; this makes <leader>w the same prefix.
 "w"   evil-window-map

 ;; Vim's quickfix has no single Emacs counterpart: results live in compilation,
 ;; grep, xref and flymake buffers.  <leader>cc from keymaps.lua is gone: Emacs
 ;; keymaps reject a binding that is also the prefix of another, where Vim just
 ;; waits out 'timeoutlen'.  q closes a results window, via evil-collection.
 ;; c is a prefix now, so compile moved under it.  Emacs keymaps reject a
 ;; binding that is also the prefix of another one, where Vim would just wait
 ;; out 'timeoutlen'.
 "cc"  #'compile
 "cs"  #'bk-cheatsheet
 ;; Not <leader>r: bk-keys--eglot binds that to eglot-rename buffer-locally in
 ;; every LSP buffer, and buffer-local wins over global -- so <leader>r would
 ;; have been the review everywhere except the code files it is for.  Grouped
 ;; under c with the cheat sheet instead.
 "cr"  #'bk-review                     ; everything changed since the base ref
 "h"   #'evil-ex-nohighlight

 ;; Files and search.  telescope becomes project.el plus the minibuffer.
 ;; dired-jump was <leader>o; dropped in favour of the built-in C-x C-j.
 "SPC" #'project-find-file              ; find_files
 "sg"  #'project-find-regexp            ; live_grep
 "sb"  #'switch-to-buffer               ; buffers
 "b"   #'occur                          ; current_buffer_fuzzy_find
 "sc"  #'execute-extended-command       ; commands
 "fr"  #'recentf-open                   ; oldfiles
 "u"   #'undo-redo                      ; the undo tree picker; Emacs undo is a tree

 ;; Diagnostics.  flymake replaces both the diagnostics picker and the quickfix
 ;; list of LSP results.
 "d"   #'flymake-show-buffer-diagnostics
 "ql"  #'flymake-show-project-diagnostics

 ;; Git
 "gb"  #'vc-annotate                    ; blame
 "gm"  #'vc-print-log                   ; file history
 "gB"  #'bk-git-browse-commit           ; GitBlameOpenCommitURL
 ;; lazygit.lua's key, now pointed at Magit: same reach, better tool, and it
 ;; renders because it is Emacs buffers rather than a TUI in a terminal.
 "lg"  #'magit-status
 ;; lazygit itself is still one key away, in a tmux window where it looks right.
 "gt"  #'bk-git-lazygit

 ;; Misc.  K already reaches the man page for the word at point, via
 ;; `evil-lookup-func' in bk-man.el; this is the one that prompts, and takes a
 ;; section, for a page whose name is not under the cursor.
 "m"   #'man
 ;; The container equivalents of <leader>c and a terminal, for a project whose
 ;; compiler is not this machine's.  See bk-container.el.
 "Cc"  #'bk-container-compile
 "Cs"  #'bk-container-shell
 "yf"  #'bk-keys-yank-file-path
 "RET" #'bk-keys-zoom-toggle
 "t"   #'bk-todo-list)

;; markdown-preview.nvim has no equivalent: there is no built-in live preview.
;; `M-x eww-open-file' renders a built HTML file, which is as close as it gets.

;; LSP keys from lsp.lua, buffer-local so they only bind where a server attached.
;; Eglot routes gd and gr through xref, which Evil already binds sensibly, so
;; these override only what differs.
(defun bk-keys--eglot ()
  "Bind the LSP keys in an Eglot-managed buffer."
  (evil-define-key 'normal 'local
    "gd" #'xref-find-definitions
    "gr" #'xref-find-references
    "gi" #'eglot-find-implementation
    "K"  #'bk-lsp-hover
    ;; rename/action were cr/ca, but a normal-state binding under c turns c into
    ;; a prefix and shadows the c change operator (cw, ciw, cc) in every LSP
    ;; buffer -- the same Emacs rule that moved <leader>cc/<leader>dd.  Moved to
    ;; the leader.  gd/gr/gi are fine: g is already a prefix, so local additions
    ;; compose with gg, gc and the rest rather than shadowing them.
    (kbd "<leader>r") #'eglot-rename
    (kbd "<leader>a") #'eglot-code-actions
    (kbd "[d") #'flymake-goto-prev-error
    (kbd "]d") #'flymake-goto-next-error)
  ;; lsp.lua bound cl to codelens.  Eglot does not implement codeLens, but the
  ;; HLS features that were lenses are also offered as quickfix code actions:
  ;; "make import lists fully explicit", "refine import", and the import that
  ;; GHC suggests for a name that is not in scope.  Eglot filters kinds by
  ;; prefix, so "quickfix" catches quickfix.literals.style and
  ;; quickfix.import.refine as well, and it sends the Flymake diagnostics at
  ;; point along with the request, which is what the not-in-scope fix needs.
  (evil-define-key 'normal 'local
    (kbd "<leader>x") #'eglot-code-action-quickfix
    (kbd "<leader>o") #'eglot-code-action-organize-imports))

(add-hook 'eglot-managed-mode-hook #'bk-keys--eglot)

;; Some modes bind SPC for themselves: Dired moves to the next line, help and
;; Info page down.  evil-collection keeps those in each mode's auxiliary
;; normal-state map, and an auxiliary map beats the global one, so the leader
;; quietly stops working in exactly those buffers -- the same precedence rule
;; that hid bk-review's RET behind evil-ret.
;;
;; Unbinding SPC there lets the global leader through again.  Nothing is lost
;; that Emacs does not already have another key for: C-v and M-v page, and in
;; Dired j and k move.  Add to this list whenever another mode swallows SPC;
;; C-h k on SPC in that buffer names the culprit.
(with-eval-after-load 'dired
  (evil-define-key '(normal motion visual) dired-mode-map (kbd "SPC") nil))
(with-eval-after-load 'help-mode
  (evil-define-key '(normal motion visual) help-mode-map (kbd "SPC") nil))
(with-eval-after-load 'info
  (evil-define-key '(normal motion visual) Info-mode-map (kbd "SPC") nil))

;; dape, from debugging.lua.  Bound only if dape loaded.
(with-eval-after-load 'dape
  (bk-keys-define
   "Db" #'dape-breakpoint-toggle
   "Dc" #'dape
   "Ds" #'dape-next
   "Dj" #'dape-step-in
   "Dk" #'dape-step-out
   ;; debugging.lua used <leader>dd to end the session, which would collide with
   ;; <leader>d for diagnostics under the same rule as <leader>cc above.  Every
   ;; debugger key lives under D instead.
   "Dq" #'dape-quit))

(provide 'bk-keys)
;;; bk-keys.el ends here
