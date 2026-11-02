;;; bk-cheatsheet.el --- A printed list of keys worth remembering -*- lexical-binding: t; -*-

;; A scratch pad for learning Emacs: the keys that have not stuck yet, printed
;; in a help window.  Nothing here is clever.  `with-help-window' does the work,
;; which means the buffer arrives in a split, in `help-mode', where q buries it
;; and TAB moves between any links -- the same window every other help buffer
;; gets, because it is the same machinery.
;;
;; Edit `bk-cheatsheet-sections' freely.  It is the point of the file: a list
;; that grows as things are learned and shrinks as they become muscle memory.

;;; Code:

(defvar bk-cheatsheet-sections
  '(("Ask Emacs about itself"
     ("C-h k KEY"  "what does this key do, and where is it defined")
     ("C-h f FN"   "describe a function")
     ("C-h v VAR"  "describe a variable")
     ("C-h o SYM"  "describe whatever is at point")
     ("C-h m"      "every binding live in this buffer")
     ("C-h i"      "Info: the manuals, offline")
     ("M-."        "jump to the source of an elisp symbol, C included")
     ("M-x"        "run a command by name")
     ("C-g"        "get out of whatever this is"))

    ("Buffers, windows, files"
     ("SPC SPC"    "find file in project")
     ("SPC sb"     "switch buffer")
     ("SPC sg"     "grep the project")
     ("SPC b"      "occur: search this buffer")
     ("SPC fr"     "recent files")
     ("SPC w"      "window prefix: s split, v vsplit, c close, hjkl move")
     ("SPC RET"    "zoom this window, and back")
     ("C-x C-s"    "save")
     ("C-x b"      "switch buffer, the Emacs way"))

    ("Dired: getting there"
     ("C-x C-j"    "Dired on this file's directory, point on the file")
     ("C-x d"      "Dired, asking which directory")
     ("C-x 4 d"    "same, in the other window")
     ("C-x C-f"    "find-file; hand it a directory and you land in Dired"))

    ("Dired: inside"
     ("RET"        "open the file or directory")
     ("-  or  ^"   "up a directory")
     ("m / u"      "mark, unmark")
     ("D / R / C"  "delete, rename, copy the marked files")
     ("+"          "make a directory")
     ("S"          "symlink")
     ("g r"        "refresh the listing")
     ("g j / g k"  "next, previous directory line")
     ("g o"        "view the file without leaving Dired")
     ("g ?"        "summary of what Dired offers here")
     ("C-x C-q"    "edit the listing as text; C-c C-c applies it"))

    ("Code"
     ("gd / gr"    "definition, references")
     ("gi"         "implementation")
     ("K"          "documentation at point")
     ("cr / ca"    "rename, code actions")
     ("cl"         "quickfix actions: imports and the like")
     ("[d / ]d"    "previous, next diagnostic")
     ("SPC d"      "diagnostics in this buffer")
     ("SPC ql"     "diagnostics across the project")
     ("gc / gcc"   "comment an object, comment a line")
     ("SPC t"      "TODO and FIXME across the project"))

    ("Review what changed"
     ("SPC cr"     "everything since the base ref")
     ("C-u SPC cr" "same, but ask which ref")
     ("RET"        "open the file at its first change, diff inline")
     ("]c / [c"    "next, previous change in that file")
     ("SPC cd"     "toggle the inline diff in any file")
     ("d"          "diff for this file")
     ("TAB"        "definitions this change touched")
     ("s"          "newest first, or by path")
     ("u"          "whole branch, or uncommitted only")
     ("r / q"      "refresh, quit"))

    ("Git"
     ("SPC lg"     "Magit")
     ("SPC gb"     "blame this file")
     ("SPC gm"     "history of this file")
     ("SPC gB"     "open this line's commit in a browser")
     ("SPC gt"     "lazygit, in a tmux window")
     ("in Magit"   "? lists everything; s stage, c c commit, P p push"))

    ("Completion"
     ("C-n / C-p"  "next, previous candidate")
     ("TAB"        "indent, or complete if already indented")
     ("C-h"        "describe the candidate under point"))

    ("Emacs ideas Vim does not have"
     ("mark"       "C-SPC sets it; C-u C-SPC jumps back to where you were")
     ("kill ring"  "M-y cycles through earlier kills after a paste")
     ("prefix arg" "C-u N before a command repeats or modifies it")
     ("universal"  "C-x C-e evaluates the expression before point"))

    ("This config"
     ("SPC cs"     "this cheat sheet")
     ("SPC cr"     "review changes since the base ref")
     ("SPC cc"     "compile")
     ("SPC m"      "man page for the word at point")
     ("SPC yf"     "copy this file's path")
     ("SPC u"      "undo-redo; Emacs undo is a tree, not a line")))
  "Sections of the cheat sheet.
Each entry is (TITLE (KEYS DESCRIPTION)...).")

(defun bk-cheatsheet--insert ()
  "Insert the cheat sheet into the current buffer."
  (let ((width (apply #'max 8 (mapcar (lambda (row) (length (car row)))
                                      (apply #'append (mapcar #'cdr bk-cheatsheet-sections))))))
    (dolist (section bk-cheatsheet-sections)
      (insert (propertize (car section) 'face 'bold) "\n")
      (dolist (row (cdr section))
        (insert "  "
                (propertize (string-pad (car row) width) 'face 'help-key-binding)
                "  " (cadr row) "\n"))
      (insert "\n"))
    (insert (propertize "Edit lisp/bk-cheatsheet.el to change this list." 'face 'shadow) "\n")))

;;;###autoload
(defun bk-cheatsheet ()
  "Show the cheat sheet in a help window."
  (interactive)
  (with-help-window "*Cheat Sheet*"
    (with-current-buffer standard-output
      (bk-cheatsheet--insert))))

(provide 'bk-cheatsheet)
;;; bk-cheatsheet.el ends here
