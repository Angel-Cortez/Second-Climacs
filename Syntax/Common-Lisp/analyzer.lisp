(cl:in-package #:climacs-syntax-common-lisp)

(defclass analyzer (folio-stream climacs2-base:analyzer)
  ())

;;; Return true if and only if position A occurs strictly before
;;; position B in some buffer.
(defun position-less (line-number-a item-number-a line-number-b item-number-b)
  (or (< line-number-a line-number-b)
      (and (= line-number-a line-number-b)
	   (< item-number-a item-number-b))))

;;; Return true if and only if the start position of PARSE-RESULT is
;;; strictly less than the position indicated by LINE-NUMBER and
;;; ITEM-NUMBER.
(defun parse-result-starts-before-position-p
    (parse-result line-number item-number)
  (position-less (start-line parse-result) (start-column parse-result)
		 line-number item-number))

;;; Make sure that the first parse result that we consider recycling
;;; starts at or beyond the current stream position.  Parse results
;;; that start before the current stream position are either no longer
;;; valid, or have been recycled already, so we remove them.  Two
;;; places are considered for recycling, namely the list of residual
;;; parse results and the suffix.
(defun pop-to-stream-position (analyzer)
  (let ((cache (folio analyzer))
	(line-number (current-line-number analyzer))
	(item-number (current-item-number analyzer)))
    (loop while (and (not (null (residue cache)))
		     (parse-result-starts-before-position-p
		      (first (residue cache)) line-number item-number))
	  do (pop-from-residue cache))
    (when (null (residue cache))
      (loop while (and (not (null (suffix cache)))
		       (parse-result-starts-before-position-p
			(first (suffix cache)) line-number item-number))
	    do (pop-from-suffix cache)))))

;;; Check whether there is a cached parse result with a start position
;;; that corresponds to the current stream position of ANALYZER, and
;;; if so, return that parse result.  If there is no such parse
;;; result, then return NIL.  If there are cached parse results that
;;; entirely precede the current stream position, then remove them.
(defun cached-parse-result (analyzer)
  (let ((cache (folio analyzer)))
    (with-accessors ((residue residue) (suffix suffix)) cache
      (loop while (and (not (null residue))
                       (or (< (start-line (first residue))
                              (current-line-number analyzer))
                           (and (= (start-line (first residue))
                                   (current-line-number analyzer))
                                (< (start-column (first residue))
                                   (current-item-number analyzer)))))
            do (pop-from-residue cache))
      (if (not (null residue))
          (if (and (= (start-line (first residue))
                      (current-line-number analyzer))
                   (= (start-column (first residue))
                      (current-item-number analyzer)))
              (first residue)
              nil)
          (progn
            (loop while (and (not (null suffix))
                             (or (< (start-line (first suffix))
                                    (current-line-number analyzer))
                                 (and (= (start-line (first suffix))
                                         (current-line-number analyzer))
                                      (< (start-column (first suffix))
                                         (current-item-number analyzer)))))
                  do (pop-from-suffix cache))
            (if (not (null suffix))
                (if (and (= (start-line (first suffix))
                            (current-line-number analyzer))
                         (= (start-column (first suffix))
                            (current-item-number analyzer)))
                    (first suffix)
                    nil)
                nil))))))

(defun advance-stream-to-beyond-parse-result (analyzer parse-result)
  (setf (current-line-number analyzer)
	(end-line parse-result))
  (setf (current-item-number analyzer)
	(end-column parse-result))
  (read-char analyzer nil nil))

;; (defmethod sicl-reader:read-common :around
;;     ((input-stream analyzer) eof-error-p eof-value)
;;   (skip-whitespace input-stream)
;;   (let ((parse-result (cached-parse-result input-stream)))
;;     (if (null parse-result)
;; 	(call-next-method)
;; 	(progn (push parse-result (first *stack*))
;; 	       (advance-stream-to-beyond-parse-result input-stream parse-result)
;; 	       (if (typep parse-result 'expression-parse-result)
;; 		   (expression parse-result)
;; 		   (sicl-reader:read-common input-stream eof-error-p eof-value))))))
