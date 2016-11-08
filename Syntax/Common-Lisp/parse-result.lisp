(cl:in-package #:climacs-syntax-common-lisp)

(defclass parse-result ()
  ((%start-line :initarg :start-line :accessor start-line)
   (%end-line :initarg :end-line :accessor end-line)
   (%start-column :initarg :start-column :accessor start-column)
   (%end-column :initarg :end-column :accessor end-column)
   ;; This slot contains TRUE if and only if the START-LINE slot is
   ;; relative to some other line.
   (%relative-p :initarg :relative-p :accessor relative-p)
   (%children :initarg :children :accessor children)))

(defclass expression-parse-result (parse-result)
  ((%expression :initarg :expression :accessor expression)))

(defclass no-expression-parse-result (parse-result)
  ())

(defclass error-parse-result (parse-result)
  ())

(defclass eof-parse-result (parse-result)
  ())

(defgeneric relative-to-absolute (parse-result offset)
  (:method ((p parse-result) offset)
    (assert (relative-p p))
    (incf (start-line p) offset)
    (setf (relative-p p) nil)))
