;Check if SVG-Canvas actually works and what it returns
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defun main ()
	(print "Checking SVG-Canvas behavior...")
	(print "")

	;Create test SVG
	(defq stream (file-stream "apps/media/images/data/test_simple.svg"))
	(bind '(w h type) (SVG-info stream))
	(print "SVG dimensions: " w "x" h)
	(print "")

	(print "Calling SVG-Canvas...")
	(setq stream (file-stream "apps/media/images/data/test_simple.svg"))
	(defq canvas (SVG-Canvas stream 1))
	(print "SVG-Canvas returned: " canvas)
	(print "Type: " (type-of canvas))
	(print "")

	(print "Trying to call :pref_size on canvas...")
	(defq result (. canvas :pref_size))
	(print "pref_size returned: " result)
	(print "Result type: " (type-of result))
	(bind '(cw ch) result)
	(print "Canvas dimensions: " cw "x" ch)

	(print "")
	(print "Test complete!"))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR CAUGHT: " _)
		(print "Error type: " (type-of _))
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
