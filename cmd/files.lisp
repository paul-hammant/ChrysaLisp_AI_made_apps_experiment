(import "lib/options/options.inc")
(import "lib/files/files.inc")

(defq usage `(
(("-h" "--help")
{Usage: files [options] [prefix] [postfix]

	options:
		-h --help: this help info.

	Find all files that match the prefix and postfix.

		prefix default "."
		postfix default ""

	eg.
	files ./apps/wallpaper/ .tga})
))

(defun main ()
	;initialize pipe details and command args, abort on error
	(when (and
			(defq stdio (create-stdio))
			(defq args (options stdio usage)))
		(defq postfix (if (< (length args) 2) "." (second args))
			prefix (if (< (length args) 3) "" (third args)))
		(if (ends-with "/" postfix) (setq postfix (most postfix)))
		(each print (files-all postfix `(,prefix)))))
