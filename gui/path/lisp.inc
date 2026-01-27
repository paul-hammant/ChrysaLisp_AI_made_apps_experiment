;lisp bindings
(ffi "gui/path/lisp_gen_arc" path-gen-arc)
; (path-gen-arc cx cy start end radius dst) -> dst
(ffi "gui/path/lisp_gen_cubic" path-gen-cubic)
; (path-gen-cubic p1x p1y p2x p2y p3x p3y p4x p4y dst) -> dst
(ffi "gui/path/lisp_gen_quadratic" path-gen-quadratic)
; (path-gen-quadratic p1x p1y p2x p2y p3x p3y dst) -> dst
(ffi "gui/path/lisp_filter" path-filter)
; (path-filter tol src dst) -> dst
(ffi "gui/path/lisp_simplify" path-simplify)
; (path-simplify tol src dst) -> dst
(ffi "gui/path/lisp_stroke_polygon" path-stroke-polygon)
; (path-stroke-polygon path radius join) -> paths
(ffi "gui/path/lisp_stroke_polyline" path-stroke-polyline)
; (path-stroke-polyline path radius join cap1 cap2) -> path
(ffi "gui/path/lisp_transform" path-transform)
; (path-transform m3x2 src dst) -> dst
(ffi "gui/path/lisp_svg" path-svg)
; (path-svg d) -> commands

(enums +join 0
	(enum miter bevel round))

(enums +cap 0
	(enum butt square tri arrow round))

(defun atan2 (y x)
	; (atan2 y x) -> angle
	; Four-quadrant arctangent using Newton-Raphson on sin/cos
	(cond
		((and (= x 0.0) (= y 0.0)) 0.0)
		((and (= x 0.0) (> y 0.0)) +fp_hpi)
		((and (= x 0.0) (< y 0.0)) (neg +fp_hpi))
		(:t
			(defq r (sqrt (+ (* x x) (* y y)))
				c (/ x r) s (/ y r)
				theta (if (>= c 0.0) 0.0 (if (>= s 0.0) +fp_pi (neg +fp_pi))))
			;Newton-Raphson: solve cos(t)=c, sin(t)=s
			(defq i 0)
			(while (< (++ i) 10)
				(defq ct (cos theta) st (sin theta)
					dc (- ct c) ds (- st s))
				(when (and (< (abs dc) 0.00001) (< (abs ds) 0.00001))
					(setq i 100))
				(setq theta (- theta (* dc st) (* ds (neg ct)))))
			theta)))

(defun acos (x)
	; (acos x) -> angle
	; Arc cosine using atan2
	(cond
		((<= x -1.0) +fp_pi)
		((>= x 1.0) 0.0)
		(:t (atan2 (sqrt (- 1.0 (* x x))) x))))

(defun path-smooth (src)
	; (path-smooth src) -> dst
	(cond
		((> (length src) 4)
			(defq out (path) src (partition src 2)
				last_point (first src) last_mid_point last_point
				mid_point last_mid_point)
			(each (# (setq last_mid_point mid_point
				mid_point (nums-add last_point (nums-scale (nums-sub %0 last_point) 0.5)))
				(path-gen-quadratic
					(first last_mid_point) (second last_mid_point)
					(first last_point) (second last_point)
					(first mid_point) (second mid_point)
					out)
				(setq last_point %0)) src)
			(push out (first last_point) (second last_point)))
		(src)))

(defun path-gen-rect (x y x1 y1 rx ry dst)
	; (path-gen-rect x y x1 y1 rx ry dst) -> dst
	(cond
		((and rx ry)
			(defq x (+ x rx) y (+ y ry) x1 (- x1 rx) y1 (- y1 ry))
			(path-gen-arc x y +fp_pi +fp_hpi rx dst)
			(path-gen-arc x y1 (const (+ +fp_pi +fp_hpi)) +fp_hpi rx dst)
			(path-gen-arc x1 y1 0.0 +fp_hpi rx dst)
			(path-gen-arc x1 y +fp_hpi +fp_hpi rx dst))
		((path x y x y1 x1 y1 x1 y))))

(defun path-gen-ellipse (cx cy rx ry dst)
	; (path-gen-ellipse cx cy rx ry dst) -> dst
	(defq s 0.1 a (neg s))
	(while (< (++ a s) +fp_2pi)
		(push dst (+ cx (* rx (sin a))) (+ cy (* ry (cos a)))))
	dst)

(defun path-gen-svg-arc (x1 y1 rx ry phi fa fs x2 y2 dst)
	; (path-gen-svg-arc x1 y1 rx ry phi fa fs x2 y2 dst) -> dst
	; SVG arc: endpoint parameterization to points
	; x1,y1 = start point, x2,y2 = end point
	; rx,ry = radii, phi = x-axis rotation (radians)
	; fa = large-arc-flag, fs = sweep-flag
	(cond
		;degenerate: zero radius -> line
		((or (= rx 0.0) (= ry 0.0))
			(push dst x2 y2))
		;degenerate: same point -> nothing
		((and (= x1 x2) (= y1 y2))
			dst)
		(:t
			;ensure positive radii
			(setq rx (abs rx) ry (abs ry))
			;precompute trig
			(defq cp (cos phi) sp (sin phi))
			;step 1: compute (x1', y1') - midpoint in rotated coords
			(defq dx (* (- x1 x2) 0.5) dy (* (- y1 y2) 0.5)
				x1p (+ (* cp dx) (* sp dy))
				y1p (+ (* (neg sp) dx) (* cp dy)))
			;step 2: correct radii if too small
			(defq x1p2 (* x1p x1p) y1p2 (* y1p y1p)
				rx2 (* rx rx) ry2 (* ry ry)
				lambda (+ (/ x1p2 rx2) (/ y1p2 ry2)))
			(when (> lambda 1.0)
				(defq sl (sqrt lambda))
				(setq rx (* rx sl) ry (* ry sl)
					rx2 (* rx rx) ry2 (* ry ry)))
			;step 3: compute center in rotated coords
			(defq num (- (* rx2 ry2) (* rx2 y1p2) (* ry2 x1p2))
				den (+ (* rx2 y1p2) (* ry2 x1p2)))
			(defq sq (if (< num 0.0) 0.0 (/ num den))
				coef (* (if (= fa fs) -1.0 1.0) (sqrt sq))
				cxp (* coef (/ (* rx y1p) ry))
				cyp (* coef (neg (/ (* ry x1p) rx))))
			;step 4: compute center in original coords
			(defq mx (* (+ x1 x2) 0.5) my (* (+ y1 y2) 0.5)
				acx (+ (* cp cxp) (* (neg sp) cyp) mx)
				acy (+ (* sp cxp) (* cp cyp) my))
			;step 5: compute angles
			(defq ux (/ (- x1p cxp) rx) uy (/ (- y1p cyp) ry)
				vx (/ (- (neg x1p) cxp) rx) vy (/ (- (neg y1p) cyp) ry)
				;angle of (1,0) to (ux,uy)
				n1 (sqrt (+ (* ux ux) (* uy uy)))
				theta1 (if (>= uy 0.0)
					(acos (/ ux n1))
					(neg (acos (/ ux n1)))))
			;angle between (ux,uy) and (vx,vy)
			(defq n2 (sqrt (+ (* vx vx) (* vy vy)))
				dp (+ (* ux vx) (* uy vy))
				arg (max -1.0 (min 1.0 (/ dp (* n1 n2))))
				dtheta (if (>= (- (* ux vy) (* uy vx)) 0.0)
					(acos arg)
					(neg (acos arg))))
			;adjust dtheta based on sweep flag
			(cond
				((and (= fs 0.0) (> dtheta 0.0))
					(setq dtheta (- dtheta +fp_2pi)))
				((and (/= fs 0.0) (< dtheta 0.0))
					(setq dtheta (+ dtheta +fp_2pi))))
			;step 6: generate arc points
			(defq steps (max 4 (n2i (* (abs dtheta) (/ (+ rx ry) 2.0) 0.5)))
				da (/ dtheta (n2f steps)))
			(defq a theta1)
			(while (> (setq steps (dec steps)) -1)
				(setq a (+ a da))
				(defq px (* rx (cos a)) py (* ry (sin a))
					x (+ (* cp px) (* (neg sp) py) acx)
					y (+ (* sp px) (* cp py) acy))
				(push dst x y))))
	dst)

(defun path-gen-paths (d)
	; (path-gen-paths svg_d) -> ((:nil|:t path) ...)
	; :t closed, :nil open
	(defq i 0 paths (list) d (path-svg (cat d " "))
		cx 0.0 cy 0.0 cpx 0.0 cpy 0.0 last_cmd " ")
	(until (eql (defq cmd (elem-get d i)) "x")
		(++ i)
		(case cmd
			("M"
				(push paths (list :nil (defq p (path))))
				(while (num? (elem-get d i))
					(bind '(cpx cpy) (slice d i (++ i 2)))
					(push p cpx cpy)))
			("m"
				(push paths (list :nil (defq p (path))))
				(while (num? (elem-get d i))
					(bind '(x y) (slice d i (++ i 2)))
					(setq cpx (+ cpx x) cpy (+ cpy y))
					(push p cpx cpy)))
			("L"
				(while (num? (elem-get d i))
					(bind '(cpx cpy) (slice d i (++ i 2)))
					(push p cpx cpy)))
			("l"
				(while (num? (elem-get d i))
					(bind '(x y) (slice d i (++ i 2)))
					(setq cpx (+ cpx x) cpy (+ cpy y))
					(push p cpx cpy)))
			("H"
				(while (num? (elem-get d i))
					(bind '(cpx) (slice d i (++ i 1)))
					(push p cpx cpy)))
			("h"
				(while (num? (elem-get d i))
					(bind '(x) (slice d i (++ i)))
					(++ cpx x)
					(push p cpx cpy)))
			("V"
				(while (num? (elem-get d i))
					(bind '(cpy) (slice d i (++ i)))
					(push p cpx cpy)))
			("v"
				(while (num? (elem-get d i))
					(bind '(y) (slice d i (++ i)))
					(++ cpy y)
					(push p cpx cpy)))
			("C"
				(while (num? (elem-get d i))
					(bind '(x1 y1 x2 y2 x y) (slice d i (++ i 6)))
					(path-gen-cubic cpx cpy x1 y1 x2 y2 x y p)
					(setq cpx x cpy y cx x2 cy y2)))
			("c"
				(while (num? (elem-get d i))
					(bind '(x1 y1 x2 y2 x y) (slice d i (++ i 6)))
					(setq x1 (+ cpx x1) y1 (+ cpy y1)
						x2 (+ cpx x2) y2 (+ cpy y2)
						x (+ cpx x) y (+ cpy y))
					(path-gen-cubic cpx cpy x1 y1 x2 y2 x y p)
					(setq cpx x cpy y cx x2 cy y2)))
			("S"
				(while (num? (elem-get d i))
					(bind '(x2 y2 x y) (slice d i (++ i 4)))
					(if (find last_cmd "CScs")
						(defq x1 (- (* cpx 2.0) cx) y1 (- (* cpy 2.0) cy))
						(defq x1 cpx y1 cpy))
					(path-gen-cubic cpx cpy x1 y1 x2 y2 x y p)
					(setq cpx x cpy y cx x2 cy y2)))
			("s"
				(while (num? (elem-get d i))
					(bind '(x2 y2 x y) (slice d i (++ i 4)))
					(setq x2 (+ cpx x2) y2 (+ cpy y2)
						x (+ cpx x) y (+ cpy y))
					(if (find last_cmd "CScs")
						(defq x1 (- (* cpx 2.0) cx) y1 (- (* cpy 2.0) cy))
						(defq x1 cpx y1 cpy))
					(path-gen-cubic cpx cpy x1 y1 x2 y2 x y p)
					(setq cpx x cpy y cx x2 cy y2)))
			("Q"
				(while (num? (elem-get d i))
					(bind '(x1 y1 x y) (slice d i (++ i 4)))
					(path-gen-quadratic cpx cpy x1 y1 x y p)
					(setq cpx x cpy y cx x1 cy y1)))
			("q"
				(while (num? (elem-get d i))
					(bind '(x1 y1 x y) (slice d i (++ i 4)))
					(setq x1 (+ cpx x1) y1 (+ cpy y1)
						x (+ cpx x) y (+ cpy y))
					(path-gen-quadratic cpx cpy x1 y1 x y p)
					(setq cpx x cpy y cx x1 cy y1)))
			("T"
				(while (num? (elem-get d i))
					(bind '(x y) (slice d i (++ i 2)))
					(if (find last_cmd "QTqt")
						(defq x1 (- (* cpx 2.0) cx) y1 (- (* cpy 2.0) cy))
						(defq x1 cpx y1 cpy))
					(path-gen-quadratic cpx cpy x1 y1 x y p)
					(setq cpx x cpy y cx x1 cy y1)))
			("t"
				(while (num? (elem-get d i))
					(bind '(x y) (slice d i (++ i 2)))
					(setq x (+ cpx x) y (+ cpy y))
					(if (find last_cmd "QTqt")
						(defq x1 (- (* cpx 2.0) cx) y1 (- (* cpy 2.0) cy))
						(defq x1 cpx y1 cpy))
					(path-gen-quadratic cpx cpy x1 y1 x y p)
					(setq cpx x cpy y cx x1 cy y1)))
			("A"
				(while (num? (elem-get d i))
					(bind '(rx ry x_axis_rotation large_arc_flag sweep_flag x y)
						(slice d i (++ i 7)))
					(path-gen-svg-arc cpx cpy rx ry
						(* x_axis_rotation (/ +fp_pi 180.0))
						large_arc_flag sweep_flag x y p)
					(setq cpx x cpy y)))
			("a"
				(while (num? (elem-get d i))
					(bind '(rx ry x_axis_rotation large_arc_flag sweep_flag dx dy)
						(slice d i (++ i 7)))
					(defq x (+ cpx dx) y (+ cpy dy))
					(path-gen-svg-arc cpx cpy rx ry
						(* x_axis_rotation (/ +fp_pi 180.0))
						large_arc_flag sweep_flag x y p)
					(setq cpx x cpy y)))
			(("Z" "z")
				(bind '(cpx cpy) (slice p 0 2))
				(push p cpx cpy)
				(elem-set (last paths) 0 :t)))
		(setq last_cmd cmd))
	paths)

(defun path-dasharray (src dasharray offset)
	; (path-dasharray src dasharray offset) -> (path ...)
	; Convert a path to dashed segments based on dasharray pattern
	; dasharray is a list of dash/gap lengths, offset is starting offset
	(cond
		((or (not dasharray) (< (length dasharray) 2) (< (length src) 4))
			(list src))
		(:t
			(defq result (list) current (path)
				dash_idx 0 dash_len (length dasharray)
				remaining (- (first dasharray) (% offset (reduce (const +) dasharray 0.0)))
				drawing :t pts (partition src 2))
			(when (< remaining 0.0)
				(setq remaining (+ remaining (first dasharray))))
			(defq last_pt (first pts))
			(push current (first last_pt) (second last_pt))
			(each (lambda (pt)
				(defq dx (- (first pt) (first last_pt))
					dy (- (second pt) (second last_pt))
					seg_len (sqrt (+ (* dx dx) (* dy dy))))
				(when (> seg_len 0.0)
					(defq ux (/ dx seg_len) uy (/ dy seg_len)
						pos 0.0)
					(while (< pos seg_len)
						(defq step (min remaining (- seg_len pos)))
						(setq pos (+ pos step) remaining (- remaining step))
						(defq px (+ (first last_pt) (* ux pos))
							py (+ (second last_pt) (* uy pos)))
						(cond
							(drawing
								(push current px py)
								(when (<= remaining 0.0)
									(when (> (length current) 2)
										(push result current))
									(setq current (path) drawing :nil
										dash_idx (% (inc dash_idx) dash_len)
										remaining (elem-get dasharray dash_idx))))
							(:t
								(when (<= remaining 0.0)
									(setq current (path) drawing :t
										dash_idx (% (inc dash_idx) dash_len)
										remaining (elem-get dasharray dash_idx))
									(push current px py))))))
				(setq last_pt pt)) (rest pts))
			(when (and drawing (> (length current) 2))
				(push result current))
			result)))

(defun path-stroke-polylines (dst radius joint cap1 cap2 src)
	; (path-stroke-polylines dst radius join cap1 cap2 src) -> dst
	(each (lambda (p)
		(push dst (path-stroke-polyline p radius joint cap1 cap2))) src)
	dst)

(defun path-stroke-polygons (dst radius joint src)
	; (path-stroke-polygons dst radius join src) -> dst
	(each (lambda (p)
		(bind '(p p1) (path-stroke-polygon p radius joint))
		(push dst p p1)) src)
	dst)
