;;; sean-config.el --- Sean's personal config on top of Prelude -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Loaded automatically by Prelude from personal/ directory.
;; All .el files in personal/ are loaded alphabetically after modules.
;; This file contains everything from the old purcell init-local.el,
;; adapted for Prelude's conventions.
;;
;;; Code:

;; ============================================================
;;  1. Fonts — Maple Mono NF CN (中英等宽，自带 CJK + Nerd Font)
;; ============================================================

(defun my/first-available-font (candidates)
  "Return the first font family from CANDIDATES that is available."
  (catch 'found
    (dolist (font candidates)
      (when (find-font (font-spec :family font))
        (throw 'found font)))
    nil))

(defun my/setup-fonts (&optional frame)
  "Configure fonts. Works for both normal start and daemon+emacsclient."
  (when frame (select-frame frame))
  (when (display-graphic-p)
    (let ((default-font (my/first-available-font
                         '("Maple Mono NF CN"
                           "Cascadia Code" "SF Mono" "Menlo" "Consolas"))))
      (when default-font
        (set-face-attribute 'default nil :family default-font :height 120)))

    (let ((vp-font (my/first-available-font
                    '("霞鹜文楷" "Microsoft YaHei UI" "Sarasa Gothic SC" "Noto Sans SC" "Segoe UI" "Arial"))))
      (when vp-font
        (set-face-attribute 'variable-pitch nil :family vp-font)))

    (let ((cjk-font (my/first-available-font
                     '("等距更纱黑体 SC" "Sarasa Mono SC"
                       "霞鹜文楷等宽" "LXGW WenKai Mono"
                       "Microsoft YaHei UI" "Microsoft YaHei"
                       "Noto Sans SC"))))
      (when cjk-font
        (dolist (charset '(kana han cjk-misc bopomofo))
          (set-fontset-font t charset (font-spec :family cjk-font) nil 'prepend))
        (setq face-font-rescale-alist
              (list (cons (regexp-quote cjk-font) 1.0)))))

    (let ((emoji-font (my/first-available-font
                       '("Segoe UI Emoji" "Apple Color Emoji" "Noto Color Emoji")))
          (symbol-font (my/first-available-font
                        '("Segoe UI Symbol" "Apple Symbols" "Symbola"))))
      (when emoji-font
        (set-fontset-font t 'emoji (font-spec :family emoji-font) nil 'prepend))
      (when symbol-font
        (set-fontset-font t 'symbol (font-spec :family symbol-font) nil 'prepend)))

    (remove-hook 'after-make-frame-functions #'my/setup-fonts)))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/setup-fonts)
  (my/setup-fonts))

;; ============================================================
;;  2. Theme & General overrides
;; ============================================================

;; Override Prelude's default zenburn theme with modus-operandi
(disable-theme 'zenburn)
(setq prelude-theme 'modus-operandi)
(load-theme 'modus-operandi t)

(defun light ()
  "Switch to modus-operandi (light)."
  (interactive)
  (load-theme 'modus-operandi t))

(defun dark ()
  "Switch to doom-one (dark)."
  (interactive)
  (prelude-require-package 'doom-themes)
  (load-theme 'doom-one t))

(setq system-time-locale "C")
(save-place-mode 1)
(global-visual-line-mode 1)

;; Faster which-key
(setq-default which-key-idle-delay 0.5)

;; ---- which-key prefix descriptions ----
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c G"   "gcal"
    "C-c G s" "gcal-sync"
    "C-c G f" "gcal-fetch"
    "C-c G d" "gcal-delete"
    "C-c G p" "gcal-push"
    "C-c i"   "image/inline"
    "C-c i t" "toggle-inline-images"
    "C-c i p" "paste-clipboard"
    "C-c i s" "screenshot"
    "C-c i y" "yank-image"
    "C-c i d" "delete-image"
    "C-c j"   "journal"
    "C-c j j" "new-entry"
    "C-c j t" "open-today"
    "C-c n"   "notes/roam"
    "C-c n f" "find-node"
    "C-c n i" "insert-node"
    "C-c n l" "roam-buffer"
    "C-c n c" "roam-capture"
    "C-c n d" "dailies-today"
    "C-c n t" "tag-add"
    "C-c n s" "rg-search-org"
    "C-c q"   "quit/restart"
    "C-c q r" "restart-emacs"
    "C-c q q" "save-quit"
    "C-c t"   "treemacs"
    "C-c w"   "web/elfeed"
    "C-c w e" "elfeed"))

;; ============================================================
;;  2b. Stolen-from-the-best — 2026-04 Emacs Redux roundup
;;      https://emacsredux.com/blog/2026/04/07/stealing-from-the-best-emacs-configs/
;; ============================================================

;; --- Performance: bidi scanning (Doom) ---
;; No RTL editing → skip bidirectional reordering on every redisplay.
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; --- Performance: LSP process I/O (Doom, Purcell, Centaur) ---
;; Default 64KB is way too small for modern LSP servers.
(setq read-process-output-max (* 4 1024 1024)) ; 4 MB

;; --- Performance: don't render cursors in unfocused windows (Doom) ---
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

;; --- Kill ring & clipboard ---
;; Save clipboard before kill so C-y gets the kill, M-y gets the old clipboard.
(setq save-interprogram-paste-before-kill t)
;; Don't waste kill-ring slots on identical entries.
(setq kill-do-not-save-duplicates t)

;; Persist kill-ring across sessions (Prelude only saves search-ring by default).
(with-eval-after-load 'savehist
  (unless (memq 'kill-ring savehist-additional-variables)
    (push 'kill-ring savehist-additional-variables)))
;; Strip text properties to keep savehist file small (Doom).
(add-hook 'savehist-save-hook
          (lambda ()
            (setq kill-ring
                  (mapcar #'substring-no-properties
                          (cl-remove-if-not #'stringp kill-ring)))))

;; --- Editing: prevent ffap from pinging hostnames (Centaur) ---
(setq ffap-machine-p-known 'reject)

;; --- Windows: proportional resize + reversible C-x 1 (Purcell, Prot) ---
(setq window-combination-resize t)

;; winner-mode is already enabled by Prelude; add a toggle for C-x 1.
(defun my/toggle-delete-other-windows ()
  "Delete other windows in frame if any, or restore previous window config."
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))
(global-set-key (kbd "C-x 1") #'my/toggle-delete-other-windows)

;; --- Navigation: fast mark popping (Purcell, Centaur, Prot) ---
;; After the first C-u C-SPC, keep pressing C-SPC to keep popping.
(setq set-mark-command-repeat-pop t)

;; --- UX: recenter after save-place restores position (Doom) ---
(advice-add 'save-place-find-file-hook :after
            (lambda (&rest _)
              (when buffer-file-name (ignore-errors (recenter)))))

;; --- UX: auto-select help window (Prot) ---
(setq help-window-select t)

;; ============================================================
;;  3. Windows-specific performance tuning
;; ============================================================

(when (eq system-type 'windows-nt)
  ;; w32-appid: merge taskbar icon with pinned shortcut
  (let ((w32-vendor-dir (expand-file-name "vendor/w32-appid" prelude-dir)))
    (when (file-directory-p w32-vendor-dir)
      (add-to-list 'load-path w32-vendor-dir)
      (when (require 'w32-appid nil t)
        (w32-set-app-user-model-id "GNU.Emacs"))))

  ;; VC / Git
  (setq auto-revert-check-vc-info nil)
  (setq auto-revert-interval 10)
  (setq vc-handled-backends '(Git))
  (setq vc-git-annotate-switches "-w")

  ;; Process creation
  (setq w32-pipe-read-delay 0)
  (setq w32-pipe-buffer-size (* 64 1024))
  (setq process-adaptive-read-buffering nil)

  ;; File I/O
  (setq inhibit-compacting-font-caches t)
  (setq w32-get-true-file-attributes nil)
  (setq find-file-visit-truename nil)

  ;; Rendering
  (setq redisplay-skip-fontification-on-input t)
  (setq fast-but-imprecise-scrolling t)
  (setq jit-lock-defer-time 0.05)

  ;; Long lines (Emacs 29+)
  (when (boundp 'long-line-threshold)
    (setq long-line-threshold 1000)
    (setq large-hscroll-threshold 1000)
    (setq syntax-wholeline-max 1000))

  ;; Large files
  (add-hook 'find-file-hook
            (lambda ()
              (when (> (buffer-size) (* 512 1024))
                (fundamental-mode)
                (font-lock-mode -1)
                (message "⚠ Large file — disabled font-lock"))))

  ;; Magit
  (with-eval-after-load 'magit
    (setq magit-refresh-status-buffer nil)
    (setq magit-diff-refine-hunk nil))

  ;; Projectile
  (with-eval-after-load 'projectile
    (setq projectile-indexing-method 'alien)
    (setq projectile-enable-caching t)))

;; ---- GC tuning ----
(with-eval-after-load 'gcmh
  (setq gcmh-idle-delay 'auto)
  (setq gcmh-high-cons-threshold (* 64 1024 1024))
  (setq gcmh-low-cons-threshold (* 16 1024 1024)))

;; Backup / auto-save locations
(setq backup-directory-alist
      `(("." . ,(expand-file-name "savefile/backups" prelude-dir))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "savefile/auto-saves/" prelude-dir) t)))
(make-directory (expand-file-name "savefile/auto-saves" prelude-dir) t)
(make-directory (expand-file-name "savefile/backups" prelude-dir) t)
(setq make-backup-files t)
(setq auto-save-default t)

;; ============================================================
;;  4. Desktop save/restore
;; ============================================================

(setq desktop-path (list user-emacs-directory))
(setq desktop-dirname user-emacs-directory)
(setq desktop-base-file-name ".emacs.desktop")
(setq desktop-base-lock-name ".emacs.desktop.lock")
(setq desktop-restore-eager 3)
(setq desktop-auto-save-timeout 60)
(setq desktop-restore-frames t)
(setq desktop-restore-in-current-display t)
(setq desktop-load-locked-desktop t)
(setq desktop-lazy-idle-delay 2)
(setq desktop-lazy-verbose nil)
(setq desktop-save t)
(setq my/desktop-restore-state nil)

(defun my/desktop-save-current-session ()
  "Save desktop now without releasing the lock."
  (when (bound-and-true-p desktop-save-mode)
    (let ((desktop-save t))
      (desktop-save desktop-dirname nil))))

(defun my/desktop-client-frame-p (&optional frame)
  "Return non-nil if FRAME is a real GUI client frame."
  (let ((f (or frame (selected-frame))))
    (and (frame-live-p f)
         (display-graphic-p f)
         (or (frame-parameter f 'client)
             (> (frame-width f) 0)))))

(defun my/desktop-enable-daemon-saving-after-init ()
  "Enable desktop saving after daemon startup."
  (when (daemonp)
    (desktop-save-mode 1)))

(defun my/desktop-cleanup-restart-helper-frame (frame)
  "Delete redundant restart helper FRAME after desktop restoration.
The helper-created frame is only needed to trigger desktop restoration in
daemon mode.  Once desktop has restored the saved client frames, drop the
temporary helper frame if another GUI client frame now exists."
  (when (and (frame-live-p frame)
             (frame-parameter frame 'my-restart-helper-frame))
    (set-frame-parameter frame 'my-restart-helper-frame nil)
    (let ((other-client-frames
           (seq-filter
            (lambda (other-frame)
              (and (not (eq other-frame frame))
                   (my/desktop-client-frame-p other-frame)))
            (frame-list))))
      (when other-client-frames
        (select-frame-set-input-focus (car other-client-frames))
        (delete-frame frame)))))

(defun my/desktop-restore-for-daemon-frame (&optional frame)
  "In daemon mode, restore desktop once on the first usable GUI FRAME."
  (when (and (daemonp)
             (eq my/desktop-restore-state nil)
             (my/desktop-client-frame-p frame)
             (file-exists-p (expand-file-name desktop-base-file-name desktop-dirname)))
    (setq my/desktop-restore-state 'scheduled)
    (let ((target-frame (or frame (selected-frame))))
      (run-with-timer
       0 nil
       (lambda ()
         (when (and (frame-live-p target-frame)
                    (eq my/desktop-restore-state 'scheduled))
            (setq my/desktop-restore-state 'running)
            (with-selected-frame target-frame
              (let ((desktop-load-locked-desktop t))
                (desktop-read desktop-dirname)
                (my/desktop-cleanup-restart-helper-frame target-frame)
                (select-frame-set-input-focus target-frame)))
            (setq my/desktop-restore-state 'done)))))))

(defun my/desktop-maybe-save-on-frame-delete (frame)
  "Persist desktop when deleting the last GUI frame in daemon mode."
  (when (and (daemonp)
             (my/desktop-client-frame-p frame)
             (<= (length (seq-filter #'my/desktop-client-frame-p (frame-list))) 1))
    (my/desktop-save-current-session)))

(with-eval-after-load 'server
  (add-hook 'server-after-make-frame-hook #'my/desktop-restore-for-daemon-frame))
(add-hook 'delete-frame-functions #'my/desktop-maybe-save-on-frame-delete)
(if (daemonp)
    (add-hook 'after-init-hook #'my/desktop-enable-daemon-saving-after-init t)
  (desktop-save-mode 1))

;; ============================================================
;;  5. Treemacs sidebar
;; ============================================================

(prelude-require-packages '(treemacs))
(setq treemacs-show-hidden-files nil
      treemacs-width 30
      treemacs-is-never-other-window t)
(global-set-key (kbd "C-c t") 'treemacs)

(defvar my/treemacs-was-visible nil)
(with-eval-after-load 'desktop
  (add-to-list 'desktop-globals-to-save 'my/treemacs-was-visible))
(add-hook 'desktop-save-hook
          (lambda ()
            (setq my/treemacs-was-visible
                  (and (fboundp 'treemacs-get-local-window)
                       (treemacs-get-local-window)
                       t))))
(add-hook 'emacs-startup-hook
          (lambda ()
            (when my/treemacs-was-visible
              (treemacs))))

(with-eval-after-load 'treemacs
  (defun my/treemacs-set-small-font ()
    (require 'face-remap nil t)
    (face-remap-add-relative 'default :height 0.85))
  (add-hook 'treemacs-mode-hook #'my/treemacs-set-small-font)
  (define-key treemacs-mode-map [mouse-1]
              (lambda (event)
                "Single click to open/expand."
                (interactive "e")
                (mouse-set-point event)
                (treemacs-RET-action))))

;; ============================================================
;;  6. Restart Emacs
;; ============================================================

(defvar my/restart-emacs-helper-script
  (expand-file-name "scripts/restart-emacs-daemon.ps1"
                    (file-name-directory (or load-file-name buffer-file-name)))
  "PowerShell helper used to restart Emacs daemon on Windows.")

(defun my/restart-emacs-windows-powershell ()
  "Return the PowerShell executable used by the Windows restart helper."
  (or (executable-find "pwsh")
      (executable-find "pwsh.exe")
      (executable-find "powershell.exe")
      (user-error "PowerShell executable not found")))

(defun my/restart-emacs-server-file ()
  "Return the current server authentication file path."
  (expand-file-name
   (or (and (boundp 'server-name) server-name) "server")
   (expand-file-name
    (or (and (boundp 'server-auth-dir) server-auth-dir)
        "~/.emacs.d/server/"))))

(defun my/restart-emacs-windows-command (&optional launcher)
  "Build the PowerShell command used to restart Windows Emacs.
When LAUNCHER is non-nil, start a detached helper process first."
  (unless (file-exists-p my/restart-emacs-helper-script)
    (user-error "Restart helper not found: %s" my/restart-emacs-helper-script))
  (append
   (list (my/restart-emacs-windows-powershell)
         "-NoProfile"
         "-NonInteractive"
         "-ExecutionPolicy"
         "Bypass"
         "-File"
         my/restart-emacs-helper-script
         "-OldPid"
         (number-to-string (emacs-pid))
         "-EmacsBinDir"
         (directory-file-name (expand-file-name invocation-directory))
         "-ServerFile"
         (my/restart-emacs-server-file)
         "-ServerName"
         (or (and (boundp 'server-name) server-name) "server"))
   (when launcher
     '("-Launcher"))
   (when (display-graphic-p)
     '("-LaunchClient"))))

(defun my/restart-emacs-windows ()
  "Restart Windows Emacs via an external helper after this daemon exits."
  (let* ((command (my/restart-emacs-windows-command t))
         (program (car command))
         (args (cdr command))
         (w32-start-process-show-window nil)
         (w32-start-process-share-console nil)
         (exit-code (apply #'call-process program nil nil nil args)))
    (unless (zerop exit-code)
      (user-error "Failed to launch restart helper: %s" exit-code))))

(defun my/restart-emacs ()
  "Restart Emacs cross-platform."
  (interactive)
  (when (and (bound-and-true-p desktop-save-mode) desktop-dirname)
    (desktop-save desktop-dirname t))
  (cond
   ((eq system-type 'windows-nt)
    (my/restart-emacs-windows))
   ((eq system-type 'darwin)
    (if (executable-find "open")
        (call-process "open" nil 0 nil "-n" "-a" "Emacs")
      (start-process "restart-emacs" nil (expand-file-name invocation-name invocation-directory))))
   (t
    (start-process "restart-emacs" nil (expand-file-name invocation-name invocation-directory))))
  (kill-emacs))

(global-set-key (kbd "C-c q r") #'my/restart-emacs)
(global-set-key (kbd "C-c q q") #'save-buffers-kill-emacs)

;; ============================================================
;;  7. Consult extra bindings
;; ============================================================

;; Override prelude-vertico's M-s f (consult-find) with consult-fd.
;; Must be OUTSIDE with-eval-after-load so the binding takes effect
;; before consult loads — otherwise the first M-s f invokes consult-find
;; which calls Windows find.exe (a text search tool, not file finder).
(autoload 'consult-fd "consult" nil t)
(global-set-key (kbd "M-s f") #'consult-fd)

(with-eval-after-load 'consult
  (global-set-key (kbd "C-s") 'consult-line)
  (global-set-key (kbd "C-x C-r") 'consult-recent-file)
  (setq consult-fd-args '((if (executable-find "fdfind" 'remote) "fdfind" "fd")
                           "--full-path --color=never --hidden"))

  (defun my/org-rg-search ()
    "Ripgrep search all files in `org-directory'."
    (interactive)
    (consult-ripgrep (expand-file-name org-directory)))
  (global-set-key (kbd "C-c n s") #'my/org-rg-search))

;; ============================================================
;;  8. Org-mode — Sean's full workflow
;; ============================================================

;; Emacs server (Prelude starts server too, but ensure org-protocol)
(with-eval-after-load 'org
  (require 'org-protocol))

(with-eval-after-load 'org
  (require 'org-tempo)
  (require 'org-habit)
  (setq org-habit-graph-column 50
        org-habit-preceding-days 21
        org-habit-following-days 7
        org-habit-show-habits-only-for-today nil)

  (setq ispell-program-name nil)
  (setq org-directory "~/org")

  ;; Todo keywords
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "WAITING(w!)" "HOLD(h@/!)" "|" "DONE(d!)" "CANCELLED(c@)")))
  (setq org-todo-keyword-faces
        '(("TODO"      :foreground "#2952a3" :weight bold)
          ("NEXT"      :foreground "#c0392b" :weight bold)
          ("WAITING"   :foreground "#8b6914" :weight bold)
          ("HOLD"      :foreground "#6c6c6c" :weight bold)
          ("DONE"      :foreground "#2e7d32" :weight bold)
          ("CANCELLED" :foreground "#9e9e9e" :weight bold)))

  (setq org-log-done 'time)
  (setq org-log-into-drawer t)

  ;; Display
  (setq org-confirm-babel-evaluate nil)
  (setq org-src-fontify-natively t)
  (setq org-src-tab-acts-natively t)
  (setq org-return-follows-link t)
  (setq org-startup-indented nil)
  (setq org-hide-leading-stars t)
  (add-hook 'org-mode-hook 'org-indent-mode)
  (setq org-startup-folded 'content)
  (setq org-hide-emphasis-markers t)
  (setq org-ellipsis " ▾")

  ;; Writing ergonomics in Org: keep trailing/tab whitespace checks,
  ;; but stop highlighting long prose lines like journal entries.
  (defun my/org-whitespace-setup ()
    "Tame whitespace visualization in Org buffers."
    (setq-local whitespace-style '(face tabs empty trailing))
    (when whitespace-mode
      (whitespace-mode -1)
      (whitespace-mode +1))
    (visual-line-mode +1))
  (add-hook 'org-mode-hook #'my/org-whitespace-setup)

  ;; Inline images
  (setq image-use-external-converter t)
  (setq org-image-actual-width '(600))

  ;; ---- org-attach: 统一附件管理 ----
  (require 'org-attach)
  (setq org-attach-id-dir (expand-file-name "data/" org-directory)) ; ~/org/data/
  (setq org-attach-method 'cp)              ; 复制文件（不移动/不链接）
  (setq org-attach-use-inheritance t)        ; 子 heading 继承父附件目录
  (setq org-attach-store-link-p 'attached)   ; attach 后自动存储 org link
  (setq org-attach-auto-tag nil)             ; 不自动打 :ATTACH: tag（保持标签简洁）

  ;; ---- 修复 attachment 链接中文乱码 ----
  ;; org-attach 对非 ASCII 文件名做 percent-encoding，导致链接不可读。
  ;; 修复方式：attach 后自动给 stored link 补上解码的文件名作为描述，
  ;; 这样 C-c C-l 插入时显示为 [[attachment:编码路径][原始文件名.pdf]]
  (defun my/org-attach-store-link-decoded (&rest _)
    "Fix stored links from `org-attach-attach' to include decoded description."
    (when org-stored-links
      (let ((latest (car org-stored-links)))
        (when (and (stringp (car latest))
                   (string-prefix-p "attachment:" (car latest))
                   (or (null (cadr latest)) (string= (cadr latest) "")))
          (setcar (cdr latest)
                  (decode-coding-string
                   (url-unhex-string
                    (file-name-nondirectory
                     (substring (car latest) (length "attachment:"))))
                   'utf-8))))))
  (advice-add 'org-attach-attach :after #'my/org-attach-store-link-decoded)

  ;; Agenda
  (setq org-agenda-inhibit-startup t)
  (setq org-agenda-tags-column -200)
  (put 'org-agenda-files 'saved-value nil)
  (put 'org-agenda-files 'customized-value nil)
  (setq org-agenda-files '("~/org/inbox.org"
                           "~/org/projects/"
                           "~/org/areas/"
                           "~/org/.calendar"))
  (setq org-default-notes-file "~/org/inbox.org")

  ;; Archive
  (setq org-archive-location
        (concat (expand-file-name ".archive/" org-directory)
                "%s_archive.org::"))

  ;; ---- Append Note helper ----
  (defun my/append-note-goto-bottom ()
    "Move point to end of append-note.org with date separator."
    (let ((today-sep (format-time-string "-- %Y-%m-%d --")))
      (goto-char (point-max))
      (unless (save-excursion
                (goto-char (point-min))
                (search-forward today-sep nil t))
        (unless (bolp) (insert "\n"))
        (insert "\n" today-sep "\n")))
    (goto-char (point-max)))

  ;; ---- Habit capture helper ----
  (defun my/org-capture-habit ()
    "Generate a capture template for a habit."
    (let* ((name (read-string "Habit 名称: "))
           (raw  (read-string "提醒时间 (HH:MM): "))
           (repeat (completing-read "重复周期: "
                                    '(".+1d  — 每天（从完成日起）"
                                      ".+2d  — 每2天"
                                      ".+1w  — 每周"
                                      ".+2w  — 每2周"
                                      ".+1m  — 每月"
                                      "++1d  — 每天（固定日期）"
                                      "++1w  — 每周（固定星期）"
                                      ".+1d/2d — 每天，最多隔2天"
                                      ".+1d/3d — 每天，最多隔3天")
                                    nil t))
           (repeat-val (car (split-string repeat " ")))
           (parts (split-string raw ":"))
           (hour (string-to-number (nth 0 parts)))
           (min  (string-to-number (nth 1 parts)))
           (time (format "%02d:%02d" hour min))
           (today (format-time-string "%Y-%m-%d %a"))
           (end-min (+ min 5))
           (end-hour (+ hour (/ end-min 60)))
           (end-time (format "%02d:%02d" end-hour (% end-min 60))))
      (format "* TODO %s\nSCHEDULED: <%s %s %s>\n:PROPERTIES:\n:STYLE:    habit\n:calendar-id: yuanxiang424@gmail.com\n:END:\n:org-gcal:\n<%s %s-%s>\n:END:\n"
              name today time repeat-val today time end-time)))

  ;; ---- Capture templates ----
  (setq org-capture-templates
        '(("a" "Append Note" plain
           (file+function "~/org/append-note.org" my/append-note-goto-bottom)
           "- %?"
           :empty-lines 1 :jump-to-captured t)
          ("i" "Inbox" entry (file "~/org/inbox.org")
           "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n" :empty-lines 1)
          ("n" "Note" entry (file "~/org/inbox.org")
           "* %^{标题}  %^g\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n%?"
           :empty-lines 1 :jump-to-captured t)
          ("t" "Task" entry (file "~/org/inbox.org")
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n" :empty-lines 1)
          ("j" "Journal" plain
           (function my/journal-capture-goto-today)
           "* %(format-time-string \"%H:%M\")\n%?"
           :empty-lines 1 :jump-to-captured t)
          ("r" "r · 稍后读 [inbox]" entry (file "~/org/inbox.org")
           "* TODO [[%^{URL}][%^{Title}]]\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?" :empty-lines 1)
          ("m" "Movie" entry (file+headline "~/org/collections/media.org" "观影记录")
           "* %^{片名}\n:PROPERTIES:\n:评分: %^{评分|⭐⭐⭐|⭐⭐⭐⭐|⭐⭐⭐⭐⭐|⭐⭐|⭐}\n:END:\n%U\n%?"
           :empty-lines 1)
          ("w" "w · 精读笔记 [ref/]" plain (function my/capture-web-article-target)
           "%?"
           :empty-lines 1 :jump-to-captured t)
          ("h" "Habit" entry (file "~/org/areas/habits.org")
           (function my/org-capture-habit)
           :empty-lines 1)
          ("pl" "Protocol: Read later" entry (file "~/org/inbox.org")
           "* TODO %:annotation\n:PROPERTIES:\n:CREATED: %U\n:END:\n%i\n"
           :immediate-finish t :jump-to-captured t)
          ("pn" "Protocol: Note → references/" plain
           (function my/protocol-note-target)
           "#+begin_quote\n%i\n#+end_quote\n%?"
           :jump-to-captured t)))

  ;; ---- Refile targets ----
  (defun my/org-top-level-org-files (dir)
    "Return top-level non-hidden .org files in DIR."
    (let ((dir (expand-file-name dir))
          result)
      (dolist (path (directory-files dir t "^[^.].*\\.org$") (nreverse result))
        (when (file-regular-p path)
          (push path result)))))

  (defun my/org-project-files ()  (my/org-top-level-org-files "~/org/projects/"))
  (defun my/org-area-files ()     (my/org-top-level-org-files "~/org/areas/"))
  (defun my/org-reference-files () (my/org-top-level-org-files "~/org/references/"))
  (defun my/org-notes-files ()    (my/org-top-level-org-files "~/org/notes/"))

  (setq org-refile-targets
        '(("~/org/inbox.org" :maxlevel . 1)
          (my/org-project-files :maxlevel . 2)
          (my/org-area-files :maxlevel . 2)
          (my/org-reference-files :maxlevel . 1)
          (my/org-notes-files :maxlevel . 1)))
  (setq org-refile-use-outline-path 'file)
  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-refile-use-cache nil)

  ;; ---- Tags ----
  (setq org-tag-alist '((:startgroup)
                        ("work" . ?w) ("personal" . ?p) ("learning" . ?l)
                        (:endgroup)
                        ("projectS" . ?s) ("ai" . ?a) ("hiring" . ?h)
                        ("@office" . ?o) ("@home" . ?H) ("@phone" . ?P)))

  ;; ---- Agenda views ----
  (setq org-stuck-projects '("" nil nil ""))

  (defun my/skip-habit ()
    "Skip entries with :STYLE: habit."
    (let ((subtree-end (save-excursion (org-end-of-subtree t))))
      (when (string= (org-entry-get nil "STYLE") "habit")
        subtree-end)))

  (setq org-agenda-custom-commands
        '(("d" "Daily"
           ((agenda "" ((org-agenda-span 'day)
                        (org-deadline-warning-days 3)
                        (org-agenda-skip-scheduled-if-done t)
                        (org-agenda-skip-deadline-if-done t)))
            (todo "NEXT"
                  ((org-agenda-overriding-header "⚡ Next Actions")
                   (org-agenda-skip-function 'my/skip-habit)
                   (org-agenda-sorting-strategy '(priority-down category-keep))))
            (todo "WAITING"
                  ((org-agenda-overriding-header "⏳ Waiting (FYI)")
                   (org-agenda-sorting-strategy '(category-keep))))))

          ("w" "Weekly"
           ((agenda "" ((org-agenda-span 'week)
                        (org-deadline-warning-days 7)
                        (org-habit-show-habits nil)))
            (tags-todo "+work"
                       ((org-agenda-overriding-header "🏢 Work")
                        (org-agenda-skip-function 'my/skip-habit)
                        (org-agenda-sorting-strategy '(todo-state-down priority-down))))
            (tags-todo "+personal"
                       ((org-agenda-overriding-header "🏠 Personal")
                        (org-agenda-skip-function 'my/skip-habit)
                        (org-agenda-sorting-strategy '(todo-state-down priority-down))))
            (tags-todo "+learning"
                       ((org-agenda-overriding-header "📚 Learning")
                        (org-agenda-skip-function 'my/skip-habit)
                        (org-agenda-sorting-strategy '(todo-state-down priority-down))))
            (tags-todo "-work-personal-learning"
                       ((org-agenda-overriding-header "📦 Untagged")
                        (org-agenda-skip-function 'my/skip-habit)
                        (org-agenda-sorting-strategy '(todo-state-down category-keep))))))

          ("g" "GTD Review"
           ((agenda "" ((org-agenda-span 'day)))
            (todo "NEXT"
                  ((org-agenda-overriding-header "⚡ Next Actions")
                   (org-agenda-skip-function 'my/skip-habit)
                   (org-agenda-sorting-strategy '(priority-down category-keep))))
            (todo "TODO"
                  ((org-agenda-overriding-header "📋 All Tasks (Backlog)")
                   (org-agenda-skip-function 'my/skip-habit)
                   (org-agenda-sorting-strategy '(tag-up priority-down category-keep))))
            (todo "WAITING"
                  ((org-agenda-overriding-header "⏳ Waiting")
                   (org-agenda-sorting-strategy '(category-keep))))
            (todo "HOLD"
                  ((org-agenda-overriding-header "🧊 On Hold")
                   (org-agenda-sorting-strategy '(category-keep))))))))

  ;; ---- Babel image dir ----
  (defun my/org-babel-image-dir ()
    "Return .images/ under the current org file."
    (when buffer-file-name
      (let ((dir (expand-file-name ".images/" (file-name-directory buffer-file-name))))
        (make-directory dir t)
        dir)))

  (advice-add 'org-babel-temp-file :around
              (lambda (orig-fn prefix &optional suffix)
                (let ((dir (my/org-babel-image-dir)))
                  (if (and dir suffix (string-match-p "\\.\\(png\\|svg\\|pdf\\|jpg\\)$" suffix))
                      (let ((temporary-file-directory dir))
                        (funcall orig-fn prefix suffix))
                    (funcall orig-fn prefix suffix)))))

  ;; ---- Archive done tasks ----
  (defun my/org-archive-done-tasks ()
    "Archive DONE/CANCELLED tasks in the *current file only*."
    (interactive)
    (unless (buffer-file-name)
      (user-error "Not visiting a file — open an org file first"))
    (org-map-entries
     (lambda ()
       (org-archive-subtree)
       (setq org-map-continue-from (org-element-property :begin (org-element-at-point))))
     "/DONE|CANCELLED" 'file)
    (message "✅ Archived done/cancelled tasks in %s" (file-name-nondirectory (buffer-file-name))))
  (define-key org-mode-map (kbd "C-c A") #'my/org-archive-done-tasks))

(global-set-key (kbd "C-c i t") 'org-toggle-inline-images)

;; ============================================================
;;  9. Org clipboard helpers
;; ============================================================

(defun my/org-download-screenshot-command ()
  "Platform-appropriate screenshot command for org-download."
  (cond
   ((eq system-type 'windows-nt)
    "powershell -Command \"Add-Type -AssemblyName System.Windows.Forms; $img = [System.Windows.Forms.Clipboard]::GetImage(); if ($img) { $img.Save('%s', [System.Drawing.Imaging.ImageFormat]::Png) } else { Write-Error 'No image in clipboard' }\"")
   ((eq system-type 'darwin)
    "sh -c 'if command -v pngpaste >/dev/null 2>&1 && pngpaste \"$1\" >/dev/null 2>&1; then exit 0; else screencapture -i \"$1\"; fi' _ %s")
   (t
    "sh -c 'if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -t image/png -o > \"$1\" 2>/dev/null || true; fi; if [ ! -s \"$1\" ]; then if command -v wl-paste >/dev/null 2>&1; then wl-paste --no-newline --type image/png > \"$1\" 2>/dev/null || true; fi; fi; if [ ! -s \"$1\" ]; then if command -v maim >/dev/null 2>&1; then maim -s \"$1\"; elif command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then grim -g \"$(slurp)\" \"$1\"; fi; fi' _ %s")))

(defun my/org-paste-rich ()
  "Paste rich text (HTML with images) from clipboard as Org content."
  (interactive)
  (unless buffer-file-name
    (user-error "Please save the current buffer first"))
  (pcase system-type
    ('windows-nt
     (let* ((img-dir (expand-file-name ".images" (file-name-directory buffer-file-name)))
            (script (expand-file-name "~/org/.src/clipboard-to-org.ps1"))
            (img-dir-win (replace-regexp-in-string "/" "\\\\" img-dir))
            (script-win (replace-regexp-in-string "/" "\\\\" script))
            (cmd (format "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%s\" -ImageDir \"%s\""
                         script-win img-dir-win))
            (out-file (string-trim (shell-command-to-string cmd))))
       (if (and (not (string-blank-p out-file))
                (file-exists-p out-file))
           (progn
             (insert-file-contents out-file)
             (delete-file out-file)
             (message "✅ Rich text pasted"))
         (message "⚠ Clipboard empty or conversion failed (out: %s)" out-file))))
    ('darwin
     (let* ((script (expand-file-name "~/org/.src/clipboard-to-org-macos.sh"))
            (img-dir (expand-file-name ".images" (file-name-directory buffer-file-name))))
       (cond
        ((file-exists-p script)
         (let ((out-file (string-trim (shell-command-to-string
                                       (format "sh %s %s" (shell-quote-argument script) (shell-quote-argument img-dir))))))
           (if (and (not (string-blank-p out-file))
                    (file-exists-p out-file))
               (progn
                 (insert-file-contents out-file)
                 (delete-file out-file)
                 (message "✅ Rich text pasted"))
             (message "⚠ macOS clipboard conversion failed"))))
        ((executable-find "pbpaste")
         (let ((text (shell-command-to-string "pbpaste")))
           (if (string-blank-p text)
               (message "⚠ macOS clipboard empty")
             (insert text)
             (message "✅ Plain text pasted (macOS fallback)"))))
        (t (message "⚠ pbpaste not found")))))
    (_ (message "⚠ Rich text clipboard not implemented for this platform"))))

(defun my/yank-markdown-as-org ()
  "Yank Markdown from kill-ring, convert to Org via pandoc."
  (interactive)
  (unless (executable-find "pandoc")
    (user-error "pandoc not found in PATH"))
  (save-excursion
    (with-temp-buffer
      (yank)
      (shell-command-on-region
       (point-min) (point-max)
       "pandoc -f markdown -t org --wrap=preserve"
       t t)
      (kill-region (point-min) (point-max)))
    (yank))
  (message "✅ Markdown → Org pasted"))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c V") #'my/org-paste-rich)
  (define-key org-mode-map (kbd "C-c M") #'my/yank-markdown-as-org))

;; ============================================================
;;  10. Org visual enhancements
;; ============================================================

;; Pixel-aligned agenda tags (fix CJK misalignment)
(defun my/org-agenda-align-tags-pixel ()
  "Right-align agenda tags using pixel-based display alignment."
  (let ((inhibit-read-only t)
        (target-pixel (- (window-text-width nil t)
                         (* 2 (string-pixel-width " ")))))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\([ \t]+\\)\\(:[[:alnum:]_@#%:]+:\\)[ \t]*$" nil t)
        (let* ((tags-str (match-string 2))
               (tags-pixel (string-pixel-width tags-str))
               (align-to (- target-pixel tags-pixel)))
          (when (> align-to 0)
            (put-text-property (match-beginning 1) (match-end 1)
                               'display `(space :align-to (,align-to)))))))))

(add-hook 'org-agenda-finalize-hook #'my/org-agenda-align-tags-pixel)

;; org-appear
(prelude-require-packages '(org-appear))
(add-hook 'org-mode-hook 'org-appear-mode)
(setq org-appear-autolinks t
      org-appear-autosubmarkers t
      org-appear-autoemphasis t
      org-appear-delay 0.3)

;; org-download — 走 org-attach 体系
(prelude-require-packages '(org-download))
(add-hook 'org-mode-hook 'org-download-enable)
(setq org-download-method 'attach              ; 截图/拖拽图片存入 org-attach 目录
      org-download-heading-lvl 0               ; 附加到最近的 heading（需要 heading 有/自动生成 ID）
      org-download-timestamp "%Y%m%d%H%M%S-"
      org-download-image-org-width 800
      org-download-annotate-function (lambda (_link) "")
      org-download-screenshot-method (my/org-download-screenshot-command))

;; Fix: org-download-dnd-fallback 使用了 Emacs 30 已废弃的 dnd-handle-one-url，
;; 导致拖入非图片文件（如 epub）时报 Wrong type argument: listp 错误。
;; 改用 Emacs 30+ 的 dnd-handle-multiple-urls API。
(with-eval-after-load 'org-download
  (when (fboundp 'dnd-handle-multiple-urls)
    (defun org-download-dnd-fallback (uri action)
      (let ((dnd-protocol-alist
             (rassq-delete-all
              'org-download-dnd
              (copy-alist dnd-protocol-alist))))
        (dnd-handle-multiple-urls
         (selected-window) (list uri) action)))))

;; Fix: org-download--fullname 只解码 %20 → 空格，其他 percent-encoding
;; （如中文 %E4%B8%96%E7%95%8C）原样保留，导致拖入中文文件名时生成乱码副本。
;; 改为完整 url-unhex-string + UTF-8 解码。
(with-eval-after-load 'org-download
  (defun org-download--fullname (link &optional ext)
    "Return the file name where LINK will be saved to.
It's affected by `org-download--dir'.
EXT can hold the file extension, in case LINK doesn't provide it.
[patched] Full percent-decoding for non-ASCII filenames."
    (let ((filename
           (decode-coding-string
            (url-unhex-string
             (file-name-nondirectory
              (car (url-path-and-query
                    (url-generic-parse-url link)))))
            'utf-8))
          (dir (org-download--dir)))
      (when (string-match ".*?\\.\\(?:png\\|jpg\\)\\(.*\\)$" filename)
        (setq filename (replace-match "" nil nil filename 1)))
      (when ext
        (setq filename (concat (file-name-sans-extension filename) "." ext)))
      (abbreviate-file-name
       (expand-file-name
        (funcall org-download-file-format-function filename)
        dir)))))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c i p") 'org-download-clipboard)
  (define-key org-mode-map (kbd "C-c i s") 'org-download-screenshot)
  (define-key org-mode-map (kbd "C-c i y") 'org-download-yank)
  (define-key org-mode-map (kbd "C-c i d") 'org-download-delete))

;; ============================================================
;;  11. Org-gcal (Google Calendar sync)
;; ============================================================

(require 'plstore)

;; plstore encryption workaround
(advice-add 'plstore-save :around
            (lambda (orig-fun plstore)
              (let ((secret-alist (copy-tree (plstore--get-secret-alist plstore))))
                (dolist (sec secret-alist)
                  (let ((pub (assoc (car sec) (plstore--get-alist plstore))))
                    (when pub (nconc pub (cdr sec)))))
                (plstore--set-secret-alist plstore nil)
                (unwind-protect
                    (funcall orig-fun plstore)
                  (plstore--set-secret-alist plstore secret-alist)))))

(prelude-require-packages '(org-gcal))
(setq org-gcal-up-days 7
      org-gcal-down-days 60)
(global-set-key (kbd "C-c G s") 'org-gcal-sync)
(global-set-key (kbd "C-c G f") 'org-gcal-fetch)
(global-set-key (kbd "C-c G d") 'org-gcal-delete-at-point)

(defvar my/org-gcal-default-calendar-id
  "f3f2ce4fb88adc5db8f25b71d3c75d20924a8c147a0feb34eafe477f173a860b@group.calendar.google.com")

(defun my/org-gcal-drawer-timestamp ()
  "返回当前 entry 的 :org-gcal: drawer 里的时间戳。"
  (save-excursion
    (let ((end (save-excursion (outline-next-heading) (point))))
      (when (re-search-forward ":org-gcal:" end t)
        (let ((drawer-end (save-excursion
                            (re-search-forward ":END:" end t)
                            (point))))
          (let ((content (buffer-substring-no-properties (point) drawer-end)))
            (when (string-match "<[^>]+>" content)
              (match-string 0 content))))))))

(defun my/org-gcal-set-drawer (timestamp)
  "把 TIMESTAMP 写入 :org-gcal: drawer。"
  (save-excursion
    (let* ((entry-start (point))
           (entry-end   (save-excursion (outline-next-heading) (point))))
      (goto-char entry-start)
      (if (re-search-forward "^:org-gcal:$" entry-end t)
          (let ((content-start (point)))
            (re-search-forward "^:END:$" entry-end t)
            (beginning-of-line)
            (delete-region content-start (point))
            (insert "\n" timestamp "\n"))
        (goto-char entry-start)
        (if (re-search-forward "^:END:$" entry-end t)
            (progn (end-of-line) (insert "\n:org-gcal:\n" timestamp "\n:END:"))
          (org-end-of-meta-data nil)
          (insert ":org-gcal:\n" timestamp "\n:END:\n"))))))

(defun my/org-gcal-patch-status (calendar-id event-id gcal-status)
  "PATCH GCal event status."
  (require 'org-gcal)
  (require 'request)
  (let ((url (concat (org-gcal-events-url calendar-id)
                     "/" (url-hexify-string event-id)))
        (token (org-gcal--get-access-token calendar-id)))
    (request url
      :type "PATCH"
      :headers `(("Content-Type"  . "application/json")
                 ("Accept"        . "application/json")
                 ("Authorization" . ,(format "Bearer %s" token)))
      :data (json-encode `(("status" . ,gcal-status)))
      :parser 'org-gcal--json-read
      :success (cl-function
                (lambda (&key _data &allow-other-keys)
                  (message "org-gcal: status → %s ✓ (%s)" gcal-status event-id)))
      :error (cl-function
              (lambda (&key error-thrown &allow-other-keys)
                (message "org-gcal: PATCH status failed: %S" error-thrown))))))

(defun my/org-gcal-todo-to-gcal-status (todo-state)
  "Map org todo state to GCal event status."
  (cond
   ((member todo-state '("CANCELLED"))  "cancelled")
   ((member todo-state '("TODO" "NEXT" "WAITING" "HOLD" "DONE")) "confirmed")
   (t nil)))

(defun my/org-gcal-auto-post ()
  "Auto push/update entries with timestamps to GCal."
  (when (derived-mode-p 'org-mode)
    (require 'org-gcal)
    (org-save-outline-visibility t
      (org-map-entries
       (lambda ()
         (let* ((scheduled   (org-entry-get nil "SCHEDULED"))
                (deadline    (org-entry-get nil "DEADLINE"))
                (timestamp   (or scheduled deadline))
                (has-id      (org-entry-get nil "entry-id"))
                (calendar-id (or (org-entry-get nil "calendar-id")
                                 my/org-gcal-default-calendar-id))
                (todo-state  (org-get-todo-state))
                (gcal-status (my/org-gcal-todo-to-gcal-status todo-state))
                (last-state  (org-entry-get nil "gcal-todo-state"))
                (state-changed (and has-id gcal-status
                                    (not (equal last-state todo-state))))
                (drawer-ts   (my/org-gcal-drawer-timestamp))
                (ts-changed  (and timestamp has-id
                                  (or (not drawer-ts)
                                      (not (string= (string-trim timestamp)
                                                    (string-trim drawer-ts)))))))
           (when (and timestamp (or (not has-id) ts-changed))
             (my/org-gcal-set-drawer timestamp)
             (org-entry-put nil "calendar-id" calendar-id)
             (condition-case err
                 (org-gcal-post-at-point)
               (error (message "org-gcal push failed: %s" err))))
           (when state-changed
             (let ((event-id (org-gcal--get-id (point))))
               (when event-id
                 (org-entry-put nil "gcal-todo-state" todo-state)
                 (my/org-gcal-patch-status calendar-id event-id gcal-status))))))
       nil 'file))))

(global-set-key (kbd "C-c G p") #'my/org-gcal-auto-post)

;; Dedup after fetch
(defun my/org-gcal-dedup-after-fetch ()
  "Remove duplicate entries from gcal fetch files."
  (let ((fetch-files (mapcar #'cdr org-gcal-fetch-file-alist))
        (known-ids (make-hash-table :test #'equal)))
    (dolist (file (org-agenda-files t))
      (unless (member (expand-file-name file) (mapcar #'expand-file-name fetch-files))
        (when (file-exists-p file)
          (with-temp-buffer
            (insert-file-contents file)
            (goto-char (point-min))
            (while (re-search-forward "^[ \t]*:entry-id:[ \t]+\\(.+\\)" nil t)
              (puthash (string-trim (match-string 1)) file known-ids))))))
    (dolist (fetch-file fetch-files)
      (let ((fpath (expand-file-name fetch-file)))
        (when (file-exists-p fpath)
          (with-current-buffer (find-file-noselect fpath)
            (org-with-wide-buffer
             (goto-char (point-min))
             (let ((kill-list nil))
               (org-map-entries
                (lambda ()
                  (let ((eid (org-entry-get nil "entry-id")))
                    (when (and eid (gethash eid known-ids))
                      (push (point) kill-list)))))
               (when kill-list
                 (dolist (pos (sort kill-list #'>))
                   (goto-char pos)
                   (org-cut-subtree))
                 (save-buffer)
                 (message "org-gcal dedup: removed %d duplicate(s) from %s"
                          (length kill-list) fetch-file))))))))))

(advice-add 'org-gcal-fetch :after
            (lambda (&rest _) (run-with-idle-timer 5 nil #'my/org-gcal-dedup-after-fetch)))

;; Periodic sync
(with-eval-after-load 'org-gcal
  (run-with-timer 120 1800
                  (lambda ()
                    (when (not org-gcal--sync-lock)
                      (org-gcal-sync)))))

;; ============================================================
;;  12. Org-roam
;; ============================================================

(prelude-require-packages '(org-roam))
(setq org-roam-directory "~/org/roam"
      org-roam-completion-everywhere t
      org-roam-capture-templates
      '(("d" "Default" plain "%?"
         :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n#+date: %U\n#+filetags: \n\n")
         :unnarrowed t)
        ("f" "Fleeting" plain "%?"
         :target (file+head "fleeting/%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n#+date: %U\n#+filetags: :fleeting:\n\n")
         :unnarrowed t)))

;; Web article target for capture "w"
(defun my/capture-web-article-target ()
  "Target function for org-capture: reference note from clipboard URL."
  (let* ((url (string-trim (current-kill 0 t)))
         (title (or (ignore-errors
                      (with-temp-buffer
                        (url-insert-file-contents url)
                        (goto-char (point-min))
                        (when (re-search-forward "<title>\\([^<]*\\)</title>" nil t)
                          (string-trim (match-string 1)))))
                    (read-string "Title: ")))
         (slug (replace-regexp-in-string "[^a-zA-Z0-9\u4e00-\u9fff]+" "-"
                                         (downcase (string-trim title)) t t))
         (slug (replace-regexp-in-string "^-\\|-$" "" slug))
         (file (expand-file-name (concat "references/" slug ".org") org-directory)))
    (set-buffer (org-capture-target-buffer file))
    (when (= (buffer-size) 0)
      (insert (format "#+title: %s\n#+filetags: :ref:\n#+created: %s\n\n* Source\n%s\n\n* Summary\n\n* My Notes\n"
                      title (format-time-string "[%Y-%m-%d %a]") url)))
    (goto-char (point-max))
    (or (re-search-backward "^\\* My Notes" nil t) (goto-char (point-max)))
    (forward-line 1)))

;; org-protocol target for "pn"
(defun my/protocol-note-target ()
  "Target for org-capture 'pn': reference note from org-protocol."
  (let* ((url   (or (plist-get org-store-link-plist :link)
                    (plist-get org-store-link-plist :url) ""))
         (title (or (plist-get org-store-link-plist :description)
                    (read-string "Title: ")))
         (slug  (replace-regexp-in-string
                 "^-\\|-$" ""
                 (replace-regexp-in-string
                  "[^a-zA-Z0-9\u4e00-\u9fff]+" "-"
                  (downcase (string-trim title)) t t)))
         (file  (expand-file-name (concat "references/" slug ".org") org-directory)))
    (set-buffer (org-capture-target-buffer file))
    (when (= (buffer-size) 0)
      (insert (format "#+title: %s\n#+filetags: :ref:\n#+created: %s\n\n* Source\n%s\n\n* Summary\n\n* My Notes\n"
                      title (format-time-string "[%Y-%m-%d %a]") url)))
    (goto-char (point-max))
    (or (re-search-backward "^\\* My Notes" nil t) (goto-char (point-max)))
    (forward-line 1)))

(global-set-key (kbd "C-c n f") 'org-roam-node-find)
(global-set-key (kbd "C-c n i") 'org-roam-node-insert)
(global-set-key (kbd "C-c n l") 'org-roam-buffer-toggle)
(global-set-key (kbd "C-c n c") 'org-roam-capture)
(global-set-key (kbd "C-c n d") 'org-roam-dailies-goto-today)
(global-set-key (kbd "C-c n t") 'org-roam-tag-add)
(with-eval-after-load 'org-roam
  (make-directory (expand-file-name "roam" org-directory) t)
  (make-directory (expand-file-name "roam/fleeting" org-directory) t)
  (org-roam-db-autosync-mode))

;; ============================================================
;;  13. Elfeed & Elfeed-org
;; ============================================================

(prelude-require-packages '(elfeed elfeed-org))
(require 'elfeed)
(require 'elfeed-org)

(setq elfeed-db-directory (expand-file-name "~/org/collections/.elfeed"))
(elfeed-org)
(setq rmh-elfeed-org-files (list (expand-file-name "~/org/collections/elfeed.org")))
(setq-default elfeed-search-filter "@1-month-ago +unread")
(global-set-key (kbd "C-c w e") 'elfeed)
(add-hook 'elfeed-search-mode-hook #'elfeed-update)
(setq elfeed-curl-max-connections 4)
(add-hook 'elfeed-show-mode-hook (lambda () (setq-local shr-use-fonts nil)))

;; Defensive fix: elfeed-db sometimes gets corrupted (set to a non-plist value
;; like "NEXT" or "(W16)") due to find-file-noselect hooks firing during
;; elfeed-db-load. elfeed-db-ensure only checks for nil, so a corrupted value
;; slips through. This advice validates the db before every save and reloads
;; from disk if it's bad.
(defun my/elfeed-db-sanitize-before-save (&rest _)
  "Ensure elfeed-db is a valid plist before saving. Reload if corrupt."
  (unless (and elfeed-db (plistp elfeed-db))
    (message "elfeed-db is corrupt (%S), reloading from disk..." elfeed-db)
    (setf elfeed-db nil)
    (elfeed-db-load)))
(with-eval-after-load 'elfeed-db
  (advice-add 'elfeed-db-save :before #'my/elfeed-db-sanitize-before-save))

;; mpv integration
(defun my/elfeed-play-with-mpv ()
  "Play the current elfeed entry with mpv."
  (interactive)
  (let ((link (if (derived-mode-p 'elfeed-show-mode)
                  (elfeed-entry-link elfeed-show-entry)
                (let ((entries (elfeed-search-selected)))
                  (when entries
                    (elfeed-entry-link (car entries)))))))
    (if link
        (progn
          (message "Starting mpv for %s..." link)
          (start-process "elfeed-mpv" nil "mpv" link)
          (when (derived-mode-p 'elfeed-search-mode)
            (elfeed-search-untag-all-unread)))
      (message "No link found."))))

(with-eval-after-load 'elfeed
  (define-key elfeed-search-mode-map (kbd "v") #'my/elfeed-play-with-mpv)
  (define-key elfeed-show-mode-map (kbd "v") #'my/elfeed-play-with-mpv))

;; ============================================================
;;  14. Journal — org-journal
;; ============================================================

(prelude-require-packages '(org-journal))
(setq org-journal-dir "~/org/journal/"
      org-journal-file-type 'daily
      org-journal-file-format "%Y-%m-%d.org"
      org-journal-date-format "%Y-%m-%d"
      org-journal-file-header "#+title: %Y-%m-%d\n#+filetags: :journal:\n"
      org-journal-start-on-weekday 1
      org-journal-carryover-items nil)

(global-set-key (kbd "C-c j j") 'org-journal-new-entry)
(global-set-key (kbd "C-c j t") 'org-journal-open-current-journal-file)

(defun my/journal-capture-goto-today ()
  "Open today's journal for org-capture. Before 03:00 uses previous day."
  (let* ((now  (decode-time))
         (hour (nth 2 now))
         (time (if (< hour 3)
                   (time-subtract (current-time) (seconds-to-time 86400))
                 (current-time)))
         (file (expand-file-name
                (format-time-string org-journal-file-format time)
                org-journal-dir)))
    (set-buffer (org-capture-target-buffer file))
    (when (= (buffer-size) 0)
      (insert (format "#+title: %s\n#+filetags: :journal:\n"
                      (format-time-string org-journal-date-format time))))
    (goto-char (point-max))))

;; ============================================================
;;  15. Chinese calendar (cal-china-x)
;; ============================================================

(prelude-require-packages '(cal-china-x))
(with-eval-after-load 'calendar
  (require 'cal-china-x)
  (setq calendar-mark-holidays-flag t)
  (setq cal-china-x-important-holidays cal-china-x-chinese-holidays)
  (setq calendar-holidays
        (append cal-china-x-important-holidays
                cal-china-x-general-holidays)))
(with-eval-after-load 'org
  (require 'calendar)
  (require 'cal-china))
(setq org-agenda-include-diary nil)

;; Hide redundant tags in agenda (avoid line wrapping for habits etc.)
(setq org-agenda-hide-tags-regexp "personal\\|habit")

;; Disable flycheck in org-mode (global-flycheck-mode enables it everywhere;
;; the built-in org-lint checker is noisy and unhelpful for normal editing)
(with-eval-after-load 'flycheck
  (setq flycheck-global-modes '(not org-mode)))

;; ============================================================
;;  16. Terminal Chinese Input (pyim)
;; ============================================================

(unless (display-graphic-p)
  (prelude-require-packages '(pyim pyim-basedict))
  (require 'pyim)
  (require 'pyim-basedict)
  (pyim-basedict-enable)
  (setq default-input-method "pyim")
  (setq pyim-default-scheme 'quanpin)
  (setq pyim-page-tooltip 'minibuffer)
  (setq pyim-page-length 5))

;; ============================================================
;;  17. PowerShell mode
;; ============================================================

(prelude-require-packages '(powershell))
(with-eval-after-load 'powershell
  (defun my/powershell-run-file ()
    "Run current .ps1 file."
    (interactive)
    (unless buffer-file-name (user-error "Buffer has no file"))
    (save-buffer)
    (compile (format "pwsh -NoProfile -ExecutionPolicy Bypass -File \"%s\""
                     (expand-file-name buffer-file-name))))

  (defun my/powershell-run-region ()
    "Send region or current line to inferior PowerShell."
    (interactive)
    (let* ((beg (if (use-region-p) (region-beginning) (line-beginning-position)))
           (end (if (use-region-p) (region-end)       (line-end-position)))
           (code (buffer-substring-no-properties beg end)))
      (unless (get-buffer "*PowerShell*") (powershell))
      (comint-send-string (get-buffer-process "*PowerShell*") (concat code "\n"))
      (display-buffer "*PowerShell*")))

  (define-key powershell-mode-map (kbd "C-c C-c") #'my/powershell-run-file)
  (define-key powershell-mode-map (kbd "C-c C-r") #'my/powershell-run-region)
  (define-key powershell-mode-map (kbd "C-c C-z") #'powershell))

;; ============================================================
;;  18. Markdown enhancements
;; ============================================================

(with-eval-after-load 'markdown-mode
  (setq markdown-command "pandoc"
        markdown-fontify-code-blocks-natively t
        markdown-header-scaling t
        markdown-enable-wiki-links t
        markdown-italic-underscore t
        markdown-asymmetric-header nil
        markdown-live-preview-delete-export 'delete-on-destroy))

;; ============================================================
;;  19. Config auto-sync (arya-sync) — DISABLED
;;      Uncomment this section if you set up your own config repo.
;;      Scripts live in personal/scripts/arya-sync-*.ps1
;; ============================================================

;; (defgroup arya-sync nil
;;   "Auto sync Emacs config repository."
;;   :group 'convenience)
;;
;; (defcustom arya-sync-enabled nil
;;   "Whether auto sync is enabled."
;;   :type 'boolean)
;;
;; (defcustom arya-sync-debounce-seconds 8
;;   "Seconds to wait after save before syncing."
;;   :type 'number)
;;
;; (defvar arya-sync--timer nil)
;; (defvar arya-sync--process nil)
;; (defvar arya-sync--buffer-name "*arya-sync*")
;;
;; (defun arya-sync--repo-root ()
;;   (file-name-as-directory (expand-file-name prelude-dir)))
;;
;; (defun arya-sync--buffer ()
;;   (get-buffer-create arya-sync--buffer-name))
;;
;; (defun arya-sync--repo-file-p (file)
;;   (let ((tru (file-truename file))
;;         (root (file-truename (arya-sync--repo-root))))
;;     (string-prefix-p root tru)))
;;
;; (defun arya-sync--sync-target-p (file)
;;   "Return t if FILE should trigger auto-sync."
;;   (when (and file (arya-sync--repo-file-p file))
;;     (let* ((root (arya-sync--repo-root))
;;            (rel (file-relative-name file root)))
;;       (or (member rel '("init.el" "early-init.el" "README.md" ".gitignore"))
;;           (string-prefix-p "personal/" rel)
;;           (string-prefix-p "core/" rel)
;;           (string-prefix-p "modules/" rel)))))
;;
;; (defun arya-sync--script-path ()
;;   (expand-file-name "personal/scripts/arya-sync-run.ps1" prelude-dir))
;;
;; (defun arya-sync--start (mode)
;;   (when (and arya-sync-enabled
;;              (not noninteractive)
;;              (file-exists-p (arya-sync--script-path))
;;              (or (null arya-sync--process)
;;                  (not (process-live-p arya-sync--process))))
;;     (let ((buf (arya-sync--buffer))
;;           (mode-arg (if (eq mode 'pull) "pull" "sync")))
;;       (with-current-buffer buf
;;         (goto-char (point-max))
;;         (insert (format "\n[%s] arya-sync %s\n"
;;                         (format-time-string "%Y-%m-%d %H:%M:%S")
;;                         mode-arg)))
;;       (setq arya-sync--process
;;             (make-process
;;              :name "arya-sync"
;;              :buffer buf
;;              :command (list "pwsh" "-NoProfile" "-File" (arya-sync--script-path) mode-arg)
;;              :noquery t
;;              :sentinel
;;              (lambda (proc _event)
;;                (when (memq (process-status proc) '(exit signal))
;;                  (let ((code (process-exit-status proc)))
;;                    (message
;;                     (if (eq code 0)
;;                         (format "arya-sync: %s done" mode-arg)
;;                       (format "arya-sync failed (%s). See %s" code arya-sync--buffer-name)))))))))))
;;
;; (defun arya-sync-pull-now () (interactive) (arya-sync--start 'pull))
;; (defun arya-sync-now () (interactive) (arya-sync--start 'sync))
;;
;; (defun arya-sync--schedule ()
;;   (when arya-sync--timer (cancel-timer arya-sync--timer))
;;   (setq arya-sync--timer
;;         (run-with-idle-timer arya-sync-debounce-seconds nil
;;                              (lambda ()
;;                                (setq arya-sync--timer nil)
;;                                (arya-sync-now)))))
;;
;; (defun arya-sync-after-save-hook ()
;;   (when (and arya-sync-enabled
;;              (buffer-file-name)
;;              (arya-sync--sync-target-p (buffer-file-name)))
;;     (arya-sync--schedule)))
;;
;; (unless noninteractive
;;   (add-hook 'after-init-hook #'arya-sync-pull-now)
;;   (add-hook 'after-save-hook #'arya-sync-after-save-hook))

;; ============================================================
;;  20. Encoding — 全局 UTF-8，避免保存时询问编码
;; ============================================================

(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; ============================================================
;;  21. Emacs server (enable emacsclient support)
;; ============================================================

(require 'server)
(unless (server-running-p) (server-start))

;; ============================================================
;;  22. Startup message
;; ============================================================

(add-hook 'after-init-hook
          (lambda ()
            (message "✓ Prelude + Sean config loaded! (%s)" emacs-version)))


;; ============================================================
;;  23. Reading: pdf-tools + nov.el + org-noter
;; ============================================================

;; --- pdf-tools: 高清 PDF 渲染，替代 DocView ---
;; epdfinfo.exe 由 MSYS2 提供：scoop install msys2 → pacman -S mingw-w64-x86_64-emacs-pdf-tools-server
(prelude-require-package 'pdf-tools)
(setenv "PATH" (concat "C:\\Users\\fengxing.chen\\scoop\\apps\\msys2\\current\\mingw64\\bin" ";" (getenv "PATH")))
(setq pdf-info-epdfinfo-program "C:\\Users\\fengxing.chen\\scoop\\apps\\msys2\\current\\mingw64\\bin\\epdfinfo.exe")
(with-eval-after-load 'pdf-tools
  (pdf-tools-install :no-query))

;; PDF 文件自动用 pdf-view-mode
(add-to-list 'auto-mode-alist '("\\.pdf\\'" . pdf-view-mode))

;; Org 中对 PDF 链接强制走 pdf-tools，避免 attachment 链接只按文本打开
(defun my/org-open-pdf-with-pdf-tools (file _link)
  "Open PDF FILE in Emacs with `pdf-view-mode'."
  (require 'pdf-tools nil t)
  (require 'pdf-view nil t)
  (find-file file)
  (unless (derived-mode-p 'pdf-view-mode)
    (pdf-view-mode)))

;; Org 中对 EPUB 链接强制走 nov.el，同理避免 attachment 按文本打开
(defun my/org-open-epub-with-nov (file _link)
  "Open EPUB FILE in Emacs with `nov-mode'."
  (require 'nov nil t)
  (find-file file)
  (unless (derived-mode-p 'nov-mode)
    (nov-mode)))

(with-eval-after-load 'org
  ;; PDF → pdf-tools
  (let ((pdf-entry (assoc "\\.pdf\\'" org-file-apps)))
    (if pdf-entry
        (setcdr pdf-entry #'my/org-open-pdf-with-pdf-tools)
      (add-to-list 'org-file-apps '("\\.pdf\\'" . my/org-open-pdf-with-pdf-tools))))
  ;; EPUB → nov.el
  (let ((epub-entry (assoc "\\.epub\\'" org-file-apps)))
    (if epub-entry
        (setcdr epub-entry #'my/org-open-epub-with-nov)
      (add-to-list 'org-file-apps '("\\.epub\\'" . my/org-open-epub-with-nov)))))

;; pdf-view 基本设置
(with-eval-after-load 'pdf-view
  ;; display-line-numbers-mode 与 pdf-view-mode 不兼容，进入时关掉
  (add-hook 'pdf-view-mode-hook (lambda () (display-line-numbers-mode -1)))
  ;; 自动适应窗口宽度
  (setq-default pdf-view-display-size 'fit-page)
  ;; 高亮颜色
  (setq pdf-view-midnight-colors '("#ffffff" . "#1e1e2e"))
  ;; 快捷键：h 高亮，t 文字批注，d 划线
  (define-key pdf-view-mode-map (kbd "C-c C-a h") #'pdf-annot-add-highlight-markup-annotation)
  (define-key pdf-view-mode-map (kbd "C-c C-a t") #'pdf-annot-add-text-annotation)
  (define-key pdf-view-mode-map (kbd "C-c C-a d") #'pdf-annot-add-strikeout-markup-annotation))

;; --- nov.el: EPUB 阅读器 ---
(prelude-require-package 'nov)
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

(with-eval-after-load 'nov
  ;; Windows 上 unzip 由 Git 提供
  (setq nov-unzip-program "C:/Program Files/Git/usr/bin/unzip.exe")

  ;; nov-render-html 内部 let-bind shr-use-fonts 为 nov-variable-pitch
  (setq nov-variable-pitch nil)

  (defun my/nov-setup ()
    (let ((font (or (my/first-available-font '("Noto Sans SC"
                                               "Noto Serif SC"
                                               "Microsoft YaHei UI"
                                               "Microsoft YaHei"))
                    "Microsoft YaHei")))
      ;; face-remap 只对 ASCII 生效；CJK 字符走 fontset 不走 face :family。
      ;; 用 nil target 设为 fontset 的默认字体，覆盖所有字符。
      (face-remap-add-relative 'default :family font :height 140)
      (face-remap-add-relative 'variable-pitch :family font :height 140)
      (set-fontset-font t nil (font-spec :family font) nil 'prepend)
      (message "nov: using font \"%s\"" font))
    (visual-line-mode 1)
    (setq nov-text-width 80))
  (add-hook 'nov-mode-hook #'my/nov-setup)

  ;; nov-save-place 用 with-temp-file 写阅读进度，
  ;; 含中文路径时触发 coding-system 选择框，强制 utf-8 写入
  (defun my/nov-save-place-a (orig-fn &rest args)
    (let ((coding-system-for-write 'utf-8))
      (apply orig-fn args)))
  (advice-add 'nov-save-place :around #'my/nov-save-place-a))

;; --- emacs-reader: MuPDF 后端的文档阅读器，试用中 ---
;; 支持 PDF/EPUB/MOBI/FB2/XPS/CBZ/DOCX 等，用来对比 pdf-tools + nov.el
;; 手动试用：M-x reader-mode  或  M-x my/open-with-reader
;; 如果效果好，后续替换 auto-mode-alist
(add-to-list 'load-path (expand-file-name "site-lisp/reader" user-emacs-directory))
(require 'reader-autoloads nil t)

(defun my/open-with-reader ()
  "Open current file buffer with `reader-mode' (emacs-reader)."
  (interactive)
  (reader-mode))

(with-eval-after-load 'reader
  (add-hook 'reader-mode-hook (lambda () (display-line-numbers-mode -1))))

;; --- org-noter: 文档 + org 笔记双向同步 ---
(prelude-require-package 'org-noter)

(with-eval-after-load 'org-noter
  ;; 笔记默认存放目录（你的 org references 目录）
  (setq org-noter-notes-search-path '("~/org/references/"))
  ;; 默认笔记文件名 = 文档文件名.org
  (setq org-noter-default-notes-file-names '("notes.org"))
  ;; 自动保存位置
  (setq org-noter-auto-save-last-location t)
  ;; 打开时自动分屏（文档左，笔记右）
  (setq org-noter-notes-window-location 'horizontal-split)
  ;; 高亮当前笔记对应位置
  (setq org-noter-highlight-selected-text t)

  ;; 强制笔记创建到 ~/org/references/，不跟随 PDF 文件所在目录
  ;; 解决：PDF 在 c:/ 根目录时 org-noter 默认逻辑尝试写 c:/ → Permission denied
  (setq org-noter-create-session-from-document-hook
        '(my/org-noter-create-session-in-references)))

(defun my/org-noter-create-session-in-references (&optional arg document-file-name)
  "Create org-noter session, always placing notes in ~/org/references/.
Default org-noter walks up from the document directory, which fails when
the PDF lives at a root like c:/."
  (let* ((document-file-name (or (run-hook-with-args-until-success
                                  'org-noter-get-buffer-file-name-hook major-mode)
                                 document-file-name))
         (document-path (or document-file-name buffer-file-truename
                            (error "This buffer does not seem to be visiting any file")))
         (document-name (file-name-nondirectory document-path))
         (document-base (file-name-base document-name))
         (notes-dir (expand-file-name "~/org/references/"))
         (notes-file (expand-file-name (concat document-base ".org") notes-dir)))
    ;; 确保目录存在
    (make-directory notes-dir t)
    ;; 如果笔记文件不存在，创建并写入标题和 NOTER_DOCUMENT 属性
    (unless (file-exists-p notes-file)
      (with-temp-file notes-file
        (insert (format "#+title: %s\n#+filetags: :ref:\n#+created: %s\n\n* %s\n:PROPERTIES:\n:NOTER_DOCUMENT: %s\n:END:\n"
                        document-base
                        (format-time-string "[%Y-%m-%d %a]")
                        document-base
                        (expand-file-name document-path)))))
    ;; 打开笔记文件并启动 org-noter
    (with-current-buffer (find-file-noselect notes-file)
      (goto-char (point-min))
      ;; 找到带 NOTER_DOCUMENT 的 heading
      (re-search-forward (org-re-property org-noter-property-doc-file) nil t)
      (org-back-to-heading t)
      (org-noter))))

;; org-noter 快捷键（C-c n 前缀在 sean-config 里已用于 roam，改用 C-c N）
(global-set-key (kbd "C-c N") #'org-noter)

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c N" "org-noter-start"))

;; ============================================================
;;  24. Fix: Org-mode 中文环境下强调标记（加粗/高亮等）不生效
;;  原因：org-mode 要求标记符号两侧是空白或标点，中文字符不满足
;;  方案：将 Unicode 字母（含汉字）加入合法前/后缀字符集
;;  备注：等 Emacs 31版本，会修复这个问题。
;; ============================================================
(with-eval-after-load 'org
  (setcar org-emphasis-regexp-components
          " \t('\"{[:alpha:][:nonascii:]")
  (setcar (nthcdr 1 org-emphasis-regexp-components)
          "[:alpha:][:nonascii:]- \t.,:!?;'\")}\\")
  (org-set-emph-re 'org-emphasis-regexp-components
                   org-emphasis-regexp-components))


(provide 'sean-config)
;;; sean-config.el ends here
