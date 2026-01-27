;SVG screenshot test - renders SVGs and saves to tests/screenshots/
;Run: ./run_tui.sh -n 1 -f -s tests/svg_screenshot_test.lisp
;
;Output: CPM files in tests/screenshots/
;Convert to PNG: python tests/screenshots/convert_to_png.py

(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defq *screenshots* 0 *failed* 0)
(defq *output_dir* "tests/screenshots/")

(defun save-screenshot (name path)
	; (save-screenshot name path) -> :t | :nil
	; Render SVG and save as CPM screenshot
	(print "Rendering: " name)
	(if (defq stream (file-stream path))
		(if (defq canvas (SVG-Canvas stream 1))
			(progn
				(bind '(w h) (. canvas :pref_size))
				(defq out_path (cat *output_dir* name ".cpm"))
				(if (. canvas :save out_path 32)
					(progn
						(setq *screenshots* (inc *screenshots*))
						(print "  Saved: " out_path " (" w "x" h ")")
						:t)
					(progn
						(setq *failed* (inc *failed*))
						(print "  FAILED: could not save " out_path)
						:nil)))
			(progn
				(setq *failed* (inc *failed*))
				(print "  FAILED: SVG-Canvas returned nil")
				:nil))
		(progn
			(setq *failed* (inc *failed*))
			(print "  FAILED: file not found")
			:nil)))

(defun main ()
	(print "")
	(print "================================================================================")
	(print "SVG Screenshot Test Suite")
	(print "================================================================================")
	(print "Output directory: " *output_dir*)
	(print "")

	;feature test files (all new SVGs from this commit)
	(print "=== Feature Tests ===")
	(save-screenshot "test_simple" "apps/media/images/data/test_simple.svg")
	(save-screenshot "arc_test" "apps/media/images/data/arc_test.svg")
	(save-screenshot "colors_test" "apps/media/images/data/colors_test.svg")
	(save-screenshot "color_formats_test" "apps/media/images/data/color_formats_test.svg")
	(save-screenshot "dash_test" "apps/media/images/data/dash_test.svg")
	(save-screenshot "opacity_test" "apps/media/images/data/opacity_test.svg")
	(save-screenshot "visibility_test" "apps/media/images/data/visibility_test.svg")
	(save-screenshot "clippath_test" "apps/media/images/data/clippath_test.svg")

	;gradient tests
	(print "")
	(print "=== Gradient Tests ===")
	(save-screenshot "gradient_test" "apps/media/images/data/gradient_test.svg")
	(save-screenshot "gradient_simple" "apps/media/images/data/gradient_simple.svg")
	(save-screenshot "radial_test" "apps/media/images/data/radial_test.svg")
	(save-screenshot "radial_simple" "apps/media/images/data/radial_simple.svg")

	;complex production files
	(print "")
	(print "=== Production SVGs ===")
	(save-screenshot "tiger" "apps/media/images/data/tiger.svg")
	(save-screenshot "burger" "apps/media/images/data/burger.svg")
	(save-screenshot "chrysalisp" "apps/media/images/data/chrysalisp.svg")
	(save-screenshot "golfer" "apps/media/images/data/golfer.svg")
	(save-screenshot "monroe" "apps/media/images/data/monroe.svg")
	(save-screenshot "kennedy" "apps/media/images/data/kennedy.svg")
	(save-screenshot "sticker" "apps/media/images/data/sticker.svg")

	(print "")
	(print "================================================================================")
	(print "Screenshots: " *screenshots* " saved, " *failed* " failed")
	(print "================================================================================")
	(if (= *failed* 0)
		(print "All screenshots captured!")
		(print "Some screenshots failed!"))
	(print "")
	(print "To convert to PNG, run:")
	(print "  python tests/screenshots/convert_to_png.py"))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
