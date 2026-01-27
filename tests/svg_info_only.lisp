;Just test SVG-info, no canvas creation
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(defun main ()
	(print "Testing SVG-info only (no canvas creation)...")

	(defq files '("colors_test.svg" "arc_test.svg" "dash_test.svg" "opacity_test.svg"))

	(each! (lambda (file)
		(defq path (cat "apps/media/images/data/" file))
		(print "")
		(print "File: " file)
		(if (defq stream (file-stream path))
			(progn
				(bind '(w h type) (SVG-info stream))
				(print "  Dimensions: " w "x" h " type: " type)
				(print "  SUCCESS!"))
			(print "  FAILED: file not found")))
		(list files))

	(print "")
	(print "All SVG-info tests completed!"))

(catch
	(main)
	(progn
		(print "")
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
