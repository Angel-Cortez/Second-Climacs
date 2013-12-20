(cl:in-package #:climacs-syntax-common-lisp)

;;; As recommended by the HyperSpec, the backquote and comma reader
;;; macros generate a data structure that corresponds to the one used
;;; in Scheme, i.e. containing the forms (QUASIQUOTE <form>),
;;; (UNQUOTE <form>), and (UNQUOTE-SPLICING <form>).
;;;
;;; These forms are converted to standard Common Lisp forms
;;; containing APPEND, LIST, QUOTE, APPLY, and VECTOR. 
;;;
;;; Our implementation is an almost immediate translation of section
;;; 2.4.6 of the Hyperspec.  Where the HyperSpec uses brackets
;;; [FORM], we use (TRANSFORM FORM).  The other difference is that
;;; the HyperSpec converts a form such as `(x1 x2 ... xn . atom)
;;; directly to (append [x1] [x2] ... [xn] (quote atom)), whereas we
;;; do it in smaller steps so that (QUASIQUOTE (x1 x2 ... xn . atom))
;;; is transformed by only converting the first element of the list
;;; into (APPEND (TRANSFORM x1) (QUASIQUOTE (x2 ... xn . atom))).  
;;;
;;; Also, the HyperSpec says that when the backquote syntax is
;;; nested, the innermost occurence of backquote is transformed first
;;; so that the "first" comma belongs to the innermost backquote.  We
;;; implement this rule by making an explicit call to macroexpand of
;;; the innmermost occurence of QUASIQUOTE when we see an expression
;;; such as (QUASIQUOTE (QUASIQUOTE ...) ...), or an expression such
;;; as (TRANSFORM (QUASIQUOTE ...) ...), before we decide on the
;;; action to take for the outermost occurrence.

(defmacro transform (form)
  (if (consp form)
      (case (car form)
        (quasiquote
         `(transform ,(macroexpand-1 form)))
        (unquote
         `(list ,(cadr form)))
        (unquote-splicing
         (cadr form))
        (t
         `(list (quasiquote ,form))))
      `(list (quasiquote ,form))))

(defmacro quasiquote (form)
  (cond ((consp form)
         (case (car form)
           (unquote
            (cadr form))
           (unquote-splicing
            ;; Hmm.  This condition type is a subclass of
            ;; reader-error, which should be given a stream, but at
            ;; this point we no longer have the stream available.  
            (error 'undefined-use-of-backquote))
           (quasiquote
            `(quasiquote ,(macroexpand-1 form)))
           (t
            `(append (transform ,(car form)) (quasiquote ,(cdr form))))))
        ((vectorp form)
         `(apply #'vector (quasiquote ,(coerce form 'list))))
        (t
         `(quote ,form))))
