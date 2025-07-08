(import "././login/env.inc")
(import "gui/lisp.inc")
(import "lib/task/global.inc")
(import "./app.inc")

(enums +event 0
	(enum close))

(enums +select 0
	(enum main task reply nodes))

(defq +scale_size 5 +bops 1000000000 +mops 1000000
	+max_bops_align (* +scale_size +bops) +max_mops_align  (* +scale_size +mops)
	+smooth_steps 5 +poll_rate (/ 1000000 4)
	+bars ''(:regs_bar :memory_bar :reals_bar)
	+results ''(:regs_results :memory_results :reals_results)
	+max_aligns `'(,+max_bops_align ,+max_bops_align ,+max_mops_align)
	+retry_timeout (task-timeout 5))

(ui-window *window* ()
	(ui-title-bar _ "Network Speed" (0xea19) +event_close)
	(ui-grid *net_charts* (:grid_height 1)
		(ui-hchart _ "Net Regs (bops/s)" +scale_size (:units +bops :color +argb_green))
		(ui-hchart _ "Net Memory (bops/s)" +scale_size (:units +bops :color +argb_yellow))
		(ui-hchart _ "Net Reals (mops/s)" +scale_size (:units +mops :color +argb_red)))
	(ui-grid *charts* (:grid_height 1)
		(ui-hchart _ "Regs (bops/s)" +scale_size (:units +bops :color +argb_green))
		(ui-hchart _ "Memory (bops/s)" +scale_size (:units +bops :color +argb_yellow))
		(ui-hchart _ "Reals (mops/s)" +scale_size (:units +mops :color +argb_red))))

(defun create (key now)
	; (create key now) -> val
	;function called when entry is created
	(def (defq node (env 1)) :timestamp now)
	(each (# (def node %0 (. %2 :add_bar) %1 (list))) +bars +results charts)
	(open-task "apps/netspeed/child.lisp" key +kn_call_open 0 (elem-get select +select_task))
	node)

(defun destroy (key node)
	; (destroy key val)
	;function called when entry is destroyed
	(when (defq child (get :child node)) (mail-send child ""))
	(each (# (. (get %0 node) :sub)) +bars))

(defun smooth-result (results val)
	(if (> (length (push results val)) +smooth_steps)
		(setq results (rest results)))
	(list results (/ (reduce (const +) results 0) (length results))))

(defun update-result (node &rest vals)
	(setq vals (map (#
			(bind '(res val) (smooth-result (get %0 node) %1))
			(def node %0 res) val) +results vals))
	(each (# (def %0 :maximum (align (max %2 (get :maximum %0)) %3))
			(def (. (get %1 node) :dirty) :value %2))
		charts +bars vals +max_aligns))

(defun update-net-result ()
	(defq results (list) bars (map (# (.-> %0 :get_bar_grid :children)) charts)
		totals (map (# (reduce (# (+ %0 (get :value %1))) %0 0)) bars)
		totals (map (#
			(bind '(res val) (smooth-result %0 %1))
			(push results res) val) net_results totals))
	(setq net_results results)
	(each (# (def %0 :maximum (align (max %2 (get :maximum %0)) %3))
			(def (. %1 :dirty) :value %2))
		net_charts net_bars totals +max_aligns))

(defun main ()
	(defq id :t select (alloc-select +select_size)
		charts (. *charts* :children) net_charts (. *net_charts* :children)
		net_bars (map (# (. %0 :add_bar)) net_charts)
		net_results (lists (length net_charts))
		global_tasks (Global create destroy) poll_que (list))
	(bind '(x y w h) (apply view-locate (. *window* :pref_size)))
	(gui-add-front-rpc (. *window* :change_dirty x y w h))
	(mail-timeout (elem-get select +select_nodes) 1 0)
	(while id
		(defq msg (mail-read (elem-get select (defq idx (mail-select select)))))
		(case idx
			(+select_main
				;main mailbox
				(cond
					((= (setq id (getf msg +ev_msg_target_id)) +event_close)
						;close button
						(setq id :nil))
					(:t (. *window* :event msg))))
			(+select_task
				;child launch response
				(defq child (getf msg +kn_msg_reply_id)
					node (. global_tasks :find (slice child +long_size -1)))
				(when node
					(def node :child child :timestamp (pii-time))
					(push poll_que child)))
			(+select_reply
				;child poll response
				(when (defq node (. global_tasks :find (getf msg +reply_node)))
					(update-result node
						(getf msg +reply_vops_regs)
						(getf msg +reply_vops_memory)
						(getf msg +reply_vops_reals))
					(def node :timestamp (pii-time))
					(push poll_que (get :child node))))
			(:t ;polling timer event
				(mail-timeout (elem-get select +select_nodes) +poll_rate 0)
				(when (. global_tasks :refresh +retry_timeout)
					;nodes have mutated
					(bind '(x y w h) (apply view-fit
						(cat (. *window* :get_pos) (. *window* :pref_size))))
					(. *window* :change_dirty x y w h)
					(each (# (. %0 :layout_bars)) charts))
				;set scales
				(update-net-result)
				(each (# (. %0 :update_scale)) (cat charts net_charts))
				;poll any ready children
				(each (# (mail-send %0 (elem-get select +select_reply))) poll_que)
				(clear poll_que))))
	;close window and children
	(. global_tasks :close)
	(free-select select)
	(gui-sub-rpc *window*))
