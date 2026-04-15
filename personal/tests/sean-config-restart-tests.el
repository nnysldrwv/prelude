(require 'cl-lib)
(require 'ert)

(ert-deftest my/restart-emacs-windows-command-includes-launcher-and-client-switches ()
  (let ((my/restart-emacs-helper-script
         "C:/Users/fengxing.chen/.emacs.d/personal/scripts/restart-emacs-daemon.ps1")
        (invocation-directory "C:/Users/fengxing.chen/scoop/apps/msys2/current/mingw64/bin/")
        (server-auth-dir "C:/Users/fengxing.chen/.emacs.d/server/")
        (server-name "server"))
    (cl-letf (((symbol-function 'emacs-pid) (lambda () 4242))
              ((symbol-function 'display-graphic-p) (lambda (&optional _) t))
              ((symbol-function 'file-exists-p)
               (lambda (path)
                 (string= path my/restart-emacs-helper-script)))
              ((symbol-function 'my/restart-emacs-windows-powershell)
               (lambda () "C:/Program Files/PowerShell/7/pwsh.exe")))
      (should
       (equal
        (my/restart-emacs-windows-command t)
        '("C:/Program Files/PowerShell/7/pwsh.exe"
          "-NoProfile"
          "-NonInteractive"
          "-ExecutionPolicy"
          "Bypass"
          "-File"
          "C:/Users/fengxing.chen/.emacs.d/personal/scripts/restart-emacs-daemon.ps1"
          "-OldPid"
          "4242"
          "-EmacsBinDir"
          "c:/Users/fengxing.chen/scoop/apps/msys2/current/mingw64/bin"
          "-ServerFile"
          "c:/Users/fengxing.chen/.emacs.d/server/server"
          "-ServerName"
          "server"
          "-Launcher"
          "-LaunchClient"))))))

(ert-deftest my/restart-emacs-windows-command-uses-server-name-without-client-switch ()
  (let ((my/restart-emacs-helper-script "C:/restart-emacs-daemon.ps1")
        (invocation-directory "C:/Emacs/bin/")
        (server-auth-dir "C:/Users/fengxing.chen/.emacs.d/server/")
        (server-name "my-server"))
    (cl-letf (((symbol-function 'emacs-pid) (lambda () 99))
              ((symbol-function 'display-graphic-p) (lambda (&optional _) nil))
              ((symbol-function 'file-exists-p)
               (lambda (path)
                 (string= path my/restart-emacs-helper-script)))
              ((symbol-function 'my/restart-emacs-windows-powershell)
               (lambda () "pwsh.exe")))
      (should
       (equal
        (my/restart-emacs-windows-command nil)
        '("pwsh.exe"
          "-NoProfile"
          "-NonInteractive"
          "-ExecutionPolicy"
          "Bypass"
          "-File"
          "C:/restart-emacs-daemon.ps1"
          "-OldPid"
          "99"
          "-EmacsBinDir"
          "c:/Emacs/bin"
          "-ServerFile"
          "c:/Users/fengxing.chen/.emacs.d/server/my-server"
          "-ServerName"
          "my-server"))))))

(ert-deftest my/restart-emacs-windows-command-errors-when-helper-is-missing ()
  (let ((my/restart-emacs-helper-script "C:/missing-restart-helper.ps1"))
    (cl-letf (((symbol-function 'file-exists-p) (lambda (_path) nil)))
      (should-error (my/restart-emacs-windows-command)
                    :type 'user-error))))

(ert-deftest my/desktop-cleanup-restart-helper-frame-deletes-redundant-frame ()
  (let ((target 'target-frame)
        (other 'other-frame)
        cleared focused deleted)
    (cl-letf (((symbol-function 'frame-live-p) (lambda (_frame) t))
              ((symbol-function 'frame-parameter)
               (lambda (frame param)
                 (and (eq frame target)
                      (eq param 'my-restart-helper-frame)
                      t)))
              ((symbol-function 'set-frame-parameter)
               (lambda (frame param value)
                 (push (list frame param value) cleared)))
              ((symbol-function 'frame-list)
               (lambda () (list target other)))
              ((symbol-function 'my/desktop-client-frame-p)
               (lambda (frame) (memq frame (list target other))))
              ((symbol-function 'select-frame-set-input-focus)
               (lambda (frame) (setq focused frame)))
              ((symbol-function 'delete-frame)
               (lambda (frame) (setq deleted frame))))
      (my/desktop-cleanup-restart-helper-frame target)
      (should (equal cleared '((target-frame my-restart-helper-frame nil))))
      (should (eq focused other))
      (should (eq deleted target)))))

(ert-deftest my/desktop-cleanup-restart-helper-frame-keeps-nonredundant-frame ()
  (let ((target 'target-frame)
        cleared focused deleted)
    (cl-letf (((symbol-function 'frame-live-p) (lambda (_frame) t))
              ((symbol-function 'frame-parameter)
               (lambda (frame param)
                 (and (eq frame target)
                      (eq param 'my-restart-helper-frame)
                      t)))
              ((symbol-function 'set-frame-parameter)
               (lambda (frame param value)
                 (push (list frame param value) cleared)))
              ((symbol-function 'frame-list)
               (lambda () (list target)))
              ((symbol-function 'my/desktop-client-frame-p)
               (lambda (frame) (eq frame target)))
              ((symbol-function 'select-frame-set-input-focus)
               (lambda (frame) (setq focused frame)))
              ((symbol-function 'delete-frame)
               (lambda (frame) (setq deleted frame))))
      (my/desktop-cleanup-restart-helper-frame target)
      (should (equal cleared '((target-frame my-restart-helper-frame nil))))
      (should (null focused))
      (should (null deleted)))))
