;;; codex-ide-config.el --- Codex IDE integration for Prelude -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Load the vendored codex-ide package and set sane defaults for this Windows setup.
;;
;;; Code:

(prelude-require-package 'transient)

(require 'savehist)
(require 'codex-ide)

(setq codex-ide-cli-path
      (expand-file-name "~/AppData/Local/Microsoft/WinGet/Links/codex.exe")
      codex-ide-approval-policy "on-request"
      codex-ide-sandbox-mode "workspace-write"
      codex-ide-personality "pragmatic"
      codex-ide-focus-on-open t
      codex-ide-enable-emacs-tool-bridge t
      codex-ide-want-mcp-bridge t
      codex-ide-suppress-server-start-prompts t
      codex-ide-emacs-bridge-python-command
      (expand-file-name "~/scoop/apps/msys2/current/mingw64/bin/python3.exe")
      codex-ide-emacs-bridge-emacsclient-command
      (expand-file-name "~/scoop/apps/msys2/current/mingw64/bin/emacsclient.exe"))

(with-eval-after-load 'savehist
  (unless (memq 'codex-ide-persisted-project-state savehist-additional-variables)
    (push 'codex-ide-persisted-project-state savehist-additional-variables)))

(global-set-key (kbd "C-c C-;") #'codex-ide-menu)

(with-eval-after-load 'codex-ide
  (define-key codex-ide-session-mode-map (kbd "C-c C-s") #'codex-ide-submit)
  (define-key codex-ide-session-mode-map (kbd "M-RET") #'codex-ide-submit))

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c C-;" "codex"
    "C-c C-s" "codex-submit"))

(provide 'codex-ide-config)
;;; codex-ide-config.el ends here
