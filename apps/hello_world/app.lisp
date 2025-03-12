(import "gui/lisp.inc")

(enums +event 0
    (enum close)
    (enum set_alarm))

(ui-window *window* ()
    (ui-title-bar _ "Hello World" (0xea19) +event_close)
    (ui-label _ (:text "Hello, World!" :color +argb_white
        :flow_flags (logior +flow_flag_align_hcenter +flow_flag_align_vcenter)
        :font (create-font "fonts/OpenSans-Regular.ctf" 24))))

(defun main ()
    (bind '(x y w h) (apply view-locate (. *window* :pref_size)))
    (gui-add-front-rpc (. *window* :change x y w h))
    (while (cond
        ((= (defq id (getf (defq msg (mail-read (task-netid))) +ev_msg_target_id)) +event_close)
            :nil)
        (:t (. *window* :event msg))))
    (gui-sub-rpc *window*))
