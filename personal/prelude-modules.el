;;; prelude-modules.el --- Sean's Prelude module selection -*- lexical-binding: t; -*-
;;; Code:

;;; Completion framework
(require 'prelude-vertico)   ; vertico + consult + marginalia + orderless
(require 'prelude-company)   ; completion-at-point

;;; Org-mode
(require 'prelude-org)
(require 'prelude-literate-programming) ; ob-python, ob-shell, babel languages

;;; Programming languages (enable what you use)
(require 'prelude-emacs-lisp)
(require 'prelude-lisp)
(require 'prelude-js)
(require 'prelude-python)
(require 'prelude-css)
(require 'prelude-web)
(require 'prelude-yaml)
(require 'prelude-xml)
(require 'prelude-shell)
(require 'prelude-c)
;; (require 'prelude-rust)
;; (require 'prelude-go)

(provide 'prelude-modules)
;;; prelude-modules.el ends here
