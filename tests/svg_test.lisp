;SVG test suite - tests SVG parsing functionality
;Some tests require full GUI mode and are skipped in TUI mode
(import "lib/task/pipe.inc")
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

;test counter
(defq *test_count* 0 *pass_count* 0)

(defun test-pass (name)
	(setq *test_count* (inc *test_count*) *pass_count* (inc *pass_count*))
	(print "  PASS: " name))

(defun test-fail (name reason)
	(setq *test_count* (inc *test_count*))
	(print "  FAIL: " name " - " reason))

(defun test-section (name)
	(print "")
	(print "=== " name " ==="))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Test SVG-info with existing SVG files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun test-svg-info ()
	(test-section "SVG-info Tests")

	;test tiger.svg
	(if (defq stream (file-stream "apps/media/images/data/tiger.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (> w 0) (> h 0))
				(test-pass "tiger.svg info")
				(test-fail "tiger.svg info" "invalid dimensions")))
		(test-fail "tiger.svg info" "file not found"))

	;test clock.svg
	(if (defq stream (file-stream "apps/media/images/data/clock.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w 300.0) (= h 300.0))
				(test-pass "clock.svg info (300x300)")
				(test-fail "clock.svg info" (cat "expected 300x300, got " (str w) "x" (str h)))))
		(test-fail "clock.svg info" "file not found"))

	;test burger.svg with viewBox
	(if (defq stream (file-stream "apps/media/images/data/burger.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w 332.0) (= h 263.0))
				(test-pass "burger.svg info (332x263 from viewBox)")
				(test-fail "burger.svg info" (cat "expected 332x263, got " (str w) "x" (str h)))))
		(test-fail "burger.svg info" "file not found"))

	;test dial.svg
	(if (defq stream (file-stream "apps/media/images/data/dial.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (> w 0) (> h 0))
				(test-pass (cat "dial.svg info (" (str w) "x" (str h) ")"))
				(test-fail "dial.svg info" "invalid dimensions")))
		(test-fail "dial.svg info" "file not found"))

	;test chrysalisp.svg
	(if (defq stream (file-stream "apps/media/images/data/chrysalisp.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (> w 0) (> h 0))
				(test-pass (cat "chrysalisp.svg info (" (str w) "x" (str h) ")"))
				(test-fail "chrysalisp.svg info" "invalid dimensions")))
		(test-fail "chrysalisp.svg info" "file not found"))

	;test non-existent file
	(if (not (file-stream "nonexistent.svg"))
		(test-pass "non-existent file returns nil stream")
		(test-fail "non-existent file" "should return nil")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Test all SVG file info in data directory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun test-all-svg-info ()
	(test-section "All SVG File Info in apps/media/images/data")

	(defq files (split (pii-dirlist "apps/media/images/data") (ascii-char 10)))
	(each! (lambda (file)
		(when (ends-with ".svg" file)
			(defq path (cat "apps/media/images/data/" file))
			(if (defq stream (file-stream path))
				(progn
					(bind '(w h type) (SVG-info stream))
					(if (and (> w 0) (> h 0))
						(test-pass (cat path " (" (str w) "x" (str h) ")"))
						(test-fail path "invalid dimensions")))
				(test-fail path "file not found"))))
		(list files)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Test SVG-Canvas rendering (SVGs without text only)
; Note: SVGs with text elements require font loading
; which needs full GUI mode to work properly
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun test-svg-dash ()
	(test-section "SVG Stroke Dasharray Tests")

	;test dash_test.svg parsing
	(if (defq stream (file-stream "apps/media/images/data/dash_test.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w 300.0) (= h 200.0))
				(test-pass "dash_test.svg info (300x200)")
				(test-fail "dash_test.svg info" (cat "expected 300x200, got " (str w) "x" (str h)))))
		(test-fail "dash_test.svg info" "file not found"))

	;test dash_test.svg canvas rendering
	(if (defq stream (file-stream "apps/media/images/data/dash_test.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "dash_test.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "dash_test.svg canvas" "invalid size")))
			(test-fail "dash_test.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "dash_test.svg canvas" "file not found")))

(defun test-svg-colors ()
	(test-section "SVG Named Colors Tests")

	;test colors_test.svg parsing
	(if (defq stream (file-stream "apps/media/images/data/colors_test.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w 400.0) (= h 300.0))
				(test-pass "colors_test.svg info (400x300)")
				(test-fail "colors_test.svg info" (cat "expected 400x300, got " (str w) "x" (str h)))))
		(test-fail "colors_test.svg info" "file not found"))

	;test colors_test.svg canvas rendering
	(if (defq stream (file-stream "apps/media/images/data/colors_test.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "colors_test.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "colors_test.svg canvas" "invalid size")))
			(test-fail "colors_test.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "colors_test.svg canvas" "file not found")))

(defun test-svg-arc ()
	(test-section "SVG Arc Command Tests")

	;test arc_test.svg parsing
	(if (defq stream (file-stream "apps/media/images/data/arc_test.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w 200.0) (= h 200.0))
				(test-pass "arc_test.svg info (200x200)")
				(test-fail "arc_test.svg info" (cat "expected 200x200, got " (str w) "x" (str h)))))
		(test-fail "arc_test.svg info" "file not found"))

	;test arc_test.svg canvas rendering
	(if (defq stream (file-stream "apps/media/images/data/arc_test.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "arc_test.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "arc_test.svg canvas" "invalid size")))
			(test-fail "arc_test.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "arc_test.svg canvas" "file not found"))

	;test path-gen-svg-arc directly with simple arc
	(defq test_path (path))
	(path-gen-svg-arc 0.0 0.0 50.0 50.0 0.0 0.0 1.0 100.0 0.0 test_path)
	(if (> (length test_path) 4)
		(test-pass "path-gen-svg-arc generates points")
		(test-fail "path-gen-svg-arc" "no points generated")))

(defun test-svg-gradient ()
	(test-section "SVG LinearGradient Tests")

	;test gradient_test.svg parsing
	(if (defq stream (file-stream "apps/media/images/data/gradient_test.svg"))
		(progn
			(bind '(w h type) (SVG-info stream))
			(if (and (= w 400.0) (= h 300.0))
				(test-pass "gradient_test.svg info (400x300)")
				(test-fail "gradient_test.svg info" (cat "expected 400x300, got " (str w) "x" (str h)))))
		(test-fail "gradient_test.svg info" "file not found"))

	;test gradient_test.svg canvas rendering (uses center color approximation)
	(if (defq stream (file-stream "apps/media/images/data/gradient_test.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "gradient_test.svg canvas (renders with center colors)"))
					(test-fail "gradient_test.svg canvas" "invalid size")))
			(test-fail "gradient_test.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "gradient_test.svg canvas" "file not found")))

(defun test-svg-canvas-simple ()
	(test-section "SVG-Canvas Rendering (no-text SVGs)")

	;test rendering tiger.svg (complex paths, no text)
	(if (defq stream (file-stream "apps/media/images/data/tiger.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "tiger.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "tiger.svg canvas" "invalid size")))
			(test-fail "tiger.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "tiger.svg canvas" "file not found"))

	;test rendering burger.svg (groups, transforms, no text)
	(if (defq stream (file-stream "apps/media/images/data/burger.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "burger.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "burger.svg canvas" "invalid size")))
			(test-fail "burger.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "burger.svg canvas" "file not found"))

	;test rendering chrysalisp.svg (no text)
	(if (defq stream (file-stream "apps/media/images/data/chrysalisp.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "chrysalisp.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "chrysalisp.svg canvas" "invalid size")))
			(test-fail "chrysalisp.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "chrysalisp.svg canvas" "file not found"))

	;test rendering golfer.svg (no text)
	(if (defq stream (file-stream "apps/media/images/data/golfer.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "golfer.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "golfer.svg canvas" "invalid size")))
			(test-fail "golfer.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "golfer.svg canvas" "file not found"))

	;test rendering monroe.svg (no text)
	(if (defq stream (file-stream "apps/media/images/data/monroe.svg"))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (and (> w 0) (> h 0))
					(test-pass (cat "monroe.svg canvas (" (str w) "x" (str h) ")"))
					(test-fail "monroe.svg canvas" "invalid size")))
			(test-fail "monroe.svg canvas" "SVG-Canvas returned nil"))
		(test-fail "monroe.svg canvas" "file not found")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main test runner
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun run-all-tests ()
	(print "")
	(print "======================================")
	(print "ChrysaLisp SVG Test Suite")
	(print "======================================")

	(test-svg-info)
	(test-all-svg-info)
	(test-svg-dash)
	(test-svg-colors)
	(test-svg-arc)
	(test-svg-gradient)
	(test-svg-canvas-simple)

	(print "")
	(print "======================================")
	(print "Test Results: " *pass_count* "/" *test_count* " passed")
	(print "======================================")

	(if (= *pass_count* *test_count*)
		(print "All tests PASSED!")
		(print "Some tests FAILED!"))

	(= *pass_count* *test_count*))

;run tests with error handling
(catch
	(unless (run-all-tests)
		(throw "Some SVG tests failed!" :nil))
	(progn
		(print "")
		(print "Test suite error: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
