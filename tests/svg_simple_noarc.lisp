;Test simple SVG without arc commands to isolate the issue
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defun main ()
	(print "Testing colors_test.svg (no arcs, no text)...")
	(defq stream (file-stream "apps/media/images/data/colors_test.svg"))
	(if stream
		(progn
			(bind '(w h type) (SVG-info stream))
			(print "  Dimensions: " w "x" h)
			(defq canvas (SVG-Canvas stream 1))
			(if canvas
				(progn
					(bind '(cw ch) (. canvas :pref_size))
					(print "  Canvas created: " cw "x" ch)
					(print "  SUCCESS!"))
				(print "  FAILED: canvas is nil")))
		(print "  FAILED: file not found"))

	(print "")
	(print "Testing arc_test.svg (contains arc commands)...")
	(setq stream (file-stream "apps/media/images/data/arc_test.svg"))
	(if stream
		(progn
			(bind '(w h type) (SVG-info stream))
			(print "  Dimensions: " w "x" h)
			(setq canvas (SVG-Canvas stream 1))
			(if canvas
				(progn
					(bind '(cw ch) (. canvas :pref_size))
					(print "  Canvas created: " cw "x" ch)
					(print "  SUCCESS!"))
				(print "  FAILED: canvas is nil - arc commands not implemented in SVG parser")))
		(print "  FAILED: file not found")))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
