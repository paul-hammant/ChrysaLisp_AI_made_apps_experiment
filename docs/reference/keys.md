# Key Bindings

## apps/debug/actions.inc

### *key_map*

```code
(ascii-code "p") action-play
(ascii-code "f") action-forward
(ascii-code "s") action-step
(ascii-code "h") action-pause
(ascii-code "x") action-clear
```

### *key_map_shift*

```code
(ascii-code "P") action-play-all
(ascii-code "F") action-forward-all
(ascii-code "S") action-step-all
(ascii-code "H") action-pause-all
(ascii-code "X") action-clear-all
```

## apps/docs/actions.inc

### *key_map_control*

```code
(ascii-code "n") action-next-doc
(ascii-code "N") action-prev-doc
(ascii-code "{") action-scale-down
(ascii-code "}") action-scale-up
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
```

## apps/edit/actions.inc

### *key_map*

```code
0x40000050 action-left
0x4000004f action-right
0x40000052 action-up
0x40000051 action-down
0x4000004A action-home
0x4000004D action-end
+char_lf action-break
+char_cr action-break
+char_backspace action-backspace
+char_delete action-delete
+char_tab action-tab
```

### *key_map_control*

```code
(ascii-code "0") action-macro-playback-0
(ascii-code "1") action-macro-playback-1
(ascii-code "2") action-macro-playback-2
(ascii-code "3") action-macro-playback-3
(ascii-code "4") action-macro-playback-4
(ascii-code "5") action-macro-playback-5
(ascii-code "6") action-macro-playback-6
(ascii-code "7") action-macro-playback-7
(ascii-code "8") action-macro-playback-8
(ascii-code "9") action-macro-playback-9
(ascii-code "!") action-macro-save-1
(ascii-code "@") action-macro-save-2
(ascii-code "#") action-macro-save-3
(ascii-code "$") action-macro-save-4
(ascii-code "%") action-macro-save-5
(ascii-code "^") action-macro-save-6
(ascii-code "&") action-macro-save-7
(ascii-code "*") action-macro-save-8
(ascii-code "(") action-macro-save-9
(ascii-code "M") action-macro-record
(ascii-code "m") action-macro-playback
(ascii-code "/") action-comment
(ascii-code "a") action-select-all
(ascii-code "A") action-region
(ascii-code "b") action-select-block
(ascii-code "B") action-cut-block
(ascii-code "w") action-select-word
(ascii-code "W") action-cut-word
(ascii-code "l") action-select-line
(ascii-code "L") action-cut-line
(ascii-code "p") action-select-paragraph
(ascii-code "P") action-cut-paragraph
(ascii-code "f") action-set-find-text
(ascii-code "r") action-replace
(ascii-code "R") action-replace-all
(ascii-code "y") action-collect
(ascii-code "Y") action-collect-global
(ascii-code "z") action-undo
(ascii-code "Z") action-redo
(ascii-code "s") action-save
(ascii-code "S") action-save-all
(ascii-code "t") action-trim
(ascii-code "x") action-cut
(ascii-code "c") action-copy
(ascii-code "v") action-paste
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
(ascii-code "n") action-next-buffer
(ascii-code "N") action-prev-buffer
(ascii-code "q") action-reflow
(ascii-code "Q") action-split
(ascii-code "u") action-to-upper
(ascii-code "U") action-to-lower
(ascii-code "i") action-invert
(ascii-code "o") action-sort
(ascii-code "O") action-unique
(ascii-code "{") action-scale-down
(ascii-code "}") action-scale-up
(ascii-code "[") action-left-bracket
(ascii-code "]") action-right-bracket
(ascii-code "d") action-push
(ascii-code "D") action-pop
(ascii-code "e") action-load-depends
(ascii-code "E") action-load-all-depends
(ascii-code "j") action-find-function
(ascii-code "J") action-pop
0x40000052 action-top
0x40000051 action-bottom
```

### *key_map_shift*

```code
0x40000050 action-left-select
0x4000004f action-right-select
0x40000052 action-up-select
0x40000051 action-down-select
0x4000004A action-home-select
0x4000004D action-end-select
+char_tab action-left-tab
```

## apps/mesh/actions.inc

### *key_map*

```code
(ascii-code "a") action-auto
(ascii-code "m") action-mode
```

### *key_map_control*

```code
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
```

## apps/molecule/actions.inc

### *key_map*

```code
(ascii-code "a") action-auto
(ascii-code "n") action-next
(ascii-code "p") action-prev
```

### *key_map_control*

```code
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
```

## apps/pcb/actions.inc

### *key_map*

```code
(ascii-code "a") action-mode-normal
(ascii-code "g") action-mode-gerber
(ascii-code "0") action-show-all
(ascii-code "1") action-show-1
(ascii-code "2") action-show-2
(ascii-code "3") action-show-3
(ascii-code "4") action-show-4
(ascii-code "r") action-reset
(ascii-code "n") action-next
(ascii-code "p") action-prev
```

### *key_map_control*

```code
(ascii-code "{") action-scale-down
(ascii-code "}") action-scale-up
```

## apps/profile/actions.inc

### *key_map*

```code
(ascii-code "x") action-clear
```

### *key_map_shift*

```code
(ascii-code "X") action-clear-all
```

## apps/template/actions.inc

### *key_map*

```code
(ascii-code "1") action-button-1
(ascii-code "2") action-button-2
(ascii-code "3") action-button-3
(ascii-code "4") action-button-4
```

### *key_map_control*

```code
(ascii-code "z") action-undo
(ascii-code "Z") action-redo
(ascii-code "x") action-cut
(ascii-code "c") action-copy
(ascii-code "v") action-paste
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
```

## apps/terminal/actions.inc

### *key_map*

```code
0x40000050 action-left
0x4000004f action-right
0x40000052 action-up
0x40000051 action-down
0x4000004A action-home
0x4000004D action-end
+char_lf action-break
+char_cr action-break
+char_backspace action-backspace
+char_delete action-delete
+char_tab action-tab
+char_esc action-escape
```

### *key_map_control*

```code
(ascii-code "w") action-select-word
(ascii-code "W") action-copy-word
(ascii-code "l") action-select-line
(ascii-code "L") action-copy-line
(ascii-code "p") action-select-paragraph
(ascii-code "P") action-copy-paragraph
(ascii-code "c") action-copy
(ascii-code "v") action-paste
(ascii-code "{") action-scale-down
(ascii-code "}") action-scale-up
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
```

### *key_map_shift*

```code
0x40000050 action-left-select
0x4000004f action-right-select
0x4000004A action-home-select
0x4000004D action-end-select
```

## apps/viewer/actions.inc

### *key_map*

```code
0x40000050 action-left
0x4000004f action-right
0x40000052 action-up
0x40000051 action-down
0x4000004A action-home
0x4000004D action-end
```

### *key_map_control*

```code
(ascii-code "f") action-set-find-text
(ascii-code "a") action-select-all
(ascii-code "A") action-region
(ascii-code "b") action-select-block
(ascii-code "B") action-copy-block
(ascii-code "w") action-select-word
(ascii-code "W") action-copy-word
(ascii-code "l") action-select-line
(ascii-code "L") action-copy-line
(ascii-code "p") action-select-paragraph
(ascii-code "P") action-copy-paragraph
(ascii-code "c") action-copy
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
(ascii-code "{") action-scale-down
(ascii-code "}") action-scale-up
(ascii-code "[") action-left-bracket
(ascii-code "]") action-right-bracket
(ascii-code "9") action-left-bracket
(ascii-code "0") action-right-bracket
(ascii-code "d") action-push
(ascii-code "D") action-pop
0x40000052 action-top
0x40000051 action-bottom
```

### *key_map_shift*

```code
0x40000050 action-left-select
0x4000004f action-right-select
0x40000052 action-up-select
0x40000051 action-down-select
0x4000004A action-home-select
0x4000004D action-end-select
```

## apps/whiteboard/actions.inc

### *key_map_control*

```code
(ascii-code "=") action-maximise
(ascii-code "-") action-minimise
```

