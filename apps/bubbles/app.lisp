(import "lib/math/vector.inc")
(import "./app.inc")

(enums +select 0
	(enum main timer tip))

(enums +event 0
	(enum close max min)
	(enum reset)
	(enum style))

(defq +width 600 +height 600 +min_width 300 +min_height 300
	+rate (/ 1000000 60) +base 0.3
	+palette (push `(,quote) (map (lambda (_) (vec-i2n
			(/ (logand (>> _ 16) 0xff) 0xff)
			(/ (logand (>> _ 8) 0xff) 0xff)
			(/ (logand _ 0xff) 0xff)))
		(list +argb_cyan +argb_yellow +argb_magenta +argb_red +argb_green +argb_blue))))

(ui-window *window* ()
	(ui-title-bar _ "Bubbles" (0xea19 0xea1b 0xea1a) +event_close)
	(ui-flow _ (:flow_flags +flow_right_fill)
		(ui-tool-bar *main_toolbar* ()
			(ui-buttons (0xe938) +event_reset))
		(. (ui-radio-bar *style_toolbar* (0xe976 0xe9a3 0xe9f0)
			(:color *env_toolbar2_col*)) :connect +event_style))
	(ui-scroll *image_scroll* +scroll_flag_both
			(:min_width +width :min_height +height)
		(ui-backdrop *backdrop* (:color +argb_black :ink_color +argb_grey8)
			(ui-canvas *layer1_canvas* +width +height 1))))

(defun redraw-layers (verts mask)
	;redraw layer/s
	(elem-set dlist +dlist_layer1_verts verts)
	(elem-set dlist +dlist_mask (logior (elem-get dlist +dlist_mask) mask)))

(defun vertex-cloud (num)
	;array of random verts
	(defq out (cap num (list)))
	(while (> (setq num (dec num)) -1)
		(push out (list
			(vec-i2n (- (random (const (* box_size 2))) box_size)
				(- (random (const (* box_size 2))) box_size)
				(- (random (const (* box_size 2))) box_size))
			(vec-i2n (- (random (const (inc (* max_vel 2)))) (const max_vel))
				(- (random (const (inc (* max_vel 2)))) (const max_vel))
				(- (random (const (inc (* max_vel 2)))) (const max_vel)))
			(i2n (const bubble_radius))
			(vec-add (const (vec-f2n +base +base +base))
				(vec-scale (elem-get +palette (random (length +palette)))
					(f2n (random (const (- 1.0 +base))))))))) out)

(defun vertex-update (verts)
	(each (lambda (vert)
		(bind '(p v _ _) vert)
		(vec-add p v p)
		(bind '(x y z) p)
		(bind '(vx vy vz) v)
		(if (or (> x (const (i2n box_size))) (< x (const (i2n (neg box_size)))))
			(setq vx (neg vx)))
		(if (or (> y (const (i2n box_size))) (< y (const (i2n (neg box_size)))))
			(setq vy (neg vy)))
		(if (or (> z (const (i2n box_size))) (< z (const (i2n (neg box_size)))))
			(setq vz (neg vz)))
		(elem-set vert +vertex_v (vec vx vy vz))) verts))

(defun fpoly (canvas col x y _)
	;draw a polygon on a canvas
	(.-> canvas (:set_color col) (:fpoly x y +winding_odd_even _)))

(defun circle (r)
	;cached circle generation, quantised to 1/4 pixel
	(defq r (* (floor (* (n2f r) 4.0)) 0.25))
	(memoize r (path-gen-arc 0.0 0.0 0.0 +fp_2pi r (path)) 13))

(defun lighting ((r g b) z)
	;very basic attenuation
	(defq at (/ (const (i2n box_size)) z) r (* r at) g (* g at) b (* b at))
	(+ 0xd0000000
		(<< (n2i (* r (const (i2n 0xff)))) 16)
		(<< (n2i (* g (const (i2n 0xff)))) 8)
		(n2i (* b (const (i2n 0xff))))))

(defun clip-verts (hsw hsh verts)
	;clip and project verts
	(reduce (lambda (out ((x y z) _ r c))
		(setq z (+ z (const (i2n (+ (* box_size 2) max_vel)))))
		(when (> z (const (i2n focal_len)))
			(defq v (vec x y z) w (/ hsw z) h (/ hsh z))
			(bind '(sx sy sz) (vec-add v (vec-scale (vec-norm
				(vec-add v (vec-sub (elem-get dlist +dlist_light_pos) v))) r)))
			(defq x (+ (* x h) hsw) y (+ (* y h) hsh) r (* r h)
				sx (+ (* sx h) hsw) sy (+ (* sy h) hsh))
			(push out (list (vec-n2f x y z) (vec-n2f sx sy) (n2f r)
				(lighting c z) (lighting (const (vec-i2n 1 1 1)) z)))) out)
		verts (cap (length verts) (list))))

(defun render-verts (canvas verts)
	;render circular verts
	(each (lambda (((x y z) (sx sy) r c sc))
		(fpoly canvas c x y (list (circle r)))
		(fpoly canvas sc sx sy (list (circle (* r 0.2))))) verts))

(defun redraw (dlist)
	;redraw layer/s
	(when (/= 0 (logand (elem-get dlist +dlist_mask) 1))
		(defq canvas (elem-get dlist +dlist_layer1_canvas))
		(. canvas :fill 0)
		(bind '(sw sh) (. canvas :pref_size))
		(defq hsw (i2n (>> sw 1)) hsh (i2n (>> sh 1)))
		(render-verts canvas
			(sort (clip-verts hsw hsh (elem-get dlist +dlist_layer1_verts))
				(# (if (<= (last (first %0)) (last (first %1))) 1 -1))))
		(. canvas :swap 0))
	(elem-set dlist +dlist_mask 0))

(defun tooltips ()
	(def *window* :tip_mbox (elem-get select +select_tip))
	(ui-tool-tips *main_toolbar*
		'("refresh"))
	(ui-tool-tips *style_toolbar*
		'("plain" "grid" "axis")))

(defun main ()
	;ui tree initial setup
	(defq dlist (list 0 light_pos *layer1_canvas* (list)) select (alloc-select +select_size))
	(tooltips)
	(. *layer1_canvas* :set_canvas_flags +canvas_flag_antialias)
	(. *backdrop* :set_size +width +height)
	(. *style_toolbar* :set_selected 0)
	(bind '(x y w h) (apply view-locate (. *window* :pref_size)))
	(gui-add-front-rpc (. *window* :change x y w h))
	(def *image_scroll* :min_width +min_width :min_height +min_height)

	;random cloud of verts
	(defq verts (vertex-cloud num_bubbles))
	(redraw-layers verts 1)

	;main event loop
	(defq last_state :u id :t)
	(mail-timeout (elem-get select +select_timer) +rate 0)
	(while id
		(defq *msg* (mail-read (elem-get select (defq idx (mail-select select)))))
		(cond
			((= idx +select_timer)
				;timer event
				(mail-timeout (elem-get select +select_timer) +rate 0)
				(vertex-update verts)
				(redraw-layers verts 1)
				(redraw dlist))
			((= idx +select_tip)
				;tip time mail
				(if (defq view (. *window* :find_id (getf *msg* +mail_timeout_id)))
					(. view :show_tip)))
			((= (setq id (getf *msg* +ev_msg_target_id)) +event_close)
				(setq id :nil))
			((= id +event_min)
				;min button
				(bind '(x y w h) (apply view-fit (cat (. *window* :get_pos) (. *window* :pref_size))))
				(. *window* :change_dirty x y w h))
			((= id +event_max)
				;max button
				(def *image_scroll* :min_width +width :min_height +height)
				(bind '(x y w h) (apply view-fit (cat (. *window* :get_pos) (. *window* :pref_size))))
				(. *window* :change_dirty x y w h)
				(def *image_scroll* :min_width +min_width :min_height +min_height))
			((= id +event_reset)
				;reset button
				(setq verts (vertex-cloud num_bubbles)))
			((= id +event_style)
				;styles
				(def (. *backdrop* :dirty) :style
					(elem-get '(:plain :grid :axis) (. *style_toolbar* :get_selected))))
			((and (= id (. *layer1_canvas* :get_id))
				(= (getf *msg* +ev_msg_type) +ev_type_mouse))
					;mouse event in canvas
					(bind '(w h) (. *layer1_canvas* :get_size))
					(defq rx (- (getf *msg* +ev_msg_mouse_rx) (/ w 2))
						ry (- (getf *msg* +ev_msg_mouse_ry) (/ h 2)))
					(cond
						((/= (getf *msg* +ev_msg_mouse_buttons) 0)
							;mouse button is down
							(case last_state
								(:d ;was down last time
									)
								(:u ;was up last time
									(setq last_state :d)))
							;set light pos
							(elem-set dlist +dlist_light_pos
								(vec-i2n (* rx 4) (* ry 4) (neg (* box_size 4)))))
						(:t ;mouse button is up
							(case last_state
								(:d ;was down last time
									(setq last_state :u))
								(:u ;was up last time, so we are hovering
									:t)))))
			(:t (. *window* :event *msg*))))
	;close window
	(free-select select)
	(gui-sub-rpc *window*)
	(profile-report "Bubbles"))
