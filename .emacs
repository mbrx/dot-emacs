(setq user-emacs-directory "/home/matbro/")
(add-to-list 'load-path "~/.emacs.d/helm-c-yasnippet")

(set-face-attribute 'default nil :height 150)

;;
;;; Load the package manager
;;
(require 'package)
(dolist (source '(("marmalade" . "http://marmalade-repo.org/packages/")
                  ("elpa" . "http://tromey.com/elpa/")
		  ("gnu" . "http://elpa.gnu.org/packages/")
                  ("melpa" . "http://melpa.milkbox.net/packages/")
		  ("org" . "http://orgmode.org/elpa/")
                  ))
  (add-to-list 'package-archives source t))
(package-initialize)

;; Disable electric-pair (which inserts matching paranthesis etc. automatically)
(electric-pair-mode 0)

;; Recentf
(recentf-mode 1)
(setq recentf-max-menu-items 250)
(setq-default recent-save-file "~/.emacs.d/recentf")
(setq helm-ff-file-name-history-use-recentf t)
(global-set-key (kbd "C-c f") 'helm-recentf)

;; Unbind C-x C-c since i have clumsy fingers
(global-unset-key (kbd "C-x C-c"))

(require 'git-commit)
(require 'realgud)
(load-library "realgud")
(desktop-save-mode 1)

(when (fboundp 'winner-mode)
      (winner-mode 1))
;;
;;; ORG-mode ------------------------------------------------------------------
;;

(require 'org)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((python . t) (plantuml . t) (ditaa . t) (dot . t)))

;; fontify code in code-blocks
(setq org-src-fontify-natively t)
(setq org-confirm-babel-evaluate nil)
(setq org-startup-with-inline-images t)
(setq org-plantuml-jar-path "/home/mathias/jars/plantuml.jar")
(setq org-ditaa-jar-path "/home/mathias/jars/ditaa.jar")
;; Display inline images in ORG-mode
(add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)

;; ORG-session handling from:
;; http://kitchingroup.cheme.cmu.edu/blog/2015/03/19/Restarting-org-babel-sessions-in-org-mode-more-effectively/A

(setq org-babel-python-command "python3")

(defun org-babel-kill-session ()
  "Kill session for current code block."
  (interactive)
  (unless (org-in-src-block-p)
    (error "You must be in a src-block to run this command"))
  (save-window-excursion
    (org-babel-switch-to-session)
    (kill-buffer)))
(define-key org-mode-map (kbd "C-c k") 'org-babel-kill-session)

(defun org-babel-remove-result-buffer ()
  "Remove results from every code block in buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward org-babel-src-block-regexp nil t)
      (org-babel-remove-result))))
(define-key org-mode-map (kbd "C-c l") 'org-babel-remove-result-buffer)

(defun src-block-in-session-p (&optional name)
  "Return if src-block is in a session of NAME.
NAME may be nil for unnamed sessions."
  (let* ((info (org-babel-get-src-block-info))
         (lang (nth 0 info))
         (body (nth 1 info))
         (params (nth 2 info))
         (session (cdr (assoc :session params))))

    (cond
     ;; unnamed session, both name and session are nil
     ((and (null session)
           (null name))
      t)
     ;; Matching name and session
     ((and
       (stringp name)
       (stringp session)
       (string= name session))
      t)
     ;; no match
     (t nil))))

(defun org-babel-restart-session-to-point (&optional arg)
  "Restart session up to the src-block in the current point.
Goes to beginning of buffer and executes each code block with
`org-babel-execute-src-block' that has the same language and
session as the current block. ARG has same meaning as in
`org-babel-execute-src-block'."
  (interactive "P")
  (unless (org-in-src-block-p)
    (error "You must be in a src-block to run this command"))
  (let* ((current-point (point-marker))
         (info (org-babel-get-src-block-info))
         (lang (nth 0 info))
         (params (nth 2 info))
         (session (cdr (assoc :session params))))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward org-babel-src-block-regexp nil t)
        ;; goto start of block
        (goto-char (match-beginning 0))
        (let* ((this-info (org-babel-get-src-block-info))
               (this-lang (nth 0 this-info))
               (this-params (nth 2 this-info))
               (this-session (cdr (assoc :session this-params))))
            (when
                (and
                 (< (point) (marker-position current-point))
                 (string= lang this-lang)
                 (src-block-in-session-p session))
              (org-babel-execute-src-block arg)))
        ;; move forward so we can find the next block
        (forward-line)))))
;; (global-unset-key (kbd "C-c C-r"))
;; (global-set-key (kbd "C-c C-r") 'org-babel-restart-session-to-point)
(define-key org-mode-map (kbd "C-c r") 'org-babel-restart-session-to-point)

;;
;;; C-like languages ----------------------------------------------------------
;; C/C++/Java/Cuda/OpenCL/...

;; General C/C++ development
(require 'cc-mode)
(setq-default c-basic-offset 4)
(setq-default c-default-style "k&r")
(setq-default indent-tabs-mode nil)
(defun my-indent-setup ()
  (c-set-offset 'arglist-intro '+))
(add-hook 'c-mode-hook 'my-indent-setup)
(add-hook 'c++-mode-hook 'my-indent-setup)
(setq ff-search-directories '("../Inc/" "../Src/"))
(global-set-key (kbd "C-x C-o") 'ff-find-other-file)
(c-set-offset 'inextern-lang 0)

;; 4 spaces of indentation for java code
(add-hook 'java-mode-hook (lambda () (setq c-basic-offset 4)))

;; Cuda, OpenCL and GLSL
(setq auto-mode-alist (cons '("\.cu$" . c-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.cl$" . c-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.glsl$" . c-mode) auto-mode-alist))

(require 'cl)
(defun* get-closest-pathname (&optional (file "Makefile"))
  "Determine the pathname of the first instance of FILE starting from the current directory towards root.
This may not do the correct thing in presence of links. If it does not find FILE, then it shall return the name
of FILE in the current directory, suitable for creation"
  (let ((root (expand-file-name "/"))) ; the win32 builds should translate this correctly
    (expand-file-name file
                      (loop
                       for d = default-directory then (expand-file-name ".." d)
                       if (file-exists-p (expand-file-name file d))
                       return d
                       if (equal d root)
                       return nil))))
(defun* do-compile (&optional (target ""))
  (let ((makefile (get-closest-pathname)))
    ;;(cd (file-name-directory makefile))
    (compile (format "cd %s; make -f %s %s" (file-name-directory makefile) makefile target))))

(global-set-key (kbd "<f4>") (lambda() (interactive) (do-compile)))
(global-set-key (kbd "<f5>") (lambda() (interactive) (do-compile "run")))
(global-set-key (kbd "C-r") (lambda() (interactive) (do-compile "run")))

;;;

;;

;;
;;; Generic tools -------------------------------------------------------------
;;
(global-set-key (kbd "C-x C-a C-a") 'align)
(global-set-key (kbd "C-x M-a M-a") 'align-regexp)
(global-set-key (kbd "C-x C-<tab>") 'untabify)
(global-set-key (kbd "C-=") 'calculator)
(global-set-key (kbd "C-x C-r") 'query-replace)
(tool-bar-mode -1)

;; Don't query when killing process windows
(setq kill-buffer-query-functions (delq 'process-kill-buffer-query-function kill-buffer-query-functions))

;; Pretty Ctrl-L
(require 'pp-c-l)
(pretty-control-l-mode 1)
(setq pp^L-^L-string "                                               ")

;; Undo tree
(global-undo-tree-mode 1)
(global-set-key (kbd "C-T") 'undo-tree-visualize)

;; Always run the emacs server
(server-start)
(global-auto-revert-mode 1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

(setq doc-view-resolution 300)

;;;

;;
;;; Customized appearance -----------------------------------------------------
;;

;; Colours and themes (apart from customization)
;(add-to-list 'custom-theme-load-path "C:/Users/Mathias/emacs-leuven-theme")
;(load-theme 'leuven t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["black" "red3" "ForestGreen" "yellow3" "blue" "magenta3" "DeepSkyBlue" "gray50"])
 '(custom-enabled-themes (quote (deeper-blue)))
 '(custom-safe-themes
   (quote
    ("e35ef4f72931a774769da2b0c863e11d94e60a9ad97fb9734e8b28c7ee40f49b" default)))
 '(doxymacs-doxygen-dirs
   (quote
    (("^/home/matbro/development/SW10019/trunk/source/Denator" "/home/matbro/development/SW10019/trunk/source/Denator/doxy.tag" "/home/matbro/development/SW10019/trunk/source/Denator/docs/html"))))
 '(ecb-options-version "2.40")
 '(helm-boring-file-regexp-list
   (quote
    ("\\.o$" "~$" "\\.bin$" "\\.lbin$" "\\.so$" "\\.a$" "\\.ln$" "\\.blg$" "\\.bbl$" "\\.elc$" "\\.lof$" "\\.glo$" "\\.idx$" "\\.lot$" "\\.svn$" "\\.hg$" "\\.git$" "\\.bzr$" "CVS$" "_darcs$" "_MTN$" "\\.fmt$" "\\.tfm$" "\\.class$" "\\.fas$" "\\.lib$" "\\.mem$" "\\.x86f$" "\\.sparcf$" "\\.dfsl$" "\\.pfsl$" "\\.d64fsl$" "\\.p64fsl$" "\\.lx64fsl$" "\\.lx32fsl$" "\\.dx64fsl$" "\\.dx32fsl$" "\\.fx64fsl$" "\\.fx32fsl$" "\\.sx64fsl$" "\\.sx32fsl$" "\\.wx64fsl$" "\\.wx32fsl$" "\\.fasl$" "\\.ufsl$" "\\.fsl$" "\\.dxl$" "\\.lo$" "\\.la$" "\\.gmo$" "\\.mo$" "\\.toc$" "\\.aux$" "\\.cp$" "\\.fn$" "\\.ky$" "\\.pg$" "\\.tp$" "\\.vr$" "\\.cps$" "\\.fns$" "\\.kys$" "\\.pgs$" "\\.tps$" "\\.vrs$" "\\.pyc$" "\\.pyo$")))
 '(inhibit-startup-screen t)
 '(package-selected-packages
   (quote
    (multi-web-mode web-mode jinja2-mode realgud git-commit clocker binclock flycheck-pycheckers yaml-mode outline-magic yasnippet undo-tree slime qml-mode pp-c-l pep8 markdown-preview-eww markdown-mode helm-themes helm ein cmake-mode clang-format ace-jump-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(helm-ff-executable ((t (:foreground "saddle brown"))))
 '(markdown-list-face ((t (:inherit markdown-markup-face :foreground "WhiteSmoke"))))
 '(org-block-background ((t (:background "DodgerBlue4"))))
 '(org-level-1 ((t (:inherit outline-1 :underline t :weight bold :height 1.5))))
 '(org-level-2 ((t (:inherit outline-2 :height 1.25))))
 '(outline-1 ((t (:foreground "SkyBlue1" :height 1.2))))
 '(outline-2 ((t (:foreground "CadetBlue1" :height 1.15))))
 '(outline-3 ((t (:foreground "LightSteelBlue1" :height 1.1)))))

;;;

;;
;;; HELM ----------------------------------------------------------------------
;;

(require 'helm-config)
(require 'helm-themes)
(when (executable-find "curl")
  (setq helm-google-suggest-use-curl-p t))
(setq helm-mode-reverse-history t)
(global-set-key (kbd "C-c h") 'helm-mini)
(global-set-key (kbd "M-y") 'helm-show-kill-ring)
(global-set-key (kbd "C-x c g") 'helm-find-files)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "M-x") 'helm-M-x)
(helm-mode 1)


;;;

;;
;;; auto completion -----------------------------------------------------------
;;

(require 'yasnippet)
(require 'helm-c-yasnippet)
(setq helm-yas-space-match-any-greedy t) ;[default: nil]
(global-set-key (kbd "C-c y") 'helm-yas-complete)
(yas-global-mode 0)
;(yas-global-mode 1)
;(yas/load-directory "~/.emacs.d/yasnippet-snippets")

;; auto-complete
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dist")
(ac-config-default)
(ac-set-trigger-key "TAB")
(ac-set-trigger-key "<tab>")

;; flymake
;; (require 'flymake)
;; (add-hook 'find-file-hook 'flymake-find-file-hook)
;; (global-set-key (kbd "<f1>") 'flymake-display-err-menu-for-current-line)
;; ;;(global-set-key (kbd "<f2>") 'flymake-display-warning)
;; (global-set-key (kbd "<f2>") 'flymake-goto-prev-error)
;; (global-set-key (kbd "<f3>") 'flymake-goto-next-error)
;; (defun flymake-display-warning (warning)
;;   "Displays the flymake warnings through the mini-buffer instead of separate popups"
;;   (message warning))

;(defun doMake (arg)
;  (interactive)
;  (compile (string "make -F" (flymake-find-buildfile "Makefile" (pwd)) arg )))

;;(require 'ggtags)
;;(add-hook 'find-file-hook 'gtags-mode)
;;(add-hook 'c-mode-common-hook
;;          (lambda ()
;;            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode)
;;              (ggtags-mode 1))))

;; (require 'qml-mode)
;; (autoload 'qml-mode "qml-mode" "Editing Qt Declarative." t)
;; (add-to-list 'auto-mode-alist '("\\.qml$" . qml-mode))

;(require 'doxymacs)
;(setq doxymacs-doxygen-root "docs/")
;(defcustom doxymacs-doxygen-dirs
;  '(("*" "doxy.tag" "docs/")
;    )
;  )
;    C-c d ? will look up documentation for the symbol under the point.
;    C-c d r will rescan your Doxygen tags file.
;    C-c d f will insert a Doxygen comment for the next function.
;    C-c d i will insert a Doxygen comment for the current file.
;    C-c d ; will insert a Doxygen comment for a member variable on the current line (like M-;).
;    C-c d m will insert a blank multi-line Doxygen comment.
;    C-c d s will insert a blank single-line Doxygen comment;.
;    C-c d @ will insert grouping comments around the current region.

; graphviz-dot-mode
(add-to-list 'auto-mode-alist '("\\.dot$" . graphviz-dot-mode))
(add-to-list 'auto-mode-alist '("\\.m$" . octave-mode))

;; ace-jump-mode
(require 'ace-jump-mode)
(define-key global-map (kbd "C-c SPC") 'ace-jump-mode)

;;(add-hook 'after-init-hook #'global-flycheck-mode)

;;;

;;
;;; LATEX ---------------------------------------------------------------------
;;

(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)
(setq TeX-PDF-mode t)
(add-hook 'LaTeX-mode-hook 'visual-line-mode)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
;; Test these later when writing on a suitable book/article
;(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
;(setq reftex-plug-into-AUCTeX t)

(defun flymake-get-tex-args (file-name)
  ;(list "lualatex" (list "-file-line-error" "-draftmode" "-interaction=nonstopmode" "-shell-escape" file-name)))
  (list "lualatex" (list "-file-line-error" "-interaction=nonstopmode" "-shell-escape" file-name)))

;; Slime using SBCL
;(add-to-list 'load-path "~/pkg/src/slime-2.5")
;(autoload 'slime "slime"
;  "Start an inferior^_superior Lisp and connect to its Swank server."
;  t)
;(require 'slime-autoloads)
;(setq inferior-lisp-program "/usr/bin/sbcl")

;; Company - autocompletion
;:(eval-after-load 'company
;  '(add-to-list 'company-backends 'company-irony))
;,(eval-after-load 'company
;  '(add-to-list 'company-backends 'company-ispell))
;(eval-after-load 'company
;  '(add-to-list 'company-backends 'company-files))

;(add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)
;;;(global-set-key [?\C-\M-\t] 'company-complete)
;(global-set-key (kbd "<C-M-tab>") 'company-complete)
;(add-hook 'after-init-hook 'global-company-mode)

(autoload 'pov-mode "pov-mode" "PoVray scene file mode" t)
(add-to-list 'auto-mode-alist '("\\.pov\\'" . pov-mode))
(add-to-list 'auto-mode-alist '("\\.inc\\'" . pov-mode))

;;;
;;; Markdown ------------------------------------------------------------------
;;;
(require 'markdown-preview-eww)
(autoload 'markdown-mode "markdown-mode"
   "Major mode for editing Markdown files" t)
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;;;
;;; Python --------------------------------------------------------------------
;;;

(require 'pep8)

;;;
;;; Generic programming modes -------------------------------------------------
;;;

(global-set-key (kbd "C-x c") 'compile)

;; Whitespace, highlight wider than 80 chars
(require 'whitespace)
(setq whitespace-line-column 99) ;; limit line length
(setq whitespace-style '(face lines-tail trailing tabs))
(add-hook 'before-save-hook 'whitespace-cleanup)

;; Outline & outshine mode
(add-hook 'outline-mode-hook
          (lambda ()
            (require 'outline-cycle)))
(add-hook 'outline-minor-mode-hook
          (lambda ()
            (require 'outline-magic)
            (define-key outline-minor-mode-map  (kbd "<C-tab>") 'outline-cycle)))
;; (require 'outshine)
;; (add-hook 'outline-minor-mode-hook 'outshine-hook-function)
;; (defvar outline-minor-mode-prefix "\M-#")

;; Enables outline-minor-mode for *ALL* programming buffers
(add-hook 'prog-mode-hook 'outline-minor-mode)

;; (setq my-black "#1b1b1e")

;; (custom-theme-set-faces
;;  'leuven
;;  `(outline-1 ((t (:height 1.25 :background "#268bd2"
;;                           :foreground ,my-black :weight bold))))
;;  `(outline-2 ((t (:height 1.15 :background "#2aa198"
;;                           :foreground ,my-black :weight bold))))
;;  `(outline-3 ((t (:height 1.05 :background "#b58900"
;;                           :foreground ,my-black :weight bold)))))

;(require 'semantic)
;; CEDET - IDE for emacs
;; http://alexott.net/en/writings/emacs-devenv/EmacsCedet.html
;(require 'semantic/ia)
;(require 'semantic/bovine/gcc)
;(semantic-mode 1)

;(require 'sr-speedbar)
;; (add-hook 'prog-mode-hook 'sr-speedbar-open)

;; --------------

;; Emacs Code Browser
;(require 'ecb-autoloads)
;(setq ecb-layout-name "left6")
;(setq ecb-show-sources-in-directories-buffer 'always)
;(setq ecb-compile-window-height 12)

;; ;;; activate and deactivate ecb
;; (global-set-key (kbd "C-x C-;") 'ecb-activate)
;; (global-set-key (kbd "C-x C-:") 'ecb-deactivate)
;; ;;; show/hide ecb window
;; (global-set-key (kbd "C-;") 'ecb-show-ecb-windows)
;; (global-set-key (kbd "C-:") 'ecb-hide-ecb-windows)
;; ;;; quick navigation between ecb windows
;; (global-set-key (kbd "M-1") 'ecb-goto-window-edit1)
;; ;;(global-set-key (kbd "C-2") 'ecb-goto-window-diretories)
;; (global-set-key (kbd "M-2") 'ecb-goto-window-sources)
;; (global-set-key (kbd "M-3") 'ecb-goto-window-methods)
;; (global-set-key (kbd "M-4") 'ecb-goto-window-history)
;; (global-set-key (kbd "M-5") 'ecb-goto-window-compilation)


(defun find-first-non-ascii-char ()
  "Find the first non-ascii character from point onwards."
  (interactive)
  (let (point)
    (save-excursion
      (setq point
            (catch 'non-ascii
              (while (not (eobp))
                (or (eq (char-charset (following-char))
                        'ascii)
                    (throw 'non-ascii (point)))
                (forward-char 1)))))
    (if point
        (goto-char point)
        (message "No non-ascii characters."))))

(display-time)
(provide '.emacs)
;;; .emacs ends here

