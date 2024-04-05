(import "lib/options/options.inc")

(defq usage `(
(("-h" "--help")
"Usage: tail [options file]

	options:
		-h --help: this help info.
		-c --count num: line count, default 10.

	Returns lines from end of file or stdin.

	Defaults to last 10 lines.")
(("-c" "--count")
	,(lambda (args arg)
		(setq count (str-as-num (first args)))
		(rest args)))
))

(defun main ()
	;initialize pipe details and command args, abort on error
	(when (and
			(defq stdio (create-stdio))
			(defq count 10 args (options stdio usage)))
		(defq lines (list))
		(each-line (# (push lines %0)
			(if (> (length lines) count) (setq lines (slice lines (- -1 count) -1))))
				(if (<= (length args) 1) (io-stream 'stdin) (file-stream (second args))))
		(each print lines)))
