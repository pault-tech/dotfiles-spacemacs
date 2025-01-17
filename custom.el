(find-file "/workspaces/*" 'wildcards)
(find-file "/workspaces/*/a*build.sh" 'wildcards)
(find-file "/workspaces/gh_utils/*.sh" 'wildcards)

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
