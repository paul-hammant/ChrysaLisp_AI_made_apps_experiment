# Event handling and dispatch

This document covers how events sent to the event loop of an application are
handled, or dispatched, so that the correct action is performed for each event
received.

When a GUI application receives an event message on its `main` mailbox these
come from the GUI task. They consist of various types, mouse events, keyboard
presses and UI widget notifications when objects like buttons are clicked etc.

In the `EVENT_LOOPS` document we talked about applications allocating multiple
mailboxes to differentiate between type of messages. But did not cover
techniques for handling the events that come to the `main` mailbox from the
GUI.

Each GUI event message has a common header format which contains a `type` field
so your code can tell what to do with it. But there are various ways you can
handle how to decide what to do.

Some ways are more flexible than others and can help with code reuse and
maintenance, others while not so flexible, may be fine for applications with
not many event types to handle.

## GUI events

There are various GUI event types, listed in `service/gui/lisp.inc`:

```file
service/gui/lisp.inc "+ev_type" ""
```

These event messages follow a standard format, have a common header that they
inherit from, and extended fields for each individual event type.

```file
service/gui/lisp.inc "+ev_msg" "defq"
```

When an event is received, it'll be targeted at a particular target object,
one of the buttons, or a scroll bar, or a textfield etc. The
`+ev_msg_target_id` field contains the id of that target UI widget.

For an action event, this target id, will depend on what the user code decided
it should be by use of the View class `:connect` method.

A negative target id, will be used for internal widget events, positive for
these user action events.

## Defining your UI event IDs

Lets look at the `apps/bubbles/app.lisp`, Bubbles demo:

```file
apps/bubbles/app.lisp "+event" ""
```

We are going to use these target ids when we construct the UI tree for the
application.

Please note that target id `0`, is reserved for, and should always be used to
indicate the application needs to close ! This action event will be sent by the
GUI service when the user wishes to logout or shutdown the system ! The best
thing is use this for your close button event.

* `+event_close, +event_min, +event_max` for our title bar window buttons.

* `+event_reset` for the main toolbar button, that makes the demo reset with a
new set of bubbles.

* `+event_grid, +event_plain, +event_axis` for the background style selection
buttons.

Here is the UI tree for the application. We will cover the UI builder macros in
another document in detail, but just note for now that we use the start of
these three event blocks for each of the 3 button bars in this UI tree.

```file
apps/bubbles/app.lisp "*window*" ""
```

The UI macros build our widget tree for us and automate calling the View class
`:connect` method for the buttons on the button bars. When these buttons are
clicked we will receive an `+ev_type_action` typed event with the
`+ev_msg_target_id` field containing our declared constants.

## The `(cond)` dispatch event loop

The simplest way to deal with the GUI event handling is to use a `(cond)`
statement, each clause of which checks the target id to see what the event was.

Here is the Bubbles `(main)` function, stripped down to just the select mailbox
event handling.

```vdu
(defun main ()
	(defq select (alloc-select +select_size))
	...
	(defq id :t)
	(mail-timeout (elem-get select +select_timer) rate 0)
	(while id
		(defq *msg* (mail-read (elem-get select (defq idx (mail-select select)))))
		(cond
			((= idx +select_timer)
				;timer event
				(mail-timeout (elem-get select +select_timer) rate 0)
				...
				)
			((= idx +select_tip)
				;tip time mail
				...
				)
			;here we know that this msg must be for (= idx +select_main)
			;ie. from the GUI
			((= (setq id (getf *msg* +ev_msg_target_id)) +event_close)
				(setq id :nil))
			((= id +event_min)
				;min button
				...
				)
			((= id +event_max)
				;max button
				...
				)
			((= id +event_reset)
				;reset button
				...
				)
			((<= +event_grid id +event_axis)
				;style buttons
				...
				)
			...
			(:t (. *window* :event *msg*))))
	...
	(free-select select))
```

In the default clause we pass the event to our windows `:event` method. This
method deals with all internal UI event traffic, mainly the negative target ids
we mentioned earlier.

While this works fine as a way of dispatching it's not very flexible. Once we
start having a LOT of UI widgets and may want to handle key press actions and
so forth, this `(cond)` statement is going to get very long and untidy. We are
going to end up not being able to see the wood for the trees !

## The `Fmap` event action dispatch loop

The Editor application takes this approach and it has started to become the `go
to` way to arrange things. I encourage folks to adopt this style apart from the
very simplest or throw away code.

It's still a simple idea though. We have separate functions for each action we
wish to perform and hold them in a set of files for that type of action. We
then have a `module` that includes all the handler action files and enters the
action functions into an event id to action function `Fmap`.

Likewise we do the same for keyboard event actions !

The module only exports these mapping objects to the application and it
searches these maps to find the `binding` for the event or key.

Here is the Editor application action bindings, `apps/editor/actions.inc`:

```vdu
;module
(env-push)

;;;;;;;;;
; actions
;;;;;;;;;

(import "./utils.inc")
(import "./undo.inc")
(import "./cursor.inc")
(import "./block.inc")
(import "./edit.inc")
(import "./file.inc")
(import "./select.inc")
(import "./clipboard.inc")
(import "./search.inc")
(import "./macros.inc")
(import "./ui.inc")

(defq
*event_map* (scatter (Fmap)
	...
	+event_close action-close
	+event_min action-minimise
	+event_max action-maximise)

*key_map* (scatter (Fmap)
	0x40000050 action-left
	...
	+char_tab action-tab)

*key_map_shift* (scatter (Fmap)
	0x40000050 action-left-select
	...
	+char_tab action-left-tab)

*key_map_control* (scatter (Fmap)
	(ascii-code "M") action-macro-record
	...
	(ascii-code "O") action-unique)

	...
)

...

;module
(export-symbols
	'(*event_map* *key_map* *key_map_shift* *key_map_control*
	...))
(env-pop)
```

In the `(main)` function event loop, for the `+select_main` mailbox we search
for the binding and call it if we find it. This is stripped down to just the
event and key dispatching code.

```vdu
(enums +select 0
	(enum main tip))

;import actions and bindings
(import "./actions.inc")

(defun dispatch-action (&rest action)
	...
	(catch (eval action) (progn (prin _) (print) :t)))

(defun main ()
	(defq select (alloc-select +select_size))
	...
	(while *running*
		(defq *msg* (mail-read (elem-get select (defq idx (mail-select select)))))
		(cond
			((= idx +select_tip)
				;tip time mail
				...
				)
			((defq id (getf *msg* +ev_msg_target_id)
				   action (. *event_map* :find id))
				;call bound event action
				(dispatch-action action))
			...
			((and (not (Textfield? (. *window* :find_id id)))
					(= (getf *msg* +ev_msg_type) +ev_type_key_down)
					(> (getf *msg* +ev_msg_key_scode) 0))
				;key event
				(defq key (getf *msg* +ev_msg_key_key)
					  mod (getf *msg* +ev_msg_key_mod))
				(cond
					...
					((bits? mod +ev_key_mod_control +ev_key_mod_alt +ev_key_mod_meta)
						;call bound control/command key action
						(when (defq action (. *key_map_control* :find key))
							...
							(dispatch-action action)))
					((bits? mod +ev_key_mod_shift)
						;call bound shift key action, else insert
						(cond
							((defq action (. *key_map_shift* :find key))
								...
								(dispatch-action action))
							((<= +char_space key +char_tilde)
								(dispatch-action action-insert (char key))
								...
								)))
					((defq action (. *key_map* :find key))
						;call bound key action
						...
						(dispatch-action action))
					((<= +char_space key +char_tilde)
						;insert the char
						(dispatch-action action-insert (char key))
						...
						)))
			(:t ;gui event
				...
				(. *window* :event *msg*)))
		...
		)
	...
	(free-select select))
```

Once we find an action binding within the `*event_map*` or the `*key_map*` (we have
several key action maps, for each key modifier state) we call the action
function via the `(dispatch-action)` helper. This is just using a `(catch)`
statement to make things a bit more robust in case we have actions that throw
errors. Don't really want to crash out of the Editor application and loose all
our editing !

If you look at the full code for this `(dispatch-action)` function you will see
another reason why this method of event dispatch is so useful. When the Editor
is in `macro record` mode we can keep a list of everything we call along with
all the parameters ! This lets us `playback` this recording at a later date,
voila we have Editor macro record and playback with hardly any effort.

One subtly with the key clause is that we check to see if the key event was
targeted at a Textfield object, if it was then we let it go to the default
clause, only if not do we try to dispatch the key action.

Another advantage of this method of dispatching is that we can reuse the
actions within other applications. If you look at the Viewer application,
`apps/viewer/app.lisp`, you can see that its `actions` module imports several
of the Editor action files as the functionality required is identical.

## Dynamic dispatch

This example is not about the dispatching of GUI events but illustrates an
important technique that applications may find useful.

The Docs application, `apps/docs/app.lisp`, uses the idea of a current state
and searches an `Emap` of state to handler function in order to render each
line of the document being scanned. If the state is not found in the `Emap`
then it uses the state to create a module name and dynamically loads that
module, entering it into the `Emap`.

In this way the Docs application has the ability to be extended in
functionality at runtime. The addition of a new document section handler
involves providing a new module and does not require changing the Docs
application itself.

Here is the entire Docs application, it's quite short:

```file
apps/docs/app.lisp
```

In the `(populate-page)` function, the document file is processed by scanning
with an `(each-line)` call. It first of all creates a new page widget, just a
UI Flow object, and the job of a handler module is to be given the current line
of text and the page instance and to do whatever that handler does.

The relevant parts of this function that do the dynamic module loading are:

```file
apps/docs/app.lisp "handler-func" ""
apps/docs/app.lisp "state :text" "bind"
```

Each module takes the current line of the file and decides what other UI
widgets need to be created to populate the page widget. In general these
modules build up their own widget sub tree and, when they see the section close
line, they add that sub tree to the page and switch the state back to `:text`
state.

Here is the `:image` handler module:

```file
apps/docs/image.inc
```

This is the `:vdu` handler module, the very same module that's displaying the
syntax highlighted source code that you are now looking at !

```file
apps/docs/vdu.inc
```
