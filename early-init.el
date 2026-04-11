;;; early-init.el --- Emacs 27+ pre-initialisation -*- lexical-binding: t; -*-
;;; Commentary:
;; Performance optimizations loaded before init.el and package.el.
;;; Code:

(setq package-enable-at-startup nil)

;; ---- native-comp: defer JIT to after startup (Windows pipe limit) ----
(setq native-comp-jit-compilation nil)
(setq native-comp-async-jobs-number 1)
(setq inhibit-automatic-native-compilation t)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq inhibit-automatic-native-compilation nil)
            (setq native-comp-jit-compilation t)
            (setq native-comp-async-jobs-number 2)))

;; ---- Suppress GUI work during init ----
(setq frame-inhibit-implied-resize t)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; ---- GC pause during init ----
(setq gc-cons-threshold (* 128 1024 1024))
(setq gc-cons-percentage 0.6)

;; ---- Suppress file-handler matching during init ----
(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist my/file-name-handler-alist)))

(provide 'early-init)
;;; early-init.el ends here
