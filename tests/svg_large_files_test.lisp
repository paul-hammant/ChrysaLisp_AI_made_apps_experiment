;Test larger production SVG files
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
      (print (cat "  ✓ " name)))
    (progn
      (setq *failed* (inc *failed*))
      (print (cat "  ✗ " name ": " reason)))))

(defun test-svg-file (path expected-min-w expected-min-h name)
  ;Test that an SVG file loads and creates a canvas of reasonable size
  (if (file-stream path)
    (progn
      (defq stream (file-stream path)
            canvas (SVG-Canvas stream 1))
      (if canvas
        (progn
          (defq size (. canvas :pref_size)
                w (n2f (first size))
                h (n2f (second size)))
          (if (and (>= w expected-min-w) (>= h expected-min-h))
            (test-result name :t :nil)
            (test-result name :nil (cat "Size too small: " (str w) "x" (str h)))))
        (test-result name :nil "canvas is nil")))
    (test-result name :nil (cat "file not found: " path))))

(print "================================================================================")
(print "ChrysaLisp Large SVG Files Test Suite")
(print "================================================================================")
(print "")
(print "=== Production SVG Files ===")

;Test larger production files
(test-svg-file "apps/media/images/data/tiger.svg" 100.0 100.0 "tiger.svg")
(test-svg-file "apps/media/images/data/burger.svg" 50.0 50.0 "burger.svg")
(test-svg-file "apps/media/images/data/monroe.svg" 50.0 50.0 "monroe.svg")
(test-svg-file "apps/media/images/data/golfer.svg" 50.0 50.0 "golfer.svg")
(test-svg-file "apps/media/images/data/chrysalisp.svg" 50.0 50.0 "chrysalisp.svg")
(test-svg-file "apps/media/images/data/sticker.svg" 50.0 50.0 "sticker.svg")
(test-svg-file "apps/media/images/data/dial.svg" 50.0 50.0 "dial.svg")
(test-svg-file "apps/media/images/data/kennedy.svg" 50.0 50.0 "kennedy.svg")
(test-svg-file "apps/media/images/data/clock.svg" 50.0 50.0 "clock.svg")

(print "")
(print "================================================================================")
(print (cat "Results: " (str *passed*) "/" (str *tests*) " tests passed, " (str *failed*) " failed"))
(print "================================================================================")
(if (= *failed* 0)
  (print "SUCCESS: All tests passed!")
  (print "FAILURE: Some tests failed"))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
