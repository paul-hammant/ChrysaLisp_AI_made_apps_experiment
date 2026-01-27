;Test a single SVG file
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")
(import "lib/xml/svg.inc")

(print "Testing tiger.svg...")
(defq stream (file-stream "apps/media/images/data/tiger.svg"))
(if stream
  (progn
    (print "  Stream created, calling SVG-Canvas...")
    (defq canvas (SVG-Canvas stream 1))
    (if canvas
      (progn
        (defq size (. canvas :pref_size))
        (print (cat "  SUCCESS: " (first size) "x" (second size))))
      (print "  FAILED: canvas is nil")))
  (print "  FAILED: file not found"))
(print "Done")

;clean shutdown
((ffi "service/gui/lisp_deinit"))
