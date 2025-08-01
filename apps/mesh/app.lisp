(import "././login/env.inc")
(import "gui/lisp.inc")
(import "lib/math/scene.inc")
(import "lib/task/local.inc")
(import "./app.inc")

(enums +event 0
	(enum close max min)
	(enum mode auto)
	(enum xrot yrot zrot)
	(enum layout)
	(enum style))

(enums +select 0
	(enum main task reply tip frame_timer retry_timer))

(defq anti_alias :nil frame_timer_rate (/ 1000000 30) retry_timer_rate 1000000
	retry_timeout (task-timeout 10) +min_size 450 +max_size 800
	canvas_size +min_size canvas_scale (if anti_alias 1 2)
	+canvas_mode (if anti_alias +canvas_flag_antialias 0)
	+stage_depth +real_4 +focal_dist +real_2
	*rotx* +real_0 *roty* +real_0 *rotz* +real_0
	+near +focal_dist +far (+ +near +stage_depth)
	+top (* +focal_dist +real_1/2) +bottom (* +focal_dist +real_-1/2)
	+left (* +focal_dist +real_-1/2) +right (* +focal_dist +real_1/2)
	*auto_mode* :nil *render_mode* :nil)

(ui-window *window* ()
	(ui-title-bar *title* "Mesh" (0xea19 0xea1b 0xea1a) +event_close)
	(ui-flow _ (:flow_flags +flow_right_fill)
		(ui-tool-bar *main_toolbar* ()
			(ui-buttons (0xe962 0xea43) +event_mode))
		(. (ui-radio-bar *style_toolbar* (0xe976 0xe9a3 0xe9f0)
			(:color *env_toolbar2_col*)) :connect +event_style)
		(ui-backdrop _ (:color (const *env_toolbar_col*))))
	(ui-flow _ (:flow_flags +flow_right_fill)
		(ui-grid _ (:grid_width 1 :font *env_body_font*)
			(ui-label _ (:text "X rot:"))
			(ui-label _ (:text "Y rot:"))
			(ui-label _ (:text "Z rot:")))
		(ui-grid _ (:grid_width 1)
			(. (ui-slider *xrot_slider* (:value 0 :maximum 1000 :portion 10 :color +argb_green))
				:connect +event_xrot)
			(. (ui-slider *yrot_slider* (:value 0 :maximum 1000 :portion 10 :color +argb_green))
				:connect +event_yrot)
			(. (ui-slider *zrot_slider* (:value 0 :maximum 1000 :portion 10 :color +argb_green))
				:connect +event_zrot)))
	(ui-backdrop *main_backdrop* (:style :plain :color +argb_black :ink_color +argb_grey8
			:min_width +min_size :min_height +min_size)
		(ui-canvas *main_widget* canvas_size canvas_size canvas_scale)))

(defun tooltips (mbox)
	(def *window* :tip_mbox mbox)
	(ui-tool-tips *main_toolbar*
		'("mode" "auto"))
	(ui-tool-tips *style_toolbar*
		'("plain" "grid" "axis")))

(defun set-rot (slider angle)
	(set (. slider :dirty) :value
		(n2i (/ (* angle (const (n2r 1000))) +real_2pi))))

(defun get-rot (slider)
	(/ (* (n2r (get :value slider)) +real_2pi) (const (n2r 1000))))

(defun dispatch-job (key val)
	;send another job to child
	(cond
		((defq job (pop jobs))
			(def val :job job :timestamp (pii-time))
			(mail-send (get :child val)
				(setf-> job
					(+job_key key)
					(+job_reply (elem-get select +select_reply)))))
		(:t ;no jobs in que
			(undef val :job :timestamp))))

(defun create (key val nodes)
	; (create key val nodes)
	;function called when entry is created
	(open-task "apps/mesh/child.lisp" (elem-get nodes (random (length nodes)))
		+kn_call_child key (elem-get select +select_task)))

(defun destroy (key val)
	; (destroy key val)
	;function called when entry is destroyed
	(when (defq child (get :child val)) (mail-send child ""))
	(when (defq job (get :job val))
		(push jobs job)
		(undef val :job)))

(defun create-scene (job_que)
	; (create-scene job_que) -> scene_root
	;create mesh loader jobs
	(each (lambda ((name command))
			(push job_que (cat (str-alloc +job_name) (pad name 16) command)))
		'(("sphere.1" "(Mesh-iso (Iso-sphere 20 20 20) (n2r 0.25))")
		("capsule" "(Mesh-iso (Iso-capsule 20 20 20) (n2r 0.25))")
		("cube.1" "(Mesh-iso (Iso-cube 8 8 8) (n2r 0.45))")
		("torus.1" "(Mesh-torus +real_1 +real_1/3 20)")
		("sphere.2" "(Mesh-sphere +real_1/2 10)")))
	;create scene graph
	(defq scene (Scene "root")
		sphere_obj (Scene-object :nil (fixeds 1.0 1.0 1.0 1.0) "sphere.1")
		capsule1_obj (Scene-object :nil (fixeds 0.8 1.0 0.0 0.0) "capsule.1")
		capsule2_obj (Scene-object :nil (fixeds 0.8 0.0 1.0 1.0) "capsule.2")
		cube_obj (Scene-object :nil (fixeds 0.8 1.0 1.0 0.0) "cube.1")
		torus_obj (Scene-object :nil (fixeds 1.0 0.0 1.0 0.0) "torus.1")
		sphere2_obj (Scene-object :nil (fixeds 0.8 1.0 0.0 1.0) "sphere.2"))
	(. sphere_obj :set_translation (+ +real_-1/3 +real_-1/3) (+ +real_-1/3 +real_-1/3) (- +real_0 +focal_dist +real_1))
	(. torus_obj :set_translation (+ +real_1/3 +real_1/3) (+ +real_1/3 +real_1/3) (- +real_0 +focal_dist +real_2))
	(. sphere2_obj :set_translation +real_0 +real_1/2 +real_0)
	(. cube_obj :set_translation +real_0 +real_-1/2 +real_0)
	(.-> capsule1_obj
		(:set_translation +real_0 +real_1/2 +real_0)
		(:set_rotation +real_0 +real_hpi +real_0))
	(. capsule2_obj :set_translation +real_0 +real_-1/2 +real_0)
	(.-> torus_obj (:add_node sphere2_obj) (:add_node cube_obj))
	(.-> sphere_obj (:add_node capsule1_obj) (:add_node capsule2_obj))
	(.-> scene (:add_node sphere_obj) (:add_node torus_obj)))

;import actions and bindings
(import "./actions.inc")

(defun dispatch-action (&rest action)
	(catch (eval action) (progn (prin _) (print) :t)))

(defun main ()
	;; (defq then (pii-time))
	;; (times 10 (Mesh-iso (Iso-capsule 30 30 30) (n2r 0.25)))
	;; (prin (time-in-seconds (- (pii-time) then)))(print)
	(bind '(x y w h) (apply view-locate (.-> *window* (:connect +event_layout) :pref_size)))
	(.-> *main_widget* (:set_canvas_flags +canvas_mode) (:fill +argb_black) (:swap 0))
	(. *style_toolbar* :set_selected 0)
	(gui-add-front-rpc (. *window* :change x y w h))
	(defq select (task-mboxes +select_size) *running* :t *dirty* :t
		jobs (list) scene (create-scene jobs) farm (Local create destroy 4))
	(tooltips (elem-get select +select_tip))
	(mail-timeout (elem-get select +select_frame_timer) frame_timer_rate 0)
	(mail-timeout (elem-get select +select_retry_timer) retry_timer_rate 0)
	(while *running*
		(defq *msg* (mail-read (elem-get select (defq idx (mail-select select)))))
		(cond
			((= idx +select_tip)
				;tip event
				(if (defq view (. *window* :find_id (getf *msg* +mail_timeout_id)))
					(. view :show_tip)))
			((= idx +select_task)
				;child task launch response
				(defq key (getf *msg* +kn_msg_key) child (getf *msg* +kn_msg_reply_id))
				(when (defq val (. farm :find key))
					(def val :child child)
					(dispatch-job key val)))
			((= idx +select_reply)
				;child mesh response
				(defq key (getf *msg* +job_reply_key)
					mesh_name (trim-start (slice *msg* +job_reply_name +job_reply_data))
					mesh (Mesh-data
							(getf *msg* +job_reply_num_verts)
							(getf *msg* +job_reply_num_norms)
							(getf *msg* +job_reply_num_tris)
							(slice *msg* +job_reply_data -1)))
				(each (# (. %0 :set_mesh mesh)) (. scene :find_nodes mesh_name))
				(setq *dirty* :t)
				(when (defq val (. farm :find key))
					(dispatch-job key val)))
			((= idx +select_retry_timer)
				;retry timer event
				(mail-timeout (elem-get select +select_retry_timer) retry_timer_rate 0)
				(. farm :refresh retry_timeout)
				(when (= 0 (length jobs))
					(defq working :nil)
					(. farm :each (lambda (key val)
						(setq working (or working (get :job val)))))
					(unless working
						(mail-timeout (elem-get select +select_retry_timer) 0 0)
						(. farm :close))))
			((= idx +select_frame_timer)
				;frame timer event
				(mail-timeout (elem-get select +select_frame_timer) frame_timer_rate 0)
				(when *auto_mode*
					(setq *rotx* (% (+ *rotx* (n2r 0.01)) +real_2pi)
						*roty* (% (+ *roty* (n2r 0.02)) +real_2pi)
						*rotz* (% (+ *rotz* (n2r 0.03)) +real_2pi)
						*dirty* :t)
					(set-rot *xrot_slider* *rotx*)
					(set-rot *yrot_slider* *roty*)
					(set-rot *zrot_slider* *rotz*))
				(when *dirty*
					(setq *dirty* :nil)
					(. scene :set_rotation +real_0 +real_0 *rotz*)
					(each (# (. %0 :set_rotation *rotx* *roty* +real_0)) (. scene :children))
					(. scene :render *main_widget* (* canvas_size canvas_scale)
						+left +right +top +bottom +near +far *render_mode*)))
			;must be gui event to main mailbox
			((defq id (getf *msg* +ev_msg_target_id) action (. *event_map* :find id))
				;call bound event action
				(dispatch-action action))
			((and (not (Textfield? (. *window* :find_id id)))
					(= (getf *msg* +ev_msg_type) +ev_type_key_down)
					(> (getf *msg* +ev_msg_key_scode) 0))
				;key event
				(defq key (getf *msg* +ev_msg_key_key)
					mod (getf *msg* +ev_msg_key_mod))
				(cond
					((bits? mod +ev_key_mod_control +ev_key_mod_alt +ev_key_mod_meta)
						;call bound control/command key action
						(when (defq action (. *key_map_control* :find key))
							(dispatch-action action)))
					((bits? mod +ev_key_mod_shift)
						;call bound shift key action, else insert
						(cond
							((defq action (. *key_map_shift* :find key))
								(dispatch-action action))
							((<= +char_space key +char_tilde)
								;insert char etc ...
								(char key))))
					((defq action (. *key_map* :find key))
						;call bound key action
						(dispatch-action action))
					((<= +char_space key +char_tilde)
						;insert char etc ...
						(char key))))
			(:t ;gui event
				(. *window* :event *msg*))))
	(. farm :close)
	(gui-sub-rpc *window*)
	(profile-report "Mesh"))
