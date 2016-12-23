(cl:in-package #:common-lisp-user)

(defpackage #:second-climacs-base
  (:nicknames #:climacs2-base)
  (:use #:common-lisp)
  (:export #:buffer
	   #:standard-buffer
	   #:analyzer
	   #:update-analyzer-from-buffer
	   #:update-analyzer
	   #:view))
