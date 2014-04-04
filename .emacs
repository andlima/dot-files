;(set-face-attribute 'default nil :height 110)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(setq initial-scratch-message "")
;(set-default-font "inconsolata")
;(set-background-color "#000000")
;(set-foreground-color "#dbdbdb")
;(set-cursor-color "#dbdbdb")

(setq line-number-mode t)
(setq column-number-mode t)

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq c-default-style "linux" c-basic-offset 4)

(setq indent-line-function 'insert-tab)

(setq x-select-enable-clipboard t)

;(global-set-key [?\C-x ?\C-g] 'rgrep)

;(custom-set-variables
; '(tab-stop-list (quote (4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120))))

(autoload 'octave-mode "octave-mod" nil t)
(setq auto-mode-alist
      (cons '("\\.m$" . octave-mode) auto-mode-alist))
