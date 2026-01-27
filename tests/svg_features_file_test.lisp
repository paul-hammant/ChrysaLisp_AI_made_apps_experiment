;Comprehensive SVG feature test suite using files
;Tests each SVG 1.1 feature systematically
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defq *tests* 0 *passed* 0 *failed* 0)

(defun test-result (name passed reason)
	(setq *tests* (inc *tests*))
	(if passed
		(progn
			(setq *passed* (inc *passed*))
			(print "  ✓ " name))
		(progn
			(setq *failed* (inc *failed*))
			(print "  ✗ " name " - " reason))))

(defun test-section (name)
	(print "")
	(print "=== " name " ==="))

(defun test-svg-file (path expected-w expected-h feature-name)
	;Test SVG-info
	(defq stream (file-stream path))
	(if stream
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w expected-w) (= h expected-h))
				(progn
					;Test SVG-Canvas
					(setq stream (file-stream path))
					(defq canvas (SVG-Canvas stream 1))
					(test-result feature-name canvas (cat "canvas is nil for " path)))
				(test-result feature-name :nil (cat "wrong dimensions for " path))))
		(test-result feature-name :nil (cat "file not found: " path))))

;Test our new SVG test files
(defun test-new-features ()
	(test-section "New Feature Test Files")

	;Arc commands
	(test-svg-file "apps/media/images/data/arc_test.svg" 200.0 200.0 "arc_test.svg")

	;Named colors
	(test-svg-file "apps/media/images/data/colors_test.svg" 400.0 300.0 "colors_test.svg")

	;Color formats (rgb, rgba, hsl, hsla)
	(test-svg-file "apps/media/images/data/color_formats_test.svg" 300.0 200.0 "color_formats_test.svg")

	;Stroke dasharray
	(test-svg-file "apps/media/images/data/dash_test.svg" 300.0 200.0 "dash_test.svg")

	;Opacity
	(test-svg-file "apps/media/images/data/opacity_test.svg" 400.0 200.0 "opacity_test.svg")

	;Visibility
	(test-svg-file "apps/media/images/data/visibility_test.svg" 200.0 200.0 "visibility_test.svg")

	;ClipPath
	(test-svg-file "apps/media/images/data/clippath_test.svg" 200.0 200.0 "clippath_test.svg")

	;Simple gradient (no text)
	(test-svg-file "apps/media/images/data/gradient_simple.svg" 400.0 200.0 "gradient_simple.svg")

	;Simple radial (no text)
	(test-svg-file "apps/media/images/data/radial_simple.svg" 200.0 200.0 "radial_simple.svg")

	;NOTE: gradient_test.svg and radial_test.svg contain <text> elements
	;which fail in TUI mode (no create-font). These are skipped for now.

	;Our simple test
	(test-svg-file "apps/media/images/data/test_simple.svg" 100.0 100.0 "test_simple.svg (basic rect)"))

;Main test runner
(defun main ()
	(print "")
	(print "================================================================================")
	(print "ChrysaLisp SVG Feature Test Suite (File-based)")
	(print "================================================================================")

	(test-new-features)

	(print "")
	(print "================================================================================")
	(print "Results: " *passed* "/" *tests* " tests passed, " *failed* " failed")
	(print "================================================================================")
	(if (= *failed* 0)
		(print "SUCCESS: All tests passed!")
		(print "FAILURES: " *failed* " test(s) need attention"))
	(print ""))

(catch
	(main)
	(progn
		(print "")
		(print "FATAL ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
