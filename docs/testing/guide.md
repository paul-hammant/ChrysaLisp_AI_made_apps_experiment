# A Guide to Testing in ChrysaLisp

## The Philosophy of Testing

In ChrysaLisp, we view computation as the transformation of sequences of data. Our applications are designed to be expressive, declarative, and focused on the flow of data. Our tests should be no different.

A good test in ChrysaLisp is not a long, imperative script that checks every little detail. Instead, it is a concise, declarative specification of the expected transformation. It should be easy to read, easy to write, and should clearly express the intent of the code being tested.

## A New Testing Framework: `test.lisp`

> **Note:** The `test.lisp` framework described in this section is a proposal. It is not yet implemented. This guide provides a vision for what testing in ChrysaLisp could look like, and the examples are meant to illustrate the proposed style.

To help you write tests in this style, we are introducing a new testing framework called `test.lisp`. It is a BDD-style framework inspired by popular frameworks like RSpec and Jasmine. It provides a simple, expressive DSL for writing tests.

The core of `test.lisp` is the `describe` and `it` macros. `describe` is used to group related tests, and `it` is used to define a single test case.

Here is a simple example:

```lisp
(import "testing/test.lisp")

(describe "A simple calculator"
  (it "should add two numbers"
    (should-be (+ 1 2) 3))
  (it "should subtract two numbers"
    (should-be (- 5 2) 3)))
```

### Assertions

`test.lisp` provides a set of assertion functions that you can use to check the results of your code.

*   `(should-be actual expected)`: Checks if `actual` is equal to `expected`.
*   `(should-not-be actual expected)`: Checks if `actual` is not equal to `expected`.
*   `(should-be-true value)`: Checks if `value` is true.
*   `(should-be-false value)`: Checks if `value` is false.
*   `(should-be-nil value)`: Checks if `value` is nil.
*   `(should-not-be-nil value)`: Checks if `value` is not nil.
*   `(should-throw form)`: Checks if `form` throws an error.
*   `(should-not-throw form)`: Checks if `form` does not throw an error.

## Types of Tests

There are four main types of tests that you can write for your ChrysaLisp applications.

### 1. Unit/Spec Tests

Unit tests are the most basic type of test. They test a single unit of code, such as a function or a method, in isolation. They should not have any dependencies on external services like databases or networks.

Since Lisp-level objects in ChrysaLisp are just `hmap`s, it is very easy to create mock objects for unit tests. You can simply create an `hmap` with the methods that you need for your test.

Here is an example of a unit test for a function that calculates the area of a rectangle:

```lisp
(import "testing/test.lisp")

(defun rectangle-area (rect)
  (* (. rect :width) (. rect :height)))

(describe "rectangle-area"
  (it "should calculate the area of a rectangle"
    (let ((rect (hmap :width 10 :height 5)))
      (should-be (rectangle-area rect) 50))))
```

### 2. Service Tests

Service tests are for testing services that communicate over TCP/IP. These tests will typically involve starting a server, sending it requests, and checking the responses.

You can use mock objects to isolate your service from its dependencies. For example, if your service depends on a database, you can create a mock database object that returns canned data.

Here is an example of a service test for a simple echo server:

```lisp
(import "testing/test.lisp")
(import "lib/streams/net.lisp")

(describe "Echo Server"
  (it "should echo back whatever is sent to it"
    (let ((server (start-server :port 8080 :handler (lambda (stream) (pipe (io-stream-in stream) (io-stream-out stream))))))
      (let ((client (connect-to-server :host "localhost" :port 8080)))
        (. client :write "hello")
        (should-be (. client :read) "hello")
        (. server :stop)))))
```

### 3. Component Tests

Component tests are for testing UI components. These tests will typically involve creating a widget or a tree of widgets, inspecting their properties, and sending them events to simulate user interaction.

We provide a `test-widget` macro to make it easier to write component tests. This macro creates a widget in a test window, and provides a set of helper functions for interacting with it.

Here is an example of a component test for a button:

```lisp
(import "testing/test.lisp")
(import "testing/widget.lisp")

(describe "A simple button"
  (it "should change its text when clicked"
    (test-widget (ui-button my-button (:text "Click Me"))
      (should-be (. my-button :text) "Click Me")
      (send-event my-button :mouse_down)
      (send-event my-button :mouse_up)
      ;; assume the button's click handler changes the text
      (should-be (. my-button :text) "Clicked!"))))
```

### 4. Full-App Tests

Full-app tests are for testing your entire application. These tests will typically involve launching your application and then interacting with it as a user would.

You can write full-app tests as Lisp scripts that send messages to your application's mailbox. This allows you to script complex user interactions and check that your application behaves as expected.

Here is an example of a full-app test for a simple calculator app:

```lisp
(import "testing/test.lisp")

(describe "Calculator App"
  (it "should be able to add two numbers"
    (let ((app (start-app "apps/calculator/app.lisp")))
      ;; press the "1" button
      (send-message (. app :mailbox) (hmap :type :ui-event :widget 'button-1 :event :click))
      ;; press the "+" button
      (send-message (. app :mailbox) (hmap :type :ui-event :widget 'button-plus :event :click))
      ;; press the "2" button
      (send-message (. app :mailbox) (hmap :type :ui-event :widget 'button-2 :event :click))
      ;; press the "=" button
      (send-message (. app :mailbox) (hmap :type :ui-event :widget 'button-equals :event :click))
      ;; check the display
      (should-be (. (get-widget app 'display) :text) "3")
      (. app :quit))))
```
