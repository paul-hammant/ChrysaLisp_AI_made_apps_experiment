(import "././login/env.inc")
(import "gui/lisp.inc")
(import "lib/text/syntax.inc")
(import "lib/task/cmd.inc")

;our UI widgets and events
(import "./widgets.inc")

(enums +select 0
	(enum main tip embeded))

(defq +margin_width (* 8 3)
	+doc_font (first (font-info *env_window_font*))
	+term_font (first (font-info *env_terminal_font*)))

(defun page-scale (s)
	(n2i (* (n2f s) *page_scale*)))

;lisp handler environment
((# (def (penv) '*handler_env* (env))))

(defun handler-func (state)
	(unless (defq handler (. handlers :find state))
		(defq module (cat "apps/docs/" (rest state) ".inc"))
		(repl (file-stream module) module)
		(. handlers :insert state handler))
	handler)

(defun intern-word (word)
	(. *page_words* :intern word))

(defun populate-page (file)
	(clear *search_widgets*)
	(setq *last_widget* :nil)
	(. *page_words* :empty)
	(when file
		;min width of an 80 column terminal !
		(def (defq vdu (Vdu))
			:font (create-font +term_font (page-scale 16))
			:vdu_width 80 :vdu_height 1)
		(ui-root page_flow (Flow) (:flow_flags +flow_right_fill
				:font (create-font +doc_font (page-scale 18))
				:color (get :color *window*))
			(ui-label _ (:min_width +margin_width))
			(ui-flow page (:flow_flags +flow_down_fill
					:min_width (first (. vdu :pref_size))))
			(ui-label _ (:min_width +margin_width)))
		(defq state :text)
		(each-line (lambda (line)
				(task-slice)
				(catch (setq state ((handler-func state)
							state page (trim-end line (ascii-char 13))))
					(progn (prin _) (print) (setq state :text) :t)))
			(file-stream file))
		(catch ((handler-func state) state page "")
			(progn (prin _) (print) (setq state :text) :t))
		(bind '(w h) (. page_flow :pref_size))
		(. page_flow :change 0 0 w h)
		(def *page_scroll* :min_width w)
		(def (get :vslider *page_scroll*)
			:value (if (defq pos (. scroll_pos :find file)) pos 0))
		(.-> *page_scroll* (:add_child page_flow) :layout)
		(.-> *doc_flow* :layout :dirty_all)))

(defun toolbar-states (toolbar states)
	(defq radio_col (canvas-brighter (get :color toolbar)))
	(each (# (undef (. %0 :dirty) :color)
			(if %1 (def %0 :color radio_col)))
		(. toolbar :children) states))

(defun visible-node (tree file)
	;highlight and show the selected file
	(when (defq node (. tree :find_node file))
		(. tree :select file)
		(. (penv tree) :visible node)))

;import actions
(import "./actions.inc")

(defun main ()
	(defq select (alloc-select +select_size) syntax (Syntax) handlers (Emap)
		scroll_pos (Fmap) *running* :t *current_file* "docs/apps/docs.md"
		*page_scale* 1.0 *regexp* :nil *whole_words* :nil
		*last_key* "" *last_files* (list) *page_words* (Fset 101)
		*last_widget* :nil *search_widgets* (list))
	(bind '(w h) (.-> *file_tree* (:populate "docs" '(".md")) :pref_size))
	(. *file_tree* :change 0 0 w h)
	(def *file_tree_scroll* :min_width w)
	(def *window* :tip_mbox (elem-get select +select_tip))
	(def *page_scroll* :min_height 800)
	(populate-page *current_file*)
	(visible-node *file_tree* *current_file*)
	(bind '(x y w h) (apply view-locate (. *window* :pref_size)))
	(gui-add-front (. *window* :change x y w h))
	(while *running*
		(defq *msg* (mail-read (elem-get select (defq idx (mail-select select)))))
		(cond
			((= idx +select_tip)
				;tip event
				(if (defq view (. *window* :find_id (getf *msg* +mail_timeout_id)))
					(. view :show_tip)))
			((= idx +select_embeded)
				;embeded event, only process internal events, not actions
				;and don't allow window events
				(and (neg? (defq id (getf *msg* +ev_msg_target_id)))
					(not (Window? (defq view (. *window* :find_id id))))
					(not (Title? view))
					(. *window* :event *msg*)))
			;must be +select_main
			((defq id (getf *msg* +ev_msg_target_id) action (. *event_map* :find id))
				;call bound event action
				(action))
			((and (not (Textfield? (. *window* :find_id id)))
					(= (getf *msg* +ev_msg_type) +ev_type_key_down)
					(> (getf *msg* +ev_msg_key_scode) 0))
				;key event
				(defq key (getf *msg* +ev_msg_key_key) mod (getf *msg* +ev_msg_key_mod))
				(cond
					((/= 0 (logand mod (const
							(+ +ev_key_mod_control +ev_key_mod_alt +ev_key_mod_meta))))
						;call bound control/command key action
						(if (defq action (. *key_map_control* :find key))
							(action)))
					((/= 0 (logand mod +ev_key_mod_shift))
						;call bound shift key action
						(if (defq action (. *key_map_shift* :find key))
							(action)))
					((defq action (. *key_map* :find key))
						;call bound key action
						(action))))
			(:t (. *window* :event *msg*)
				;save scroll position
				(. scroll_pos :insert *current_file* (get :value (get :vslider *page_scroll*))))))
	(undef (penv) '*handler_env*)
	(gui-sub *window*)
	(free-select select))
