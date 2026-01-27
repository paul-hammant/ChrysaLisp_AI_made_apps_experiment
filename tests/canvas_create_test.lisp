;Test if Canvas can be created in TUI mode
(import "gui/canvas/lisp.inc")

(defun main ()
	(print "Testing Canvas creation in TUI mode...")
	(print "Creating Canvas 100x100 with scale 1...")
	(defq canvas (Canvas 100 100 1))
	(print "Canvas type: " (type-of canvas))
	(print "Canvas value: " canvas)
	(if canvas
		(print "SUCCESS: Canvas created!")
		(print "FAILED: Canvas is nil")))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
