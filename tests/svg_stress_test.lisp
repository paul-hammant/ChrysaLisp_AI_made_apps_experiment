;SVG stress test - try to trigger segfault
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defun test-file (path)
	(print "Testing: " path)
	(if (defq stream (file-stream path))
		(progn
			(print "  Reading SVG-info...")
			(bind '(w h type) (SVG-info stream))
			(print "  Dimensions: " w "x" h)
			(print "  Creating SVG-Canvas...")
			;re-open stream for SVG-Canvas (SVG-info consumed the first one)
			(setq stream (file-stream path))
			(if (defq canvas (SVG-Canvas stream 1))
				(progn
					(bind '(cw ch) (. canvas :pref_size))
					(print "  Canvas size: " cw "x" ch)
					(print "  SUCCESS!"))
				(print "  FAILED: SVG-Canvas returned nil")))
		(print "  FAILED: file not found")))

(defun main ()
	;test gradient files (most likely to cause issues)
	(test-file "apps/media/images/data/gradient_test.svg")
	(test-file "apps/media/images/data/gradient_simple.svg")
	(test-file "apps/media/images/data/radial_test.svg")
	(test-file "apps/media/images/data/radial_simple.svg")

	;test other new features
	(test-file "apps/media/images/data/arc_test.svg")
	(test-file "apps/media/images/data/colors_test.svg")
	(test-file "apps/media/images/data/color_formats_test.svg")
	(test-file "apps/media/images/data/dash_test.svg")
	(test-file "apps/media/images/data/opacity_test.svg")
	(test-file "apps/media/images/data/visibility_test.svg")
	(test-file "apps/media/images/data/clippath_test.svg")

	(print "")
	(print "All tests completed without crash!"))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
