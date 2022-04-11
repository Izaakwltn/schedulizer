;;;;backup.lisp

(in-package :schedulizer)

;;;;For now, backing up is simple- just overwrite the previous backup with all items in the designated list

;;;;function for generating a backup given a filename, list to backup, function for formatting them
(defgeneric backup-unit (object)
  (:documentation "Prepares an object for backup."))

;(defmethod backup-unit ((client client))
 ; (format nil "(~a ~a)~%" (write-to-string (first-name client))
;	  (last-name client)))

;make backup-unit for appointments, clients, employees, rooms, maybe more categories

(defun make-backup (backup-name filename object-list)
  (with-open-file (out (asdf:system-relative-pathname "schedulizer" filename)
		       :direction         :output
		       :if-does-not-exist :create
		       :if-exists         :overwrite)
    (format out ";;;;~a~%(in-package :schedulizer)~%~%(defvar ~a '(" filename backup-name)
    (loop :for o :in object-list
	  :do (format out "~a~%" (backup-unit o)))
    (format out "))"))) ;;;;;;;so backup-unit will work for any object

(defun load-backup (backup-list)
  "Iterates through backup list, runs each command"

;;;;make backup then make functions for loading the backup when the program is loaded
