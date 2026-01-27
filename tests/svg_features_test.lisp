;comprehensive SVG feature test suite
;tests SVG 1.1 features using existing test files
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defq *tests* 0 *passed* 0 *failed* 0)

(defun test-pass (name)
	(setq *tests* (inc *tests*) *passed* (inc *passed*))
	(print "  PASS: " name))

(defun test-fail (name reason)
	(setq *tests* (inc *tests*) *failed* (inc *failed*))
	(print "  FAIL: " name " - " reason))

(defun test-section (name)
	(print "")
	(print "=== " name " ==="))

;helper to test SVG file rendering
(defun test-svg-file (name path)
	(if (defq stream (file-stream path))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat name " (" (str w) "x" (str h) ")"))
					(test-fail name "invalid canvas size")))
			(test-fail name "SVG-Canvas returned nil"))
		(test-fail name "file not found")))

;helper to test SVG-info parsing
(defun test-svg-info (name path expected_w expected_h)
	(if (defq stream (file-stream path))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w expected_w) (= h expected_h))
				(test-pass (cat name " info (" (str w) "x" (str h) ")"))
				(test-fail name (cat "expected " (str expected_w) "x" (str expected_h) ", got " (str w) "x" (str h)))))
		(test-fail name "file not found")))

;test basic shapes - tiger.svg has all shape types
(defun test-shapes ()
	(test-section "Basic Shapes")
	(test-svg-file "tiger.svg (complex paths)" "apps/media/images/data/tiger.svg")
	(test-svg-file "burger.svg (groups/transforms)" "apps/media/images/data/burger.svg")
	(test-svg-file "chrysalisp.svg (polygons/paths)" "apps/media/images/data/chrysalisp.svg"))

;test path commands via arc_test.svg
(defun test-path-commands ()
	(test-section "Path Commands")
	(test-svg-info "arc_test.svg" "apps/media/images/data/arc_test.svg" 200.0 200.0)
	(test-svg-file "arc_test.svg (arc commands)" "apps/media/images/data/arc_test.svg")

	;test path-gen-svg-arc directly
	(defq test_path (path))
	(path-gen-svg-arc 0.0 0.0 50.0 50.0 0.0 0.0 1.0 100.0 0.0 test_path)
	(if (> (length test_path) 4)
		(test-pass "path-gen-svg-arc generates arc points")
		(test-fail "path-gen-svg-arc" "no points generated")))

;test color formats
(defun test-colors ()
	(test-section "Color Formats")
	(test-svg-info "colors_test.svg" "apps/media/images/data/colors_test.svg" 400.0 300.0)
	(test-svg-file "colors_test.svg (named colors)" "apps/media/images/data/colors_test.svg")
	(test-svg-info "color_formats_test.svg" "apps/media/images/data/color_formats_test.svg" 300.0 200.0)
	(test-svg-file "color_formats_test.svg (hex/rgb/hsl)" "apps/media/images/data/color_formats_test.svg"))

;test stroke properties
(defun test-stroke ()
	(test-section "Stroke Properties")
	(test-svg-info "dash_test.svg" "apps/media/images/data/dash_test.svg" 300.0 200.0)
	(test-svg-file "dash_test.svg (dasharray/linecap)" "apps/media/images/data/dash_test.svg"))

;test opacity
(defun test-opacity ()
	(test-section "Opacity")
	(test-svg-info "opacity_test.svg" "apps/media/images/data/opacity_test.svg" 400.0 200.0)
	(test-svg-file "opacity_test.svg (fill/stroke/group)" "apps/media/images/data/opacity_test.svg"))

;test visibility
(defun test-visibility ()
	(test-section "Visibility")
	(test-svg-info "visibility_test.svg" "apps/media/images/data/visibility_test.svg" 200.0 200.0)
	(test-svg-file "visibility_test.svg (hidden/visible)" "apps/media/images/data/visibility_test.svg"))

;test gradients
(defun test-gradients ()
	(test-section "Gradients")
	(test-svg-info "gradient_test.svg" "apps/media/images/data/gradient_test.svg" 400.0 300.0)
	(test-svg-file "gradient_test.svg (linear gradient)" "apps/media/images/data/gradient_test.svg")
	(test-svg-info "gradient_simple.svg" "apps/media/images/data/gradient_simple.svg" 400.0 200.0)
	(test-svg-file "gradient_simple.svg (simple linear)" "apps/media/images/data/gradient_simple.svg")
	(test-svg-info "radial_test.svg" "apps/media/images/data/radial_test.svg" 200.0 200.0)
	(test-svg-file "radial_test.svg (radial gradient)" "apps/media/images/data/radial_test.svg")
	(test-svg-info "radial_simple.svg" "apps/media/images/data/radial_simple.svg" 200.0 200.0)
	(test-svg-file "radial_simple.svg (simple radial)" "apps/media/images/data/radial_simple.svg"))

;test complex files
(defun test-complex ()
	(test-section "Complex Renderings")
	(test-svg-file "golfer.svg (detailed illustration)" "apps/media/images/data/golfer.svg")
	(test-svg-file "monroe.svg (portrait)" "apps/media/images/data/monroe.svg")
	(test-svg-file "kennedy.svg (portrait)" "apps/media/images/data/kennedy.svg")
	(test-svg-file "sticker.svg (multi-element)" "apps/media/images/data/sticker.svg"))

;main test runner
(defun main ()
	(print "")
	(print "================================================================================")
	(print "ChrysaLisp SVG 1.1 Feature Test Suite")
	(print "================================================================================")

	(test-shapes)
	(test-path-commands)
	(test-colors)
	(test-stroke)
	(test-opacity)
	(test-visibility)
	(test-gradients)
	(test-complex)

	(print "")
	(print "================================================================================")
	(print "Results: " *passed* "/" *tests* " passed, " *failed* " failed")
	(print "================================================================================")
	(if (= *failed* 0)
		(print "All tests PASSED!")
		(print "Some tests need attention"))
	(print ""))

(catch
	(main)
	(progn
		(print "")
		(print "FATAL ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
