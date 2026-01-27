;Test very simple SVG with just a red rectangle
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defun main ()
	(print "Testing test_simple.svg (one red rectangle)...")
	(defq stream (file-stream "apps/media/images/data/test_simple.svg"))
	(if stream
		(progn
			(print "  File opened successfully")
			(bind '(w h type) (SVG-info stream))
			(print "  Dimensions from SVG-info: " w "x" h)
			(print "  Creating SVG-Canvas...")
			(defq canvas (SVG-Canvas stream 1))
			(print "  Canvas type: " (type-of canvas))
			(print "  Canvas value: " canvas)
			(if canvas
				(progn
					(bind '(cw ch) (. canvas :pref_size))
					(print "  Canvas size: " cw "x" ch)
					(print "  SUCCESS!"))
				(print "  FAILED: canvas is nil")))
		(print "  FAILED: file not found")))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
