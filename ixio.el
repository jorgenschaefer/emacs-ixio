;;; ixio.el --- Use the ix.io paste service

;; Copyright (C) 2013  Jorgen Schaefer <forcer@forcix.cx>

;; Author: Jorgen Schaefer <forcer@forcix.cx>
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Very simple paste interface.

;; `ixio-paste' sends the active region or the current buffer to
;; ix.io, and places the URL into the kill ring.

;;; Code:

(defgroup ixio nil
  "The ixio paste service interface.")

(defcustom ixio-login nil
  "The login to use for ixio."
  :group 'ixio
  :type 'string)

(defcustom ixio-token nil
  "The token to authenticate at ixio with."
  :group 'ixio
  :type 'string)

(defun ixio-paste (&optional beg end)
  "Paste the current region if active, otherwise the current buffer."
  (interactive (if (use-region-p)
                   (list (region-beginning)
                         (region-end))
                 (list (point-min)
                       (point-max))))
  (let* ((data (buffer-substring beg end))
         (url "http://ix.io")
         (url-request-method "POST")
         args
         url-request-data)
    (when (and ixio-login ixio-token)
      (push (cons "login" ixio-login) args)
      (push (cons "token" ixio-login) args))
    (push (cons "f:1" (buffer-substring beg end)) args)
    (setq url-request-data (ixio-urlencode args))
    (with-current-buffer (url-retrieve-synchronously url)
      (goto-char (point-min))
      (re-search-forward "\n\n" nil t)
      (when (looking-at "^user ")
        (forward-line 1))
      (let ((paste-url (buffer-substring (point) (point-at-eol))))
        (kill-new paste-url)
        (kill-buffer (current-buffer))
        (message "Pasted to %s" paste-url)))))

(defun ixio-urlencode (alis)
  "Map an alist of key/value pairs to an URL-encoded string."
  (mapconcat (lambda (pair)
               (format "%s=%s"
                       (url-hexify-string
                        (format "%s" (car pair)))
                       (url-hexify-string
                        (format "%s" (if (consp (cdr pair))
                                         (cadr pair)
                                       (cdr pair))))))
             alis
             "&"))

(provide 'ixio)
;;; ixio.el ends here
