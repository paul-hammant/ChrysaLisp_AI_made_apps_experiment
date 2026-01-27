;SVG to CPM renderer for image-diff testing
;Template script - modify INPUT_SVG and OUTPUT_CPM before running
;Usage: ./run_tui.sh -n 1 -f -s tests/image_diff/render_svg.lisp
;
;The Python test runner (run_image_diff.py) generates custom versions
;of this script with specific paths for each test.

(import "gui/lisp.inc")

;MODIFY THESE FOR YOUR TEST:
(defq INPUT_SVG "apps/images/data/arc_test.svg")
(defq OUTPUT_CPM "tests/image_diff/output/test.cpm")

(defun main ()
	(if (defq stream (file-stream INPUT_SVG))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(if (. canvas :save OUTPUT_CPM 32)
					(print "OK " INPUT_SVG " -> " OUTPUT_CPM " (" w "x" h ")")
					(print "ERROR: Failed to save " OUTPUT_CPM)))
			(print "ERROR: Failed to render " INPUT_SVG))
		(print "ERROR: Cannot open " INPUT_SVG)))

(catch
	(main)
	(print "ERROR: " _))

((ffi "service/gui/lisp_deinit"))
