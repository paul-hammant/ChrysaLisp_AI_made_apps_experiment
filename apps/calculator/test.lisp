(import "testing/test.lisp")
(import "apps/calculator/app.lisp")

(describe "Calculator Logic"
  (describe "do_lastop"
    (it "should add two numbers"
      (let ((accum 10) (num 5) (lastop "+"))
        (should-be (do_lastop) 15)))
    (it "should subtract two numbers"
      (let ((accum 10) (num 5) (lastop "-"))
        (should-be (do_lastop) 5)))
    (it "should multiply two numbers"
      (let ((accum 10) (num 5) (lastop "*"))
        (should-be (do_lastop) 50)))
    (it "should divide two numbers"
      (let ((accum 10) (num 5) (lastop "/"))
        (should-be (do_lastop) 2)))
    (it "should not throw an error when dividing by zero"
      (let ((accum 10) (num 0) (lastop "/"))
        (should-not-throw (do_lastop))
        (should-be accum 10))))))
