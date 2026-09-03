;;; bk-debug.el --- Debugging -*- lexical-binding: t; -*-

;; From lua/plugins/debugging.lua.  dape is the nvim-dap replacement, and unlike
;; vimspector it needs nothing outside Emacs: no +python3 build, no 1.4 GiB
;; closure.  That was the reason DAP stayed off in the Vim config.
;;
;; dape has no equivalent of dap-python's pytest integration, so the two test
;; mappings from debugging.lua, <leader>Dm and <leader>DC, are not ported.  It
;; reads configuration from a plist rather than a launch.json.

;;; Code:

(require 'dape nil t)

(with-eval-after-load 'dape
  (setq dape-buffer-window-arrangement 'right
        dape-inlay-hints t
        dape-info-hide-mode-line nil)

  ;; Save without formatting getting in the way, and remember breakpoints.
  (add-hook 'dape-compile-hook #'kill-buffer)
  (dape-breakpoint-global-mode 1)

  ;; debugpy, the adapter dap-python drove.  dape ships a debugpy config; this
  ;; only points it at the module rather than a hardcoded path, the way
  ;; debugging.lua pointed at /etc/profiles/per-user/bkay/bin/debugpy.
  (setq dape-configs-port 'auto))

(provide 'bk-debug)
;;; bk-debug.el ends here
