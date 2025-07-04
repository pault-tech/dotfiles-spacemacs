;; FIX for: magit error, which is from server-start since magit uses client/server to open commint message editor
;; in github codespaces with emacs. 2 line tweak to original function definition:
;; server-ensure-safe-dir: ‘/tmp/emacs1000’ is not a safe directory because it is accessible by others (756)
(require 'server)
(defun server-ensure-safe-dir (dir)
  "Make sure DIR is a directory with no race-condition issues.
Creates the directory if necessary and makes sure:
- there's no symlink involved
- it's owned by us
- it's not readable/writable by anybody else."
  (setq dir (directory-file-name dir))
  (let ((attrs (file-attributes dir 'integer)))
    (unless attrs
      (with-file-modes ?\700
        (make-directory dir t))
      (setq attrs (file-attributes dir 'integer)))

    ;; Check that it's safe for use.
    (let* ((uid (file-attribute-user-id attrs))
           (w32 (eq system-type 'windows-nt))
           (unsafe (cond
                    ((not (eq t (file-attribute-type attrs)))
                     (if (null attrs) "its attributes can't be checked"
                       (format "it is a %s"
                               (if (stringp (file-attribute-type attrs))
                                   "symlink" "file"))))
                    ((and w32 (zerop uid)) ; on FAT32?
                     (display-warning
                      'server
                      (format-message "\
Using `%s' to store Emacs-server authentication files.
Directories on FAT32 filesystems are NOT secure against tampering.
See variable `server-auth-dir' for details."
                                      (file-name-as-directory dir))
                      :warning)
                     nil)
                    ((and (/= uid (user-uid)) ; is the dir ours?
                          (or (not w32)
                              ;; Files created on Windows by Administrator
                              ;; (RID=500) have the Administrators (RID=544)
                              ;; group recorded as the owner.
                              (/= uid 544) (/= (user-uid) 500)))
                     (format "it is not owned by you (owner = %s (%d))"
                             (user-full-name uid) uid))
                    (w32 nil)           ; on NTFS?
                    ((let ((modes (file-modes dir 'nofollow)))
                       (unless (zerop (logand (or modes 0) #o077))
                         (format "it is accessible by others (%03o)" modes))))
                    (t nil)))
           )
      ;; (message dir)
      ;; (debug)
      (if (equal dir "/tmp/emacs1000")
          (setq unsafe nil))
      ;; fix is 2 lines above
      (when unsafe
        (error "`%s' is not a safe directory because %s"
               (expand-file-name dir) unsafe)))))

























(defun _tmp ()
  (query-replace "" "my" nil (use-region-beginning) (use-region-end) nil (use-region-noncontiguous-p))
  )




(defun my-tramp-buffer-p ()
  (or
   (if buffer-file-name
       (if (tramp-tramp-file-p buffer-file-name)
           t))
   (if (and (equal major-mode 'dired-mode) list-buffers-directory )
       (if (tramp-tramp-file-p  list-buffers-directory )
           t))
   )
  )

(defun mysubmit-submit-this ()
  (interactive)
  (let (
        (orig-window (buffer-name))
        cmd
        )
    (if ;;Emacs lisp file
        (equal (file-name-extension (buffer-file-name)) "el")
        (let ()
          (save-buffer)
          (if     (load-file buffer-file-truename )
              (emacs-lisp-byte-compile))
          )
      (if ;;Shell File
          (or (equal (file-name-extension (buffer-file-name)) "sh")
              (equal mode-name "sh"))
          (progn
            (let ()
              (save-buffer)
              (switch-to-unix-bash-command

               (concat "chmod +x \""(if (my-tramp-buffer-p) (my-tramp-file-path-only buffer-file-name) buffer-file-name) "\";" "\""(if (my-tramp-buffer-p) (my-tramp-file-path-only buffer-file-name) buffer-file-name) "\"")

               (switch-to-unix-bash-command-comint-buffer-name)
               )
              (switch-to-buffer-other-window
               (switch-to-unix-bash-command-comint-buffer-name)                   t)
              (end-of-buffer)
              (evil-force-normal-state)
              ))
        (if
            (equal (file-name-extension (buffer-file-name)) "bash")
            ;;Like .sh but runs it in a terminal buffer
            ;;#TODO: use exec-sequal:-- like syntax in buffer string instead of .bash suffix
            (let
                ((cmd-buffer-name (switch-to-unix-bash-command-comint-buffer-name)))
              (save-buffer)
              (if (get-buffer cmd-buffer-name)
                  (progn
                    (exec-sql-send-buffer-string cmd-buffer-name (concat "chmod +x "(buffer-file-name)"; " (buffer-file-name)))
                    (switch-to-buffer-other-window     cmd-buffer-name                   t)
                    )
                ;;else
                (spacemacs/default-pop-shell)
                (rename-buffer
                 cmd-buffer-name)
                (switch-to-buffer-other-window
                 cmd-buffer-name                   t)
                (end-of-buffer)
                (evil-force-normal-state)
                )
              )
          (if mysubmit-build-cmd
              (progn
                (setq mysubmit-build-cmd (expand-file-name mysubmit-build-cmd (locate-dominating-file "." mysubmit-build-cmd)))
                (save-buffer)
                (mysubmit-switch-to-unix-bash-sh mysubmit-build-cmd buffer-file-truename)
                (message mysubmit-build-cmd)
                ;; TODO: there seems to be a bug here where there is a switch to *no-buffer-file-name. see 1 line fix below
                (select-window (get-buffer-window orig-window))

                ;; begin fix
                (if nil
                    (progn
                      (other-window 1)
                      ;; (switch-to-buffer-other-window
                      ;;  (switch-to-unix-bash-command-comint-buffer-name) 'no-record)
                      (end-of-buffer)
                      (evil-force-normal-state)
                      ;; begin fix-part2
                      ;; (switch-to-buffer-other-window (get-buffer-window orig-window))
                      (other-window 1)
                      ;; end fix-part2
                      ))
                )

            (message "(mysubmit-submit-this) has not been defined for this file type or mode.")
            ))))
    (if (not (window-live-p (get-buffer orig-window)))
        (switch-to-buffer (get-buffer orig-window)))
    (select-window (get-buffer-window orig-window))
    ))


(defvar mysubmit-build-cmd nil)


(defun switch-to-unix-bash-command-comint-buffer-name()
  (if buffer-file-name
      (concat ""(file-name-nondirectory
                 buffer-file-name)
              "--(sh "buffer-file-name")"
              )
    "*no-buffer-file-name"
    )
  )

(defun mysubmit-switch-to-unix-bash-sh (filename buffr-file-name &optional cmd-args)
  (switch-to-unix-bash-command
   ;; (concat "chmod +x \""filename "\";" "\""filename "\"") ;;v1
   ;; (concat "chmod +x \""filename "\";" "\""filename "\"" " \""buffr-file-name"\"") ;;v2
   (concat "chmod +x \""filename "\";" "\""filename "\"" " \""buffr-file-name"\""
           (if cmd-args (concat " \""cmd-args"\"") "")
           )
   (concat (file-name-nondirectory
            filename)
           "--(sh "filename")"
           )
   )
  )

(defun mysubmit-switch-to-unix-cmd (cmd filename)
  (switch-to-unix-bash-command
   (concat cmd " \""filename "\"")
   (concat (file-name-nondirectory
            filename)
           "--("cmd" "filename")"
           )
   )
  )



;; (defcustom ssh-program "ssh"
;;   "*Name of program to invoke ssh"
;;   :type 'string
;;   :group 'ssh)

(defalias 'ssh-elisp 'ssh)


(defun switch-to-unix-bash-command (&optional shell-command shell-buffer-name create-new-buffer-p for-file-name)
  (interactive)
  (let* ((shell-buff (if shell-buffer-name
                         shell-buffer-name
                       (get-shell-buffer-for-current-buffer-or-file for-file-name)))
         (buffer-filen (or for-file-name buffer-file-name list-buffers-directory ""))
         (v (when (tramp-tramp-file-p buffer-filen)
              (tramp-dissect-file-name buffer-filen)))
         (luser (when (tramp-tramp-file-p buffer-filen)
                  (tramp-file-name-user v)))
         (lhost (when (tramp-tramp-file-p buffer-filen)
                  (tramp-file-name-host v)))
         (method (when (tramp-tramp-file-p buffer-filen)
                   (tramp-file-name-method v)))
         (cur-buff (current-buffer))
         alist-method
         )
    (setq lhost
          (if (stringp lhost)
              lhost
            (elt lhost 0)))
    (setq luser
          (if (stringp luser)
              luser
            (elt luser 0)))
    ;;(debug)
    (if (and
         (get-buffer-process shell-buff)
         (not create-new-buffer-p))
        ;;shell for buffer already running, cd to current dir
        (progn
          (if t t
            (switch-to-buffer shell-buff)
            (pop-to-buffer (concat shell-buff))
            ))
      ;;create shell process
      (if (or
           (my-tramp-buffer-p)
           (if for-file-name
               (string-match "@" for-file-name)))
          ;;remote file, run ssh on remote
          (progn
            (setq alist-method
                  (get-cdr-from-alist-for-name
                   switch-to-unix-bash-methods-alist
                   lhost
                   ))
            (if alist-method (setq method alist-method))
            (if (equal method "telnet")
                (progn
                  (telnet lhost)
                  (rename-buffer shell-buff)
                  )
              (if (equal ssh-program "plink")
                  (let ((passw
                         (ange-ftp-get-passwd lhost luser)
                         ))
                    (ssh (concat lhost " -X -l " luser " -pw "passw)))
                (shell shell-buff) ;; shell acutally opens ssh
                )
              )
            )
        (if (get-buffer-process shell-buff)
            (if create-new-buffer-p
                (unix-newshell-my shell-buff)
              (switch-to-buffer shell-buff))
          (unix-newshell-my shell-buff)
          )
        )
      )
    (if shell-command
        (send-string (get-buffer-process shell-buff) (concat shell-command"\n"))
      )

    (pop-to-buffer shell-buff 'other-window)
    (end-of-buffer )
    )
  )

(defun unix-newshell-my (shell-buffer-name)
  (interactive)
  (let ((buffname shell-buffer-name) (i 1))
    (while (and (get-buffer buffname) (< i 100))
      (setq i (+ i 1))
      (setq buffname (concat shell-buffer-name (int-to-string i))))
    (shell buffname)
    ))


(defun switch-to-unix ()
  (interactive)
  (if (get-buffer-process "unix")
      (switch-to-buffer "unix")
    (shell)))

(defun switch-to-unix-bash-file-at-point ()
  (interactive)
  (switch-to-unix-bash (ffap-string-at-point)))

(defun switch-to-unix-bash (&optional default-directory-for-shell)
  (interactive)
  (let ((dir-to-cd (if default-directory-for-shell default-directory-for-shell
                     (expand-file-name default-directory)))
        (remote nil))
    (if (or (my-tramp-buffer-p)
            (if default-directory-for-shell
                (tramp-tramp-file-p default-directory-for-shell)))
        (progn
          (if (string-match ":/" dir-to-cd)
              (setq dir-to-cd (substring dir-to-cd (+ (string-match ":/" dir-to-cd) 1))))
          (if (string-match ":~/" dir-to-cd)
              (setq dir-to-cd (substring dir-to-cd (+ (string-match ":~/" dir-to-cd) 1))))
          (setq remote t))
      )
    ;;called from sppedbar
    ;; (if (equal frame-title-format "Speedbar")
    ;;     (progn
    ;;       (select-frame speedbar-attached-frame)
    ;;       (setq dir-to-cd (my-spdb-directory-on-line-num nil))
    ;;       (other-frame 4)
    ;;       ))

    ;;remove user@host for tramp file names
    (switch-to-unix-bash-command (concat  "cd \""dir-to-cd"\"\n") nil nil default-directory-for-shell)

    (if (not 'BROKEN)
        (pop-to-buffer (get-shell-buffer-for-current-buffer-or-file default-directory-for-shell)
                       'other-window))

    (if (not remote)
        (progn
          (message dir-to-cd)
          (setq default-directory dir-to-cd))
      )
    )
  )

(global-set-key "b" (quote mysubmit-submit-this))
(spacemacs/declare-prefix "o" "own-menu")
(spacemacs/set-leader-keys "oj" 'mysubmit-submit-this)








(defvar exec-sql-exec-str-prefix "")
(defvar exec-sql-exec-str-suffix "")

(defun exec-sql (&optional dont-force-always-to-prompt-only-prompt-w-update-delete)
  (interactive)
  (let* ((buff (switch-to-unix-bash-command-comint-buffer-name))
         ;; (markactive (c-region-is-active-p))
         (markactive (region-active-p))
         (start-para (save-excursion
                       (backward-paragraph)
                       (point)))
         (end-para (save-excursion
                     (forward-paragraph)
                     (point)))
         (execstr (if markactive
                      (concat
                       (buffer-substring-no-properties (point) (mark))"\n")
                    ;; (if
                    ;; jupyter notebook NOTE: this was abandoned in favor of setting paragraph-start regex for jupytext code cell
                    ;; get-current-buffer-text-between-double-percent
                    (concat
                     exec-sql-exec-str-prefix
                     (buffer-substring-no-properties start-para end-para)
                     exec-sql-exec-str-suffix
                     )
                    ;; )
                    )))
    ;; (debug)
    ;; (if (exec-buffer-redirect-to (buffer-file-name))
    ;;     (setq buff (exec-buffer-redirect-to (buffer-file-name))))
    (if (or
         (and
          dont-force-always-to-prompt-only-prompt-w-update-delete;;nil to temporarily break this and always prompt
          (not (string-match "delete" execstr))
          (not (string-match "update" execstr))
          )
         (y-or-n-p (concat buff":      SQL contains update or delete continue? \n\n" execstr))
         )
        t
      (error "Delete or update canceled"))

    ;;Find the buffer to send commands to
    (if (get-buffer-process buff)
        (exec-sql-send-buffer-string buff execstr)
      (if (string-match "--exec-buffer:.*\n"
                        (buffer-substring-no-properties (point-min) (point-max)))
          (message (concat "no process in buffer:"buff))
        (switch-to-unix-bash-command execstr  buff
                                     nil
                                     ;; (exec-buffer-redirect-list-get-remote-file (buffer-file-name))
                                     (buffer-file-name)
                                     )
        )
      )

    ;;(write-string-to-file "/tmp/execstr.sh" execstr)
    (other-window 1)
    (if markactive (pulse-momentary-highlight-region (point) (mark))
      (pulse-momentary-highlight-region start-para end-para))
    )
  )

(defun exec-sql-no-prompt ()
  (exec-sql 'no-prompt)
  )

(defun exec-sql-send-buffer-string (buff execstr)
  (progn
    ;; (message (concat "submitting:  (replace-all execstr "%" "_PERCENT_")))
    ;; (ready-message)
    (process-send-string
     (get-buffer-process buff) (concat execstr "\n"))
    (switch-to-buffer-other-window buff)
    )
  )

(global-set-key "l" (lambda ()(interactive)(exec-sql 'no-prompt)))






(defun thing-at-point-or-point-mark ()
  (if mark-active
      (buffer-substring (mark) (point))
    (thing-at-point 'symbol)))

(defun query-replace-symbol-at-point (to)
  (interactive "MReplace with:")
  (kill-new (thing-at-point-or-point-mark))
  (query-replace
   (thing-at-point-or-point-mark) to nil (point) (point-max) ))

(global-set-key "8" (quote query-replace-symbol-at-point))

(defun find-grep-symbol-at-point ()
  (interactive)
  ;;(switch-to-unix-bash-command (concat "find . | xargs grep "(thing-at-point-or-point-mark)))
  (if (thing-at-point-or-point-mark)
      (kill-new (thing-at-point-or-point-mark)))
  (call-interactively 'grep-find)
  )

(global-set-key "i" (quote find-grep-symbol-at-point))



(defun in-devcontainer-p ()
  (or
   (file-exists-p "/.dockerenv")
   (file-exists-p "~/eww")
   ;; t
   )
  )

(defun web-search-google (&optional search-type word)
  (interactive)
  (let (
        (devcontainer-p (in-devcontainer-p))
        (urlenc
         (url-encode-url word))
        (engine (if (eq search-type 'duckduckgo)
                    "https://duckduckgo.com/?t=ffab&q="
                  "http://www.google.com/search?q="
                  ;; "https://www.google.com/search?gbv=1&q="
                  ))
        )
    (if (and devcontainer-p
             (eq search-type 'duckduckgo))
        (eww-browse-url
         (concat
          engine
          urlenc
          ))
      (browse-url
       ;; (eww-browse-url
       (concat
        engine
        ;; (convert-string-to-url word)
        urlenc
        ))
      )
    )
  )

(defun web-search-google-that ()
  (interactive)
  (web-search-google 'google (thing-at-point-or-point-mark)))

(defun web-search-duckduckgo-that ()
  (interactive)
  (web-search-google 'duckduckgo (thing-at-point-or-point-mark)))


(run-at-time 30 nil (lambda ()
                      (setq vc-follow-symlinks t)
                      (find-file-noselect "/workspaces/" t nil)
                      (find-file-noselect "/workspaces/*" t nil 'wildcards)
                      (setq vc-follow-symlinks 'ask)
                      ))
(run-at-time 60 nil (lambda ()
                      (setq vc-follow-symlinks t)
                      (find-file-noselect "/workspaces/*/a*build.sh" t nil 'wildcards)
                      (find-file-noselect "/workspaces/gh_utils/*.sh" t nil 'wildcards)
                      ;;elisp
                      (find-file-noselect "/workspaces/gh_utils/*.el" t nil 'wildcards)
                      (setq vc-follow-symlinks 'ask)
                      ))

(load-file "/workspaces/gh_utils/custom.el")


(defun mytmp ()
  (if mark-active
      (buffer-substring (mark) (point))
    (thing-at-point 'symbol)))
