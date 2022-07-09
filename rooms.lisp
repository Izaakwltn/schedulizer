;;;; rooms.lisp
;;;;
;;;; Copyright Izaak Walton (c) 2022

(in-package :bartleby)

;;; Room Class

(mito:deftable meeting-room ()
  ((num  :col-type (:int))
   (name :col-type (:varchar 64))
   (capacity  :col-type (:int))
   (notes     :col-type (:varchar 128)))
  (:conc-name room-))

(mito:ensure-table-exists 'meeting-room)

(defmethod print-object ((obj meeting-room) stream)
  (print-unreadable-object (obj stream :type t)
    (with-accessors ((room-num room-num)
		     (room-name room-name)
		     (room-capacity room-capacity)
		     (room-notes room-notes))
	obj
      (format stream "~%Room ~a, ~a~%Capacity: ~a~%Notes: ~a~%"
	      room-num
	      room-name
	      room-capacity
	      room-notes))))

(defun make-room (room-num room-name capacity notes)
  (make-instance 'meeting-room :id        room-num
		               :room-name room-name
			       :capacity  capacity
		               :notes     notes))

;;; Adding and removing rooms

(defmethod add-room ((meeting-room meeting-room))
  "Adds a meeting room to *rooms*"
  (mito:insert-dao meeting-room))
  
(defmethod remove-room ((meeting-room meeting-room))
  "Removes a room from *rooms*"
  (mito:delete-dao meeting-room))

(defmethod replace-room ((meeting-room meeting-room) new-meeting-room)
  "Removes room, adds a replacement room."
  (remove-room meeting-room)
  (add-room new-meeting-room))

;;; Editing one attribute at a time

(defmethod change-num ((meeting-room meeting-room) new-number)
  (setf (slot-value meeting-room 'num) new-number)
  (mito:save-dao meeting-room))

(defmethod change-name ((meeting-room meeting-room) new-name)
  (setf (slot-value meeting-room 'name) new-name)
  (mito:save-dao meeting-room))

(defmethod change-capacity ((meeting-room meeting-room) new-capacity)
  (setf (slot-value meeting-room 'capacity) new-capacity)
  (mito:save-dao meeting-room))

(defmethod change-notes((meeting-room meeting-room) new-notes)
  (setf (slot-value meeting-room 'notes) new-notes)
  (mito:save-dao meeting-room))

;;;;------------------------------------------------------------------------
;;;;Searching for rooms
;;;;------------------------------------------------------------------------

;(defun room-search (room-num)
 ; "Searches for rooms by room number."
  ;(loop :for r :in *rooms*
;;	:if (equal room-num (id r))
;	  :do (return r)))


;;; Room tests

(defvar *room-names* '("The Library" "Room with the Broken Chair""Guitar Room" "The Chokey" "The Kitchen" "The room where everything works" "The room where nothing works"))

(defun random-room (room-names)
  (nth (random (length room-names)) room-names))

(defun generate-rooms (number-of-rooms)
  (loop :for i :from 1 :to number-of-rooms
	:do (new-room (random-room *room-names*) (random 10) "")))
		       
				      
