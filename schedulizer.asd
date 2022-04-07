;;;schedulizer.asd

(asdf:defsystem #:schedulizer
  :version "0.0.1"
  :author "Izaak Walton <izaakw@protonmail.com>"
  :license "GNU General Purpose License"
  :description "Scheduling System"
  :depends-on ("local-time")
  :serial t
  :components ((:file "package")
	       (:file "calendar")
	       (:file "contact")
	       (:file "editing-generics")
	       (:file "clients")
	       (:file "rooms")
	       (:file "employees")
	       (:file "appointments")
	       (:file "scheduling")
	       (:file "receipts")
	       (:file "invoices")
	       (:module "tests"
		:serial t
		:components ((:file "client-tests")
			     (:file "employee-tests")
			     (:file "appointment-tests")))));add makeups.lisp, printing.lisp,
					;maybe separate out date.lisp, time.lisp, calendar.lisp
                                        ;
;;;;make separate folder for client-tests, employee-tests, appointment-tests
