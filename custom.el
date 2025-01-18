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
                (mysubmit-switch-to-unix-bash-sh mysubmit-build-cmd)
                (message mysubmit-build-cmd)
                (switch-to-buffer-other-window
                 (switch-to-unix-bash-command-comint-buffer-name)                   t)
                (end-of-buffer)
                (evil-force-normal-state)
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

(defun mysubmit-switch-to-unix-bash-sh (filename)
  (switch-to-unix-bash-command
   (concat "chmod +x \""filename "\";" "\""filename "\"")
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









(setq vc-follow-symlinks t)
(find-file "/workspaces/" )
(find-file "/workspaces/*" 'wildcards)
(find-file "/workspaces/*/a*build.sh" 'wildcards)
(find-file "/workspaces/gh_utils/*.sh" 'wildcards)
(setq vc-follow-symlinks 'ask)
