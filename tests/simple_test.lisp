;Simple test to verify ChrysaLisp is working
(defun test-basic ()
    (print "ChrysaLisp is running!")
    (print "Testing basic arithmetic:")
    (print "2 + 2 =" (+ 2 2))
    (print "10 * 5 =" (* 10 5))
    (print "Success!"))

(catch
    (test-basic)
    (progn
        (print "Test failed with error:" _)
        :t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
