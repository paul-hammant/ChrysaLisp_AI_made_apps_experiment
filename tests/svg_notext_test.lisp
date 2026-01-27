;test SVG files with no text elements
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defq *tests* 0 *passed* 0)

(defun test-svg-file (path)
	(print "")
	(print "Testing: " path)
	(setq *tests* (inc *tests*))

	;test SVG-info with fresh stream
	(if (defq stream (file-stream path))
		(progn
			(bind '(w h type) (SVG-info stream))
			(print "  SVG-info: " w "x" h))
		(progn
			(print "  FAILED: file not found")
			(setq *tests* (dec *tests*))))

	;test SVG-Canvas with fresh stream (streams are consumed after use)
	(if (defq stream (file-stream path))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(cw ch) (. canvas :pref_size))
				(print "  Canvas: " cw "x" ch)
				(setq *passed* (inc *passed*))
				(print "  PASSED"))
			(print "  FAILED: SVG-Canvas returned nil"))
		(print "  FAILED: could not reopen file")))

(defun main ()
	(print "SVG Test Suite - Files without text elements")
	(print "=============================================")

	;test arc functionality
	(test-svg-file "apps/media/images/data/arc_test.svg")

	;test named colors
	(test-svg-file "apps/media/images/data/colors_test.svg")

	;test color format parsing
	(test-svg-file "apps/media/images/data/color_formats_test.svg")

	;test stroke dasharray
	(test-svg-file "apps/media/images/data/dash_test.svg")

	;test opacity
	(test-svg-file "apps/media/images/data/opacity_test.svg")

	;test visibility
	(test-svg-file "apps/media/images/data/visibility_test.svg")

	;test gradients
	(test-svg-file "apps/media/images/data/gradient_test.svg")
	(test-svg-file "apps/media/images/data/gradient_simple.svg")
	(test-svg-file "apps/media/images/data/radial_test.svg")
	(test-svg-file "apps/media/images/data/radial_simple.svg")

	(print "")
	(print "=============================================")
	(print "Results: " *passed* "/" *tests* " passed")
	(print "=============================================")
	(if (= *passed* *tests*)
		(print "All tests PASSED!")
		(print "Some tests FAILED!")))

(catch
	(main)
	(progn
		(print "")
		(print "TEST SUITE ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
