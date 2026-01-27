;basic system test
(import "lib/task/pipe.inc")
(import "lib/text/charclass.inc")

(defun my-test ()
	;test basic arithmetic
	(defq result1 (+ 1 2 3))
	(unless (= result1 6)
		(throw "Arithmetic test failed!" result1))

	;test string operations
	(defq test_str "hello")
	(unless (= (length test_str) 5)
		(throw "String length test failed!" test_str))

	;test list operations
	(defq test_list (list 1 2 3 4 5))
	(unless (= (length test_list) 5)
		(throw "List length test failed!" test_list))

	;test reduce! (ChrysaLisp style - seqs is a list of sequences)
	(defq sum (reduce! (lambda (acc x) (+ acc x)) (list test_list) 0))
	(unless (= sum 15)
		(throw "Reduce test failed!" sum))

	;test map! (ChrysaLisp style - seqs is a list of sequences, returns list)
	(defq doubled (map! (lambda (x) (* x 2)) (list test_list)))
	(unless (= (elem-get doubled 0) 2)
		(throw "Map test failed!" doubled))

	;test filter! (ChrysaLisp style - operates on single sequence)
	(defq evens (filter! (lambda (x) (= (% x 2) 0)) test_list))
	(unless (= (length evens) 2)
		(throw "Filter test failed!" evens))

	;all tests passed
	(print "All basic tests passed!")
	:t)

(catch
	(my-test)
	(progn
		;report error
		(print "Test failed with error: " _)
		;signal to abort the catch
		:t))

;clean shutdown of the VP node
((ffi "service/gui/lisp_deinit"))
