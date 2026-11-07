;;; early-init.el --- runs before the first frame and before package.el  -*- lexical-binding: t -*-

;; Fewer GCs during startup; init.el restores a sane value at the end.
(setq gc-cons-threshold (* 128 1024 1024))

;; Turn off bars here so the first frame never flashes them.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Don't resize the frame when the font or bars change; faster startup.
(setq frame-inhibit-implied-resize t)

;; Skip the splash screen.
(setq inhibit-startup-screen t)

;;; early-init.el ends here
