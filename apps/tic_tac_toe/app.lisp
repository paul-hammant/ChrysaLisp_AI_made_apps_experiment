(import "gui/lisp.inc")

(enums +event 0
    (enum close)
    (enum cell_click))

(defq board (make-array 9 :initial-element " ")
    current_player "X"
    game_over :nil)

(ui-window *window* ()
    (ui-title-bar _ "Tic-Tac-Toe" (0xea19) +event_close)
    (ui-grid *grid* (:grid_width 3 :grid_height 3 :color +argb_white)
        (each (lambda (i)
            (. (ui-button _ (:text (elem-get board i) :min_width 100 :min_height 100))
                :connect (+ +event_cell_click i)))
            (range 0 9))))

(defun check-winner ()
    (defq win_patterns '((0 1 2) (3 4 5) (6 7 8) (0 3 6) (1 4 7) (2 5 8) (0 4 8) (2 4 6)))
    (some (lambda (pattern)
        (let ((a (elem-get board (first pattern)))
              (b (elem-get board (second pattern)))
              (c (elem-get board (third pattern))))
          (and (not (eql a " ")) (eql a b) (eql b c))))
      win_patterns))

(defun reset-game ()
    (setq board (make-array 9 :initial-element " ")
          current_player "X"
          game_over :nil)
    (each (lambda (button)
        (def button :text ""))
      (. *grid* :children)))

(defun main ()
    (bind '(x y w h) (apply view-locate (. *window* :pref_size)))
    (gui-add-front-rpc (. *window* :change x y w h))
    (while (cond
        ((= (defq id (getf (defq msg (mail-read (task-netid))) +ev_msg_target_id)) +event_close)
            :nil)
        ((and (>= id +event_cell_click) (< id (+ +event_cell_click 9)))
            (unless game_over
                (let ((index (- id +event_cell_click)))
                  (when (eql (elem-get board index) " ")
                    (elem-set board index current_player)
                    (def (. (elem-get (. *grid* :children) index) :dirty) :text current_player)
                    (if (check-winner)
                        (setq game_over :t)
                        (setq current_player (if (eql current_player "X") "O" "X")))))))
        (:t (. *window* :event msg))))
    (gui-sub-rpc *window*))
