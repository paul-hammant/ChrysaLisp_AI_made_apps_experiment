(import "gui/lisp.inc")

(enums +event 0
    (enum close)
    (enum save)
    (enum new_note))

(defq notes (list)
    current_note :nil)

(ui-window *window* ()
    (ui-title-bar _ "Notes" (0xea19) +event_close)
    (ui-tool-bar *main_toolbar* ()
        (ui-buttons (0xe9e8) +event_new_note))
    (ui-flow _ (:flow_flags +flow_right_fill)
        (ui-label _ (:text "Notes:"))
        (. (ui-textfield note_title (:clear_text "" :hint_text "Note Title")) :connect +event_save))
    (ui-vdu note_content (:vdu_width 60 :vdu_height 20 :ink_color +argb_black)))

(defun save-note ()
    (when current_note
        (setf (getf current_note :title) (get :clear_text note_title))
        (setf (getf current_note :content) (. note_content :get_text))
        (setf notes (cons current_note (remove current_note notes)))))

(defun new-note ()
    (save-note)
    (setq current_note (scatter (Emap) :title "" :content ""))
    (set note_title :clear_text "")
    (. note_content :load '("") 0 0 0 0))

(defun main ()
    (bind '(x y w h) (apply view-locate (. *window* :pref_size)))
    (gui-add-front-rpc (. *window* :change x y w h))
    (new-note)
    (while (cond
        ((= (defq id (getf (defq msg (mail-read (task-netid))) +ev_msg_target_id)) +event_close)
            :nil)
        ((= id +event_save)
            (save-note))
        ((= id +event_new_note)
            (new-note))
        (:t (. *window* :event msg))))
    (gui-sub-rpc *window*))
