;;;;invoices.lisp
;;;;

(in-package :bartleby)

;;; Invoice class

                                        ; maybe do html generation for now

(mito:deftable invoice ()
  ((obj-type :col-type (:varchar 32))
   (obj-id   :col-type (:varchar 32))
   (month    :col-type (:int))
   (year     :col-type (:int))
   (filename :col-type (:varchar 32)))
  (:conc-name "invoice-"))

(mito:ensure-table-exists 'invoice)

;(defvar invoice-object-types '(client employee room))

(defun find-invoice-object (obj-type obj-id)
  "Finds the object at the center of the invoice"
    (cond ((string-equal obj-type "client")
           (client-id-search obj-id))
          ((string-equal obj-type "employee")
           (employee-id-search obj-id))
          ((string-equal obj-type "meeting-room")
           (room-id-search obj-id))))

(defmethod print-object ((obj invoice) stream)
  (print-unreadable-object (obj stream :type t)
    (with-accessors ((obj-type invoice-obj-type)
                     (obj-id   invoice-obj-id)
                     (month    invoice-month)
                     (year     invoice-year)
		     (filename invoice-filename))
	obj
      (format stream
	      "~a-~a~%~a/~a~%~a~%~{~a~%~}"
	      obj-type obj-id month year filename (month-receipts (find-invoice-object obj-type obj-id) month year)))))

(defgeneric make-invoice (object month year)
  (:documentation "Puts together information for an invoice"))

(defmethod make-invoice ((client client) month year)
  (make-instance 'invoice :obj-type "client"
                          :obj-id   (mito:object-id client)
                          :month    month
			  :year     year
                          :filename (default-invoice-filename client month year)))

(defmethod make-invoice ((employee employee) month year)
  (make-instance 'invoice :obj-type "employee"
		          :obj-id   (mito:object-id employee)
			  :month    month
			  :year     year
			  :filename (default-invoice-filename employee month year)))
			  
(defun default-invoice-filename (object month year)
  "Generates a filename for a given invoice."
  (concatenate 'string "invoice"
               (write-to-string (mito:object-id object))
               (write-to-string (month-name month))
               "/"
               (write-to-string year)))
               
;;; Adding and removing invoices

(defmethod add-invoice ((invoice invoice))
  (mito:insert-dao invoice))

(defmethod remove-invoice ((invoice invoice))
  (mito:delete-dao invoice))

(defmethod replace-invoice ((invoice invoice) new-invoice)
  (remove-invoice invoice)
  (add-invoice new-invoice))

;;;Invoice calculations
;;;;------------------------------------------------------------------------

(defmethod invoice-total ((invoice invoice))
  "Returns the total money earned for an invoice."
  (loop :for r :in (receipts (find-invoice-object (invoice-obj-type invoice)
						  (invoice-obj-id invoice)))
	:sum (* (/ (appointment-duration r) 60)
		(employee-hourly-rate (employee-id-search (appointment-employee-id r)))))) ;maybe change input to receipt-list

(defgeneric month-receipts (object month year)
  (:documentation "Returns all receipts for an object in the month"))

(defmethod month-receipts ((employee employee) month year)
  "Returns all apppointments for an employee in a given month."
  (loop :for r :in (all-receipts)
	:if (and (equal (appointment-employee-id r) (mito:object-id employee))
		 (equal month (m (date-o (appointment-timestamp r))))
		 (equal year (y (date-o (appointment-timestamp r)))))
	  :collect r :into rcpts
	:finally (return rcpts)))

(defmethod month-receipts ((client client) month year)
  "Returns all appointments for a client in a given month"
  (loop :for r :in (all-receipts)
	:if (and (equal (appointment-client-id r) (mito:object-id client))
		 (equal month (m (date-o (appointment-timestamp r))))
		 (equal year (y (date-o (appointment-timestamp r)))))
	  :collect r :into rcpts
	:finally (return rcpts)))                            ;;;;;;later add room method

(defun chronological-receipts (receipts)
  "Sorts a list of receipts by oldest to newest."
  (sort (copy-list receipts)
	#'(lambda (receipt1 receipt2)
	    (not (later-date (app-date (appointment receipt1))
			(app-date (appointment receipt2)))))))

;;;;------------------------------------------------------------------------
;;;;Figure out Makeup Table
;;;;------------------------------------------------------------------------

;;;;------------------------------------------------------------------------
;;;;Printing Invoices:
;;;;------------------------------------------------------------------------

(defun printable-invoice-clients (client-list)
  (cond ((null client-list) "")
	(t (concatenate 'string
			(printable-invoice-clients (rest client-list))
			(concatenate 'string
				     (first-name (first client-list))
				     " "
				     (last-name (first client-list))
				     ", ")))))

(defun printable-invoice-employees (employee-list)
  (cond ((null employee-list) "")
	(t (concatenate 'string
			(printable-invoice-employees (rest employee-list))
			(concatenate 'string
				     (first-name (first employee-list))
				     " "
				     (last-name (first employee-list))
				     ", ")))))

(defmethod print-invoice ((invoice invoice) filename)
  (with-open-file (out (asdf:system-relative-pathname "bartleby" filename)
		       :direction         :output
		       :if-does-not-exist :create
		       :if-exists         :overwrite)
    (format out "~%~a~%~%~a~%~%"
	    (title invoice)
	    ;(first-name (subject invoice))
	    ;(last-name (subject invoice)))
	    ;(address (owner invoice)))
     (loop :for r :in (receipts invoice)
	   :do (let ((d  (date-o (timestamp-from-sql (write-to-string (appointment-timestamp r)))))
		     (st (time-o (timestamp-from-sql (write-to-string (appointment-timestamp r)))))
		     (c (client-id-search (appointment-client-id r)))
		     (e (employee-id-search (appointment-employee-id r))))
		 (format out
			 "~a, ~a ~a~a, ~a-~a:~a ~a~%Client: ~a| Employee: ~a~%~a ~amin|~%~%"
			 (second (assoc (day-of-week d) days-of-week))
		         (second (assoc (m d) month-names))
		         (if (equal (length (write-to-string (d d))) 1)
			     (concatenate 'string " " (write-to-string (d d)))
			     (d d))
		         (number-suffix (d d))
		         (y d)
			 (if (equal 1 (length (write-to-string (hour st))))
			     (concatenate 'string " "
					  (write-to-string
					   (if (> (hour st) 12)
					       (- (hour st) 12)
			                       (hour st))))
			     (if (> (hour st) 12)
			         (- (hour st) 12)
			         (hour st)))
			 (if (equal 1 (length (write-to-string (minutes st))))
			     (concatenate 'string "0" (write-to-string (minutes st)))
			     (minutes st))
			 (if (> (hour st) 12) "pm" "am")
			 (concatenate 'string
				      (client-first-name c)
				      " "
				      (client-last-name c))
			 (concatenate 'string
			              (employee-first-name e)
				      " "
				      (employee-last-name e))
			 (write-to-string (receipt-attendance r))
			 (write-to-string (appointment-duration r))))))))
			 
(defgeneric invoice-it (object month year &optional filename title)
  (:documentation "Prints an invoice for an object"))

(defmethod invoice-it ((client client) month year &optional filename title)
  (print-invoice (if filename
		     filename
		     (concatenate 'string
				  (first-name client)
				  "-"
				  (last-name client)
				  "-"
				  (write-to-string month)
				  "-"
				  (write-to-string year)
				  ".txt"))
		 (draft-invoice (if title
				    title
				    (concatenate 'string
						 (second (assoc month month-names))
						 " Appointments"))
				 (id client)
				 (month-receipts client month year))))

(defmethod invoice-it ((employee employee) month year &optional filename title)
  (print-invoice (if filename
		     filename
		     (concatenate 'string
				  (first-name employee)
				  "-"
				  (last-name employee)
				  "-"
				  (write-to-string month)
				  "-"
				  (write-to-string year)
				  ".txt"))
		 (draft-invoice (if title
				    title
				    (concatenate 'string
						 (second (assoc month month-names))
						 " Appointments"))
				(id employee)
				(month-receipts employee month year))))

;;;;------------------------------------------------------------------------
;;;;
;;;;------------------------------------------------------------------------

(defmethod pdf-invoice ((invoice invoice))
  (pdf:with-document ()
    (pdf:with-page ()
      (pdf:with-outline-level ("Invoice" (pdf:register-page-reference))
        (let ((helvetica (pdf:get-font "Helvetica")))
          (pdf:in-text-mode
            (pdf:set-font helvetica 36.0)
            (pdf:draw-text "Test Invoice")))))
    (pdf:write-document "test-invoice.pdf")))

;(defun test-invoice-pdf ()
 ; (let ((width 8.5)
  ;      (height 11)
   ;     (margin-top 1)
    ;    (margin-bottom 1)
       ; (span .02)
     ;;   (helvetica (pdf:get-font "Helvetica")))
 ; (pdf:with-document ()
  ;  (pdf:with-page ()
   ;   (loop :for i :from 1 :to 12
    ;        :do (pdf:rectangle 100 (+ margin-bottom (* i 5)) 1 1)))
 ;   (pdf:write-document "test-invoice.pdf"))))
  ;    
   ;   (pdf:with-outline-level ("Invoice" (pdf:register-page-reference))
    ;      (pdf:in-text-mode
     ;       (pdf:set-font helvetica 36.0)
      ;      ;(pdf:move-text 100 800)
       ;     (pdf:draw-text "Test Invoice"))
        ;  (loop :with line := 1
         ;       :for i :from 1 :to 70
          ;      :do (pdf:draw-left-text 3 5 "Test" helvetica 12.0)))))
   ; (pdf:write-document "test-invoice.pdf")))

(defmethod default-title ((invoice invoice))
  (let ((o (find-invoice-object invoice)))
    (concatenate 'string o (invoice-month invoice) "/" (invoice-year invoice))))

(defmacro invoice-template ((&key invoice) &body body)
  `(pdf:with-document ()
    (pdf:with-page ()
      (pdf:with-outline-level ( (pdf:register-page-reference))
        (let ((helvetica (pdf:get-font "Helvetica")))
          (pdf:in-text-mode
            (pdf:set-font helvetica 12)
            (pdf:draw-text "Test Invoice")))))
    (pdf:write-document (invoice-filename invoice))))

(defun mm-pt (mm)
  "Converts milimeters to pixel points"
  (* mm 2.83464388))

(defun inch-pt (inch)
  "Converts inches into pixel points"
  (* inch 72))

(defclass invoice-layout ()
  ((width         :initarg :width
                  :accessor width)
   (height        :initarg :height
                  :accessor height)
   (margin-top    :initarg :margin-top
                  :accessor margin-top)
   (margin-bottom :initarg :margin-bottom
                  :accessor margin-bottom)))

(defun invoice-layout (width height margin-top margin-bottom)
  (make-instance 'invoice-layout :width width
                                 :height height
                                 :margin-top margin-top
                                 :margin-bottom margin-bottom))

(defun default-invoice-layout ()
  (invoice-layout (inch-pt 8.5)
                  (inch-pt 11)
                  (inch-pt 10)
                  (inch-pt 1)))

;;; make title/ banner
(defmethod make-banner (invoice-layout title)
  (pdf:draw-centered-text (/ (width invoice-layout) 2)
                          (margin-top invoice-layout)
                          "INVOICE"
                          (pdf:get-font "Helvetica")
                          (inch-pt .2)))
  
;;; then populate with items

(defmethod pdf-invoice ((invoice invoice))
  (pdf:with-document ()
    (pdf:with-page ()
      (pdf:with-outline-level ("Invoice" (pdf:register-page-reference))
        ;(let ((helvetica (pdf:get-font "Helvetica")))
          (make-banner (default-invoice-layout) "Turtles")))
    (pdf:write-document "test-invoice.pdf")))
