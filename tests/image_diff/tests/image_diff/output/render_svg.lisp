
(import "gui/lisp.inc")

(defun main ()
    (when (defq stream (file-stream "/home/paul/scm/ChrysaLisp_AI_made_apps_experiment/apps/images/data/tiger.svg"))
        (when (defq canvas (SVG-Canvas stream 1))
            (bind '(w h) (. canvas :pref_size))
            (. canvas :save "out.cpm" 32)
            (print "OK " w " " h))))

(catch
    (main)
    (print "ERROR " _))

((ffi "service/gui/lisp_deinit"))
