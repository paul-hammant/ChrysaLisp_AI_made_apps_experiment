(import "lib/options/options.inc")

(defq usage `(
(("-h" "--help")
"Usage: sdir [options] [prefix]

	options:
		-h --help: this help info.")
))

(defun main ()
	;initialize pipe details and command args, abort on error
	(when (and
			(defq stdio (create-stdio))
			(defq args (options stdio usage)))
		(defq prefix (if (> (length args) 1) (second args) "*"))
		(each (const print) (mail-enquire prefix))))
