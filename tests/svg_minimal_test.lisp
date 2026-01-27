;minimal SVG test to isolate issues
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defun main ()
	(print "Test 1: gradient_test.svg")

	;test SVG-info (uses fresh stream)
	(if (defq stream (file-stream "apps/media/images/data/gradient_test.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(print "  SVG-info dimensions: " w "x" h))
		(print "  ERROR: could not open file for SVG-info"))

	;test SVG-Canvas (uses fresh stream - streams are consumed after use)
	(if (defq stream (file-stream "apps/media/images/data/gradient_test.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(print "  Canvas result: " canvas)
				(bind '(cw ch) (. canvas :pref_size))
				(print "  Canvas dimensions: " cw "x" ch))
			(print "  ERROR: SVG-Canvas returned nil"))
		(print "  ERROR: could not open file for SVG-Canvas"))

	(print "")
	(print "Test 2: arc_test.svg")

	;test SVG-info
	(if (defq stream (file-stream "apps/media/images/data/arc_test.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(print "  SVG-info dimensions: " w "x" h))
		(print "  ERROR: could not open file for SVG-info"))

	;test SVG-Canvas
	(if (defq stream (file-stream "apps/media/images/data/arc_test.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(print "  Canvas result: " canvas)
				(bind '(cw ch) (. canvas :pref_size))
				(print "  Canvas dimensions: " cw "x" ch))
			(print "  ERROR: SVG-Canvas returned nil"))
		(print "  ERROR: could not open file for SVG-Canvas"))

	(print "")
	(print "All tests completed!"))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
