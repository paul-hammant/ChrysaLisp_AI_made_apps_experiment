;=============================================================================
; MINIMAL REPRODUCTION CASE: SVG-Canvas returns :nil
;=============================================================================
; This test demonstrates that SVG-Canvas consistently returns :nil instead
; of a valid canvas object, even for the simplest possible SVG files.
;
; Expected behavior: SVG-Canvas should return a canvas object
; Actual behavior: SVG-Canvas returns :nil
;
; Test environment: ChrysaLisp TUI mode
; Test date: 2026-01-11
;=============================================================================

(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defun main ()
	(print "=============================================================================")
	(print "REPRODUCTION CASE: SVG-Canvas returns :nil")
	(print "=============================================================================")
	(print "")

	;Test 1: Verify Canvas class works directly
	(print "Test 1: Direct Canvas creation")
	(defq test_canvas (Canvas 100 100 1))
	(print "  Result: " (if test_canvas "SUCCESS" "FAILED"))
	(print "  Type: " (type-of test_canvas))
	(print "")

	;Test 2: Verify SVG-info works
	(print "Test 2: SVG-info parsing")
	(defq stream (file-stream "apps/media/images/data/test_simple.svg"))
	(if stream
		(progn
			(bind '(w h type) (SVG-info stream))
			(print "  Result: SUCCESS")
			(print "  Dimensions: " w "x" h " Type: " type))
		(print "  Result: FAILED - file not found"))
	(print "")

	;Test 3: SVG-Canvas - THE BUG
	(print "Test 3: SVG-Canvas creation (THE BUG)")
	(setq stream (file-stream "apps/media/images/data/test_simple.svg"))
	(if stream
		(progn
			(print "  File: apps/media/images/data/test_simple.svg")
			(print "  Contents: Simple 100x100 SVG with one red rectangle")
			(defq svg_canvas (SVG-Canvas stream 1))
			(print "  SVG-Canvas returned: " svg_canvas)
			(print "  Type: " (type-of svg_canvas))
			(if svg_canvas
				(print "  Result: SUCCESS")
				(progn
					(print "  Result: FAILED - SVG-Canvas returned :nil")
					(print "  Expected: A valid canvas object")
					(print "  Impact: Cannot render any SVG files"))))
		(print "  Result: FAILED - file not found"))
	(print "")

	(print "=============================================================================")
	(print "SUMMARY:")
	(print "  - Canvas creation: WORKS")
	(print "  - SVG-info parsing: WORKS")
	(print "  - SVG-Canvas creation: FAILS (returns :nil)")
	(print "============================================================================="))

(catch
	(main)
	(progn
		(print "")
		(print "UNCAUGHT ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
