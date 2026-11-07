;;; init.el --- starter configuration  -*- lexical-binding: t -*-
;;
;; Layout:
;;   ~/.config/emacs/early-init.el  frame/GC settings applied before this file
;;   ~/.config/emacs/init.el        this file
;;   ~/.config/emacs/custom.el      written by M-x customize (kept out of here)
;;   ~/.cache/emacs/                backups, auto-saves, and other runtime files
;;
;; Everything in "Built-in" works offline. The "Packages" section pulls a few
;; things from MELPA on first launch (needs network, takes a minute).

;;;; Packages: sources and use-package ---------------------------------------

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t)   ; install a package if it's missing

;;;; Files and runtime state -------------------------------------------------

(defvar my/cache-dir (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache")))
(make-directory my/cache-dir t)

;; Keep M-x customize output out of this file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)

;; Backups and auto-saves go to the cache dir instead of next to the file.
(setq backup-directory-alist `(("." . ,(expand-file-name "backups/" my/cache-dir)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" my/cache-dir) t))
      auto-save-list-file-prefix (expand-file-name "auto-save-list/" my/cache-dir)
      create-lockfiles nil
      backup-by-copying t
      delete-old-versions t
      version-control t
      kept-new-versions 5
      kept-old-versions 2)

(setq recentf-save-file (expand-file-name "recentf" my/cache-dir)
      savehist-file (expand-file-name "history" my/cache-dir)
      save-place-file (expand-file-name "places" my/cache-dir)
      bookmark-default-file (expand-file-name "bookmarks" my/cache-dir)
      transient-history-file (expand-file-name "transient-history" my/cache-dir)
      eshell-directory-name (expand-file-name "eshell/" my/cache-dir)
      url-configuration-directory (expand-file-name "url/" my/cache-dir))

;;;; Built-in: look and feel -------------------------------------------------

;; Same font as the terminal (Omarchy ships JetBrainsMono Nerd Font).
(set-face-attribute 'default nil :family "JetBrainsMono Nerd Font" :height 110)

;; Dark theme that matches Omarchy's Tokyo Night mood. Built-in, no download.
;; Light alternative: (load-theme 'modus-operandi-tinted t)
(load-theme 'modus-vivendi-tinted t)

(setq-default cursor-type 'bar)
(blink-cursor-mode 0)
(column-number-mode 1)
(global-display-line-numbers-mode 0)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'conf-mode-hook #'display-line-numbers-mode)
(setq display-line-numbers-width 3)
(show-paren-mode 1)
(global-hl-line-mode 1)
(setq ring-bell-function 'ignore)
(setq use-short-answers t)            ; y/n instead of yes/no
(setq frame-title-format '("%b – Emacs"))

;;;; Built-in: editing defaults ---------------------------------------------

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80
              require-final-newline t)
(delete-selection-mode 1)             ; typing replaces the active region
(electric-pair-mode 1)                ; auto-close () [] {} ""
(global-auto-revert-mode 1)           ; reload files changed on disk (git checkout, etc.)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)
(save-place-mode 1)                   ; reopen a file at the last cursor position
(savehist-mode 1)                     ; keep minibuffer history across sessions
(recentf-mode 1)
(setq recentf-max-saved-items 200)
(setq sentence-end-double-space nil)
(setq scroll-conservatively 101        ; no jumpy recentering when moving off-screen
      scroll-margin 2)
(setq mouse-wheel-progressive-speed nil)
(pixel-scroll-precision-mode 1)       ; smooth touchpad scrolling on PGTK

;; Wayland clipboard is handled natively by the PGTK build. This makes
;; mouse-selected text also land in the clipboard, like a terminal does.
(setq select-enable-primary t)

;; Show trailing whitespace in code, and strip it on save.
(add-hook 'prog-mode-hook (lambda () (setq show-trailing-whitespace t)))
(add-hook 'before-save-hook #'delete-trailing-whitespace)

;; Discover keybindings: pause after a prefix (e.g. C-x) and a popup lists the rest.
(which-key-mode 1)

;;;; Built-in: keys -----------------------------------------------------------

;; C-z is your tmux prefix. In a GUI frame Emacs binds it to "suspend/iconify",
;; which is only a nuisance, so free it up (inside tmux it never reaches Emacs anyway).
(global-unset-key (kbd "C-z"))
(global-unset-key (kbd "C-x C-z"))

(global-set-key (kbd "C-c r") #'recentf-open)
(global-set-key (kbd "M-o") #'other-window)
(global-set-key (kbd "C-x k") #'kill-current-buffer)   ; no "which buffer?" prompt
(global-set-key (kbd "C-+") #'text-scale-increase)
(global-set-key (kbd "C--") #'text-scale-decrease)
(global-set-key (kbd "C-0") (lambda () (interactive) (text-scale-set 0)))

;;;; Built-in: programming ---------------------------------------------------

;; Tree-sitter major modes (Emacs 29+). `M-x treesit-install-language-grammar`
;; fetches a grammar the first time you open a file of that language.
(setq treesit-language-source-alist
      '((javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (json       "https://github.com/tree-sitter/tree-sitter-json")
        (python     "https://github.com/tree-sitter/tree-sitter-python")
        (bash       "https://github.com/tree-sitter/tree-sitter-bash")
        (lua        "https://github.com/tree-sitter-grammars/tree-sitter-lua")
        (toml       "https://github.com/tree-sitter-grammars/tree-sitter-toml")
        (yaml       "https://github.com/tree-sitter-grammars/tree-sitter-yaml")))

;; Use the ts modes when the grammar is installed, fall back to the classic ones.
(dolist (pair '((js-mode . js-ts-mode) (typescript-mode . typescript-ts-mode)
                (json-mode . json-ts-mode) (python-mode . python-ts-mode)
                (sh-mode . bash-ts-mode)))
  (when (treesit-language-available-p (intern (string-remove-suffix "-ts-mode" (symbol-name (cdr pair)))))
    (add-to-list 'major-mode-remap-alist pair)))

;; Eglot (built-in LSP client). Turn it on per buffer with M-x eglot, or
;; uncomment a hook to start it automatically when a server is installed.
;; (add-hook 'js-base-mode-hook #'eglot-ensure)
;; (add-hook 'typescript-ts-base-mode-hook #'eglot-ensure)
(setq eglot-autoshutdown t)

;; Flymake shows errors in the fringe; these keys jump between them.
(with-eval-after-load 'flymake
  (define-key flymake-mode-map (kbd "M-n") #'flymake-goto-next-error)
  (define-key flymake-mode-map (kbd "M-p") #'flymake-goto-prev-error))

;; Projects: C-x p f finds a file in the current git repo, C-x p g greps it.
(setq project-list-file (expand-file-name "projects" my/cache-dir))

;; Dired
(setq dired-listing-switches "-alh --group-directories-first"
      dired-dwim-target t                 ; copy/move to the other dired window
      dired-kill-when-opening-new-dired-buffer t)

;;;; Packages (MELPA) --------------------------------------------------------

;; Vertical minibuffer completion: C-x C-f, M-x, C-x b become fuzzy pickers.
(use-package vertico
  :init (vertico-mode 1)
  :custom (vertico-cycle t))

;; Match on space-separated words in any order ("init el" finds init.el).
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Annotations next to candidates (docstrings, file sizes, ...).
(use-package marginalia
  :init (marginalia-mode 1))

;; Git. C-x g opens the status buffer.
(use-package magit
  :bind ("C-x g" . magit-status))

;; Terminal emulator. M-x vterm. The first run compiles a small C module;
;; cmake and gcc are already on this machine via base-devel.
;; (use-package vterm)

;;;; Wrap up ------------------------------------------------------------------

;; Restore a normal GC threshold now that startup is over.
(setq gc-cons-threshold (* 16 1024 1024))

;;; init.el ends here
