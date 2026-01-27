;Test to check current directory and file paths
(defun main ()
	(print "Testing file access...")
	(print "Trying to list directory: apps/media/images/data")
	(defq files (split (pii-dirlist "apps/media/images/data") (ascii-char 10)))
	(print "Found " (length files) " files")
	(each! (lambda (file)
		(when (> (length file) 0)
			(print "  " file)))
		(list files)))

(catch
	(main)
	(progn
		(print "ERROR: " _)
		:t))

;clean shutdown
((ffi "service/gui/lisp_deinit"))
