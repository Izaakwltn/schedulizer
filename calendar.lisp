;;;;calendar.lisp

(in-package :schedulizer)

;;;;------------------------------------------------------------------------
;;;;Date Class
;;;;------------------------------------------------------------------------

(defclass date ()
  ((month       :initarg :month
	        :accessor month)
   (day         :initarg :day
	        :accessor day)
   (year        :initarg :year
	        :accessor year)))

(defmethod print-object ((obj date) stream)
  (print-unreadable-object (obj stream :type t)
    (with-accessors ((month month)
		     (day day)
		     (year year))
	obj
      (format stream "~a, ~a ~a~a, ~a"
	      (second (assoc (day-of-week (date month day year)) days-of-week))
	      (second (assoc month month-names))
	      day
	      (number-suffix day)
	      year))))

(defun date (m d y)
  (make-instance 'date :month m
		       :day   d
		       :year  y))

;;;;------------------------------------------------------------------------
;;;;Messing with dates
;;;;------------------------------------------------------------------------

(defun later-date (date1 date2)
  "Compares two dates, returns the later date."
  (cond ((> (year date1) (year date2)) date1)
	((> (year date2) (year date1)) date2)
	((> (month date1) (month date2)) date1)
	((> (month date2) (month date1)) date2)
	((> (day date1) (day date2)) date1)
	((> (day date2) (day date1)) date2)
	(t date1)))

(defun equal-date (date1 date2)
  "Determines whether two dates are equal."
  (if (and (equal (month date1) (month date2))
	   (equal (day   date1) (day   date2))
	   (equal (year  date1) (year date2)))
	 t
	 nil))

(defun month-days (month year)
  "Given a month and a year, returns the number of days in that month."
  (second (assoc month (if (leap-year-p year)
			   leap-year-numbers
			   common-year-numbers))))

(defun add-days (date days)
  "Returns a date a specified number of days after a particular date."
  (cond ((zerop days) date)
	((and (equal (month date) 12)
	      (equal (day date) 31))
	 (add-days (date 1 1 (+ (year date) 1)) (- days 1)))
	((equal (day date) (month-days (month date) (year date)))
	 (add-days (date (+ (month date) 1) 1 (year date)) (- days 1)))
	(t (add-days (date (month date) (+ 1 (day date)) (year date))
		     (- days 1)))))
			       

;;;;------------------------------------------------------------------------
;;;;Date Calculations
;;;;------------------------------------------------------------------------

(defvar common-year-numbers '((1 31)
			      (2 28)
			      (3 31)
			      (4 30)
			      (5 31)
			      (6 30)
			      (7 31)
			      (8 30)
			      (9 30)
			      (10 31)
			      (11 30)
			      (12 31)))

(defvar leap-year-numbers '((1 31)
			    (2 29)
			    (3 31)
			    (4 30)
			    (5 31)
			    (6 30)
			    (7 31)
			    (8 30)
			    (9 30)
			    (10 31)
			    (11 30)
			    (12 31)))

(defvar month-names '((1 "January")
		      (2 "February")
		      (3 "March")
		      (4 "April")
		      (5 "May")
		      (6 "June")
		      (7 "July")
		      (8 "August")
		      (9 "September")
		      (10 "October")
		      (11 "November")
		      (12 "December")))

(defvar days-of-week '((0 "Sunday")
		       (1 "Monday")
		       (2 "Tuesday")
		       (3 "Wednesday")
		       (4 "Thursday")
		       (5 "Friday")
		       (6 "Saturday")))

(defun day-cycle (day-value change)
  "Cycles through days of the week as designated."
  (cond ((zerop change) day-value)
	((equal day-value 6) (day-cycle 0 (- change 1)))
	(t (day-cycle (+ day-value 1) (- change 1)))))

(defun leap-year-p (year)
  "Determines whether a given year is a leap year"
  (cond ((not (zerop (mod year 4))) nil)
	((not (zerop (mod year 100))) t)
	((not (zerop (mod year 400))) nil)
	(t t)))

(defun day-nth (date)
  "Returns how many days into the year the given date is"
  (let ((month-list (if (leap-year-p (year date))
			leap-year-numbers
			common-year-numbers)))
    (+ (cond ((equal (month date) 1) 0)
	     ((equal (month date) 2) 31)
	     (t (loop for i from 0 to (- (month date) 2)
		 sum (second (nth i month-list)))))
       (day date))))

(defun each-first-of-january (start-year start-day-of-week end-year)
  "Start from an arbitrary monday january 1st, go up to a specified year, store a list of (year day-of-week)"
  (loop :with day-of-week := start-day-of-week
	:for year from start-year to end-year
	:collect (list year day-of-week) :into firsts
	:do (if (leap-year-p year)
		(setf day-of-week (day-cycle day-of-week 2))
		(setf day-of-week (day-cycle day-of-week 1)))
	:finally (return firsts)))

(defvar firsts-of-january (each-first-of-january 1900 1 2100))

(defun day-of-week (date)
  "Determines the day of the week for a given date."
  (let ((jan1 (second (assoc (year date) firsts-of-january))))
    (day-cycle jan1 (mod (- (day-nth date) 1) 7))))

(defun number-suffix (n)
  "Given a number, returns the English suffix (st, nd, th)."
  (let ((s (write-to-string n)))
    (cond ((> (length s) 2)
	   (number-suffix
	    (parse-integer
	     (subseq s (- (length s) 2) (length s)))))
	  ((member n '(11 12 13 14 15 16 17 18 19)) "th")
	  ((> (length s) 1)
	   (number-suffix
	    (parse-integer
	     (subseq s (- (length s) 1) (length s)))))
	  ((equal n 1) "st")
	  ((equal n 2) "nd")
	  ((equal n 3) "rd")
	  (t "th"))))
				   
(defun today ()
  "Returns today's date."
  (date (local-time:timestamp-month (local-time:now))
        (local-time:timestamp-day   (local-time:now))
	(local-time:timestamp-year  (local-time:now))))

;;;;------------------------------------------------------------------------
;;;;
;;;;------------------------------------------------------------------------

;Make calendar- cycle through all days in the month, use day of the week to plot them across a printout

;;;;------------------------------------------------------------------------
;;;;Time Calculations
;;;;------------------------------------------------------------------------

(defclass set-time ()
  ((hour    :initarg :hour
	    :accessor hour) ;;;stored in 24 hour system
   (minutes :initarg :minutes
	    :accessor minutes)))

(defmethod print-object ((obj set-time) stream)
  (print-unreadable-object (obj stream :type t)
    (with-accessors ((hour hour)
		     (minutes minutes))
	obj
      (format stream "~a:~a ~a"
	      (if (> hour 12) (- hour 12) hour)
	      (if (equal 1 (length (write-to-string minutes)))
		  (concatenate 'string "0" (write-to-string minutes))
		  minutes)
	      (if (> hour 12) "pm" "am")))))

(defun set-time (hour minutes)
  (make-instance 'set-time :hour hour
		           :minutes minutes))

(defun add-time (time minutes)
  "Adds a specified number of minutes to a given time."
  (cond ((zerop minutes) time)
	((and (equal (minutes time) 59)
	      (equal (hour time) 24))
	 (add-time (set-time 1 0) (- minutes 1)))
	((equal (minutes time) 59)
	 (add-time (set-time (+ 1 (hour time)) 0) (- minutes 1)))
	(t (add-time (set-time (hour time) (+ 1 (minutes time))) (- minutes 1)))))

(defun current-time ()
  "Returns the current time (Hours/Minutes)."
  (set-time (local-time:timestamp-hour (local-time:now))
	    (local-time:timestamp-minute (local-time:now))))

(defun later-time (time1 time2)
  "Returns the later of two times."
  (cond ((> (hour time1) (hour time2)) time1)
	((> (hour time2) (hour time1)) time2)
	((> (minutes time1) (minutes time2)) time1)
	((> (minutes time2) (minutes time1)) time2)
	(t time1)))

(defun equal-time (time1 time2)
  "Checks whether two times are equal."
  (and (equal (hour time1) (hour time2))
       (equal (minutes time1) (minutes time2))))