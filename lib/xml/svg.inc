;;;;;;;;;;;;
; svg parser
;;;;;;;;;;;;

(import "./parse.inc")
(import "lib/consts/colors.inc")
(import "gui/path/lisp.inc")
(import "gui/canvas/lisp.inc")

;module
(env-push)

(defun deg-to-rad (d)
	(/ (* d +fp_pi) 180.0))

(defmacro Mat3x2-f (m00 m01 m02 m10 m11 m12)
	`(fixeds ,m00 ,m01 ,m02 ,m10 ,m11 ,m12))

(defun Mat3x2-rotz-f (a)
	(defq ca (cos a) sa (sin a))
	(Mat3x2-f ca (* sa -1.0) 0.0 sa ca 0.0))

(defun Mat3x2-skewx-f (a)
	(defq ca (cos a) sa (sin a))
	(Mat3x2-f ca (* sa -1.0) 0.0 0.0 1.0 0.0))

(defun Mat3x2-skewy-f (a)
	(defq ca (cos a) sa (sin a))
	(Mat3x2-f 1.0 0.0 0.0 sa ca 0.0))

(defun mat3x2-mul-f (ma mb)
	; (mat3x2-mul-f mat3x2_a mat3x2_b) -> mat3x2-f
	(defq mar0 (slice ma 0 3) mar1 (slice ma 3 -1)
		mbr0 (slice mb 0 3) mbr1 (slice mb 3 -1)
		mbc0 (fixeds (first mbr0) (first mbr1))
		mbc1 (fixeds (second mbr0) (second mbr1))
		mbc2 (fixeds (third mbr0) (third mbr1) 1.0))
	(Mat3x2-f (nums-dot mbc0 mar0) (nums-dot mbc1 mar0) (nums-dot mbc2 mar0)
		(nums-dot mbc0 mar1) (nums-dot mbc1 mar1) (nums-dot mbc2 mar1)))

(defun read-col (val)
	(case (length val)
		(4 (canvas-to-argb32 (str-to-num (cat "0xf" (rest val))) 12))
		(7 (canvas-to-argb32 (str-to-num (cat "0x" (rest val))) 24))
		(:t (throw "Unknown # val !" val))))

(defun read-rgb (val)
	(bind '(r g b) (map (const str-to-num) (slice (split val (const (char-class "(), "))) 1 4)))
	(+ +argb_black (<< r 16) (<< g 8) b))

(defun read-rgba (val)
	; rgba(r, g, b, a) where a is 0-1
	(bind '(r g b a) (map (const str-to-num) (slice (split val (const (char-class "(), "))) 1 5)))
	(+ (<< (n2i (* (n2f a) 255.0)) 24) (<< r 16) (<< g 8) b))

(defun hsl-to-rgb (h s l)
	; Convert HSL to RGB, h in degrees, s and l in 0-1
	(defq h (/ (% h 360.0) 360.0))
	(if (= s 0.0)
		;achromatic
		(defq r l g l b l)
		(progn
			(defq q (if (< l 0.5) (* l (+ 1.0 s)) (- (+ l s) (* l s))))
			(defq p (- (* 2.0 l) q))
			(defun hue-to-rgb (p q frac)
				(defq frac (% (+ frac 1.0) 1.0))
				(cond
					((< frac (/ 1.0 6.0)) (+ p (* (- q p) 6.0 frac)))
					((< frac 0.5) q)
					((< frac (/ 2.0 3.0)) (+ p (* (- q p) (- (/ 2.0 3.0) frac) 6.0)))
					(:t p)))
			(defq r (hue-to-rgb p q (+ h (/ 1.0 3.0)))
				g (hue-to-rgb p q h)
				b (hue-to-rgb p q (- h (/ 1.0 3.0))))))
	(list (n2i (* r 255.0)) (n2i (* g 255.0)) (n2i (* b 255.0))))

(defun read-hsl (val)
	; hsl(h, s%, l%)
	(defq parts (slice (split val (const (char-class "(),% "))) 1 -1))
	(defq parts (filter (lambda (p) (> (length p) 0)) parts))
	(bind '(h s l) (map (const str-to-num) (slice parts 0 3)))
	(bind '(r g b) (hsl-to-rgb (n2f h) (/ (n2f s) 100.0) (/ (n2f l) 100.0)))
	(+ +argb_black (<< r 16) (<< g 8) b))

(defun read-hsla (val)
	; hsla(h, s%, l%, a)
	(defq parts (slice (split val (const (char-class "(),% "))) 1 -1))
	(defq parts (filter (lambda (p) (> (length p) 0)) parts))
	(bind '(h s l a) (map (const str-to-num) (slice parts 0 4)))
	(bind '(r g b) (hsl-to-rgb (n2f h) (/ (n2f s) 100.0) (/ (n2f l) 100.0)))
	(+ (<< (n2i (* (n2f a) 255.0)) 24) (<< r 16) (<< g 8) b))

;SVG 1.1 named colors lookup
(defq +svg-colors (scatter (Fmap 101)
	"aliceblue" 0xfff0f8ff "antiquewhite" 0xfffaebd7 "aqua" 0xff00ffff
	"aquamarine" 0xff7fffd4 "azure" 0xfff0ffff "beige" 0xfff5f5dc
	"bisque" 0xffffe4c4 "black" 0xff000000 "blanchedalmond" 0xffffebcd
	"blue" 0xff0000ff "blueviolet" 0xff8a2be2 "brown" 0xffa52a2a
	"burlywood" 0xffdeb887 "cadetblue" 0xff5f9ea0 "chartreuse" 0xff7fff00
	"chocolate" 0xffd2691e "coral" 0xffff7f50 "cornflowerblue" 0xff6495ed
	"cornsilk" 0xfffff8dc "crimson" 0xffdc143c "cyan" 0xff00ffff
	"darkblue" 0xff00008b "darkcyan" 0xff008b8b "darkgoldenrod" 0xffb8860b
	"darkgray" 0xffa9a9a9 "darkgreen" 0xff006400 "darkgrey" 0xffa9a9a9
	"darkkhaki" 0xffbdb76b "darkmagenta" 0xff8b008b "darkolivegreen" 0xff556b2f
	"darkorange" 0xffff8c00 "darkorchid" 0xff9932cc "darkred" 0xff8b0000
	"darksalmon" 0xffe9967a "darkseagreen" 0xff8fbc8f "darkslateblue" 0xff483d8b
	"darkslategray" 0xff2f4f4f "darkslategrey" 0xff2f4f4f "darkturquoise" 0xff00ced1
	"darkviolet" 0xff9400d3 "deeppink" 0xffff1493 "deepskyblue" 0xff00bfff
	"dimgray" 0xff696969 "dimgrey" 0xff696969 "dodgerblue" 0xff1e90ff
	"firebrick" 0xffb22222 "floralwhite" 0xfffffaf0 "forestgreen" 0xff228b22
	"fuchsia" 0xffff00ff "gainsboro" 0xffdcdcdc "ghostwhite" 0xfff8f8ff
	"gold" 0xffffd700 "goldenrod" 0xffdaa520 "gray" 0xff808080
	"green" 0xff008000 "greenyellow" 0xffadff2f "grey" 0xff808080
	"honeydew" 0xfff0fff0 "hotpink" 0xffff69b4 "indianred" 0xffcd5c5c
	"indigo" 0xff4b0082 "ivory" 0xfffffff0 "khaki" 0xfff0e68c
	"lavender" 0xffe6e6fa "lavenderblush" 0xfffff0f5 "lawngreen" 0xff7cfc00
	"lemonchiffon" 0xfffffacd "lightblue" 0xffadd8e6 "lightcoral" 0xfff08080
	"lightcyan" 0xffe0ffff "lightgoldenrodyellow" 0xfffafad2 "lightgray" 0xffd3d3d3
	"lightgreen" 0xff90ee90 "lightgrey" 0xffd3d3d3 "lightpink" 0xffffb6c1
	"lightsalmon" 0xffffa07a "lightseagreen" 0xff20b2aa "lightskyblue" 0xff87cefa
	"lightslategray" 0xff778899 "lightslategrey" 0xff778899 "lightsteelblue" 0xffb0c4de
	"lightyellow" 0xffffffe0 "lime" 0xff00ff00 "limegreen" 0xff32cd32
	"linen" 0xfffaf0e6 "magenta" 0xffff00ff "maroon" 0xff800000
	"mediumaquamarine" 0xff66cdaa "mediumblue" 0xff0000cd "mediumorchid" 0xffba55d3
	"mediumpurple" 0xff9370db "mediumseagreen" 0xff3cb371 "mediumslateblue" 0xff7b68ee
	"mediumspringgreen" 0xff00fa9a "mediumturquoise" 0xff48d1cc "mediumvioletred" 0xffc71585
	"midnightblue" 0xff191970 "mintcream" 0xfff5fffa "mistyrose" 0xffffe4e1
	"moccasin" 0xffffe4b5 "navajowhite" 0xffffdead "navy" 0xff000080
	"oldlace" 0xfffdf5e6 "olive" 0xff808000 "olivedrab" 0xff6b8e23
	"orange" 0xffffa500 "orangered" 0xffff4500 "orchid" 0xffda70d6
	"palegoldenrod" 0xffeee8aa "palegreen" 0xff98fb98 "paleturquoise" 0xffafeeee
	"palevioletred" 0xffdb7093 "papayawhip" 0xffffefd5 "peachpuff" 0xffffdab9
	"peru" 0xffcd853f "pink" 0xffffc0cb "plum" 0xffdda0dd
	"powderblue" 0xffb0e0e6 "purple" 0xff800080 "rebeccapurple" 0xff663399
	"red" 0xffff0000 "rosybrown" 0xffbc8f8f "royalblue" 0xff4169e1
	"saddlebrown" 0xff8b4513 "salmon" 0xfffa8072 "sandybrown" 0xfff4a460
	"seagreen" 0xff2e8b57 "seashell" 0xfffff5ee "sienna" 0xffa0522d
	"silver" 0xffc0c0c0 "skyblue" 0xff87ceeb "slateblue" 0xff6a5acd
	"slategray" 0xff708090 "slategrey" 0xff708090 "snow" 0xfffffafa
	"springgreen" 0xff00ff7f "steelblue" 0xff4682b4 "tan" 0xffd2b48c
	"teal" 0xff008080 "thistle" 0xffd8bfd8 "tomato" 0xffff6347
	"turquoise" 0xff40e0d0 "violet" 0xffee82ee "wheat" 0xfff5deb3
	"white" 0xffffffff "whitesmoke" 0xfff5f5f5 "yellow" 0xffffff00
	"yellowgreen" 0xff9acd32))

(defun svg-color (name)
	; (svg-color name) -> argb | :nil
	(. +svg-colors :find name))

;gradient color interpolation
(defun lerp-color (c1 c2 frac)
	; (lerp-color c1 c2 frac) -> interpolated color
	; frac is 0.0-1.0
	(defq a1 (n2f (>>> (logand c1 0xff000000) 24))
		r1 (n2f (>>> (logand c1 0xff0000) 16))
		g1 (n2f (>>> (logand c1 0xff00) 8))
		b1 (n2f (logand c1 0xff))
		a2 (n2f (>>> (logand c2 0xff000000) 24))
		r2 (n2f (>>> (logand c2 0xff0000) 16))
		g2 (n2f (>>> (logand c2 0xff00) 8))
		b2 (n2f (logand c2 0xff))
		frac1 (- 1.0 frac))
	(+ (<< (n2i (+ (* a1 frac1) (* a2 frac))) 24)
		(<< (n2i (+ (* r1 frac1) (* r2 frac))) 16)
		(<< (n2i (+ (* g1 frac1) (* g2 frac))) 8)
		(n2i (+ (* b1 frac1) (* b2 frac)))))

(defun gradient-color-at (stops offset &optional spread)
	; (gradient-color-at stops offset [spread]) -> color
	; stops is list of (offset color) pairs sorted by offset
	; spread is :pad (default), :repeat, or :reflect
	(setd spread :pad)
	;apply spread method to offset
	(cond
		((eql spread :repeat)
			;tile the gradient
			(setq offset (- offset (floor offset)))
			(when (< offset 0.0) (setq offset (+ offset 1.0))))
		((eql spread :reflect)
			;mirror/bounce the gradient
			(setq offset (abs offset))
			(defq cycle (n2i (floor offset)))
			(setq offset (- offset (n2f cycle)))
			(when (= (logand cycle 1) 1) (setq offset (- 1.0 offset)))))
	;now offset is clamped/adjusted, get color
	(cond
		((<= offset (first (first stops)))
			(second (first stops)))
		((>= offset (first (last stops)))
			(second (last stops)))
		(:t
			;find the two stops we're between
			(defq prev (first stops))
			(some (lambda (stop)
				(when (>= offset (first stop))
					(setq prev stop)
					:nil)
				(when (< offset (first stop))
					;interpolate between prev and stop
					(defq blend (/ (- offset (first prev))
							(- (first stop) (first prev))))
					(lerp-color (second prev) (second stop) blend)))
				(rest stops)))))

(defun read-transform (entry val)
	(defq stack (reverse (split val ")")) ma (. entry :find "transform"))
	(while (defq transform (pop stack))
		(defq args (split transform (const (char-class "(, \t\n")))
			key (first args)
			vals (map (# (n2f (str-to-num %0))) (rest args))
			mb (case key
			("matrix"
				(bind '(m00 m01 m10 m11 tx ty) vals)
				(Mat3x2-f m00 m01 tx m10 m11 ty))
			("translate"
				(bind '(tx &optional ty) vals)
				(setd ty 0.0)
				(Mat3x2-f 1.0 0.0 tx 0.0 1.0 ty))
			("scale"
				(bind '(sx &optional sy) vals)
				(setd sy sx)
				(Mat3x2-f sx 0.0 0.0 0.0 sy 0.0))
			("rotate"
				(bind '(a &optional tx ty) vals)
				(setd tx 0.0 ty 0.0)
				(defq mb (Mat3x2-rotz-f (deg-to-rad a)))
				(bind '(m00 m01 m02 m10 m11 m12) mb)
				(bind '(rx ry) (path-transform mb (path tx ty) (path 0 0)))
				(Mat3x2-f m00 m01 (- tx rx) m10 m11 (- ty ry)))
			("skewX"
				(bind '(a) vals)
				(Mat3x2-skewx-f (* (deg-to-rad a) -1.0)))
			("skewY"
				(bind '(a) vals)
				(Mat3x2-skewy-f (deg-to-rad a)))
			(:t (throw "Unknown transform !" key))))
		(setq ma (mat3x2-mul-f ma mb)))
	ma)

(defun parse-numeric (val)
	; Parse numeric value, stripping common CSS units (px, pt, em, rem, %, etc.)
	; Returns 0.0 for empty/auto/none values
	(cond
		((or (eql val "") (eql val "auto") (eql val "none")) 0.0)
		((ends-with "px" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "pt" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "em" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "ex" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "pc" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "cm" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "mm" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "in" val) (n2f (str-to-num (slice val 0 (- (length val) 2)))))
		((ends-with "%" val) (n2f (str-to-num (slice val 0 (dec (length val))))))
		((ends-with "rem" val) (n2f (str-to-num (slice val 0 (- (length val) 3)))))
		(:t (n2f (str-to-num val)))))

(defun read-attribute (entry key val)
	;handle inherit keyword for any attribute
	(if (eql val "inherit")
		(. entry :find key)
		(case key
			(("x" "y" "x1" "y1" "x2" "y2" "rx" "ry" "cx" "cy" "r"
				"width" "height" "stroke-width" "fill-opacity" "stroke-opacity" "opacity"
				"dx" "dy")
				(parse-numeric val))
		("viewBox"
			(map (# (n2f (str-to-num %0))) (split val (const (char-class ", ")))))
		("points"
			(reduce (# (push %0 (n2f (str-to-num %1)))) (split val (const (char-class ", "))) (path)))
		("transform"
			(read-transform entry val))
		(("stroke" "fill")
			(cond
				((eql val "none") 0)
				((eql val "transparent") 0)
				((eql val "currentColor")
					;inherit from color property or use black
					(defq color (. entry :find "color"))
					(if color color +argb_black))
				((starts-with "#" val) (read-col val))
				((starts-with "rgba(" val) (read-rgba val))
				((starts-with "rgb(" val) (read-rgb val))
				((starts-with "hsla(" val) (read-hsla val))
				((starts-with "hsl(" val) (read-hsl val))
				((starts-with "url(#" val)
					;gradient or pattern reference - return as string for lookup later
					val)
				((svg-color val))
				(:t 0)))
		("stroke-linecap"
			(case val
				("butt" +cap_butt)
				("round" +cap_round)
				("square" +cap_square)
				((throw "Unknown stroke-linecap style !" val))))
		("stroke-linejoin"
			(case val
				("miter" +join_miter)
				("bevel" +join_bevel)
				("round" +join_round)
				("miter-clip" +join_miter)
				("arcs" +join_miter)
				((throw "Unknown stroke-linejoin style !" val))))
		("fill-rule"
			(case val
				("nonzero" +winding_none_zero)
				("evenodd" +winding_odd_even)
				((throw "Unknown fill-rule !" val))))
		("clip-rule"
			;same as fill-rule but for clipping paths
			(case val
				("nonzero" +winding_none_zero)
				("evenodd" +winding_odd_even)
				(:t +winding_none_zero)))
		("stroke-dasharray"
			(if (eql val "none")
				:nil
				(map (# (parse-numeric %0)) (split val (const (char-class ", "))))))
		("stroke-dashoffset"
			(parse-numeric val))
		("stroke-miterlimit"
			(parse-numeric val))
		("color"
			;CSS color property - used by currentColor keyword
			(cond
				((eql val "none") +argb_black)
				((starts-with "#" val) (read-col val))
				((starts-with "rgba(" val) (read-rgba val))
				((starts-with "rgb(" val) (read-rgb val))
				((starts-with "hsla(" val) (read-hsla val))
				((starts-with "hsl(" val) (read-hsl val))
				((svg-color val))
				(:t +argb_black)))
		("visibility"
			(case val
				("visible" "visible")
				("hidden" "hidden")
				("collapse" "hidden")
				(:t "visible")))
		("display"
			(if (eql val "none") "none" "inline"))
		("font-weight"
			(cond
				((eql val "normal") "Regular")
				((eql val "bold") "Bold")
				((eql val "bolder") "Bolder")
				((eql val "lighter") "Lighter")
				;numeric weights: 100-500 = Regular, 600-900 = Bold
				((and (>= (length val) 1) (<= (length val) 3))
					(defq w (str-to-num val))
					(if (>= w 600) "Bold" "Regular"))
				(:t "Regular")))
		("font-size"
			(parse-numeric val))
		("font-family"
			;return OpenSans for now - can be extended later
			"OpenSans")
		("font-style"
			;normal, italic, oblique - map to font variant suffix
			(case val
				("normal" "")
				("italic" "Italic")
				("oblique" "Italic")
				(:t "")))
		("text-anchor"
			(case val
				("start" "start")
				("middle" "middle")
				("end" "end")
				((throw "Unknown text-anchor !" val))))
		("dominant-baseline"
			(case val
				("auto" "auto")
				("middle" "middle")
				("central" "middle")
				("hanging" "hanging")
				("text-before-edge" "hanging")
				("text-after-edge" "auto")
				("alphabetic" "auto")
				("ideographic" "auto")
				("mathematical" "middle")
				(:t "auto")))
		("d"
			(path-gen-paths val))
		;silently ignore unimplemented presentation attributes
		(("enable-background" "overflow" "clip" "clip-path" "mask"
			"filter" "flood-color" "flood-opacity" "lighting-color"
			"color-interpolation" "color-interpolation-filters" "color-profile"
			"color-rendering" "image-rendering" "shape-rendering" "text-rendering"
			"alignment-baseline" "baseline-shift" "glyph-orientation-horizontal"
			"glyph-orientation-vertical" "kerning" "text-decoration"
			"unicode-bidi" "writing-mode" "direction" "cursor" "pointer-events"
			"class" "style" "xml:space" "preserveAspectRatio" "vector-effect"
			"paint-order")
			:nil)
		(("marker" "marker-start" "marker-mid" "marker-end")
			;extract marker id from "url(#id)" or "none"
			(cond
				((eql val "none") :nil)
				((starts-with "url(#" val)
					(slice val 5 (dec (length val))))
				(:t val)))
		(:t val))))

(defun push-attributes (stack keys vals &optional css_rules element_name)
	(push stack (defq entry (. (last stack) :copy)))
	;apply CSS rules first (lower priority than inline styles) - if css_rules is a map
	;
	;apply element attributes (inline styles have highest priority)
	(each (lambda (key val)
		(cond
			((eql key "style")
				;parse CSS style attribute: "prop1:val1; prop2:val2; ..."
				(each (lambda (pair)
						(when (> (length pair) 0)
							(defq parts (split pair ":"))
							(when (> (length parts) 1)
								(defq k (trim (elem-get parts 0) " \t")
									v (trim (elem-get parts 1) " \t"))
								(when (and (> (length k) 0) (> (length v) 0))
									(. entry :insert k (read-attribute entry k v))))))
					(split val ";")))
			(:t (setq val (read-attribute entry key val))))
		(. entry :insert key val)) keys vals)
	entry)

(defun parse-css-rules (css_text)
	; (parse-css-rules css_text) -> Fmap of selector -> props-list
	; Return empty Fmap for now to debug
	(Fmap 17))

(defun apply-props-to-entry (entry props)
	; Helper to apply property list to entry
	(when (and props (> (length props) 1))
		(defq i 0 n (length props))
		(while (< (inc i) n)
			(defq k (elem-get props i) v (elem-get props (inc i)))
			(when (and (str? k) (str? v))
				(. entry :insert k (read-attribute entry k v)))
			(setq i (+ i 2)))))

(defun apply-css-rules (entry element_name keys vals css_rules)
	; Apply CSS rules to entry based on element name, class, and id
	; Simplified version that just returns without doing anything for debugging
	:nil)

(defun path-bounding-box (paths)
	; (path-bounding-box paths) -> (minx miny maxx maxy)
	(defq minx 999999.0 miny 999999.0 maxx -999999.0 maxy -999999.0)
	(each (lambda ((f p))
		(defq pts (partition p 2))
		(each (lambda ((x y))
			(when (< x minx) (setq minx x))
			(when (< y miny) (setq miny y))
			(when (> x maxx) (setq maxx x))
			(when (> y maxy) (setq maxy y)))
			pts))
		paths)
	(list minx miny maxx maxy))

(defun linear-gradient-fill-bands (canvas minx miny maxx maxy gx1 gy1 gx2 gy2 stops spread fill_opacity num_bands)
	; Fill a rectangular region with linear gradient color bands
	(defq dx (- gx2 gx1)
		dy (- gy2 gy1)
		width (- maxx minx)
		height (- maxy miny))
	(cond
		;horizontal gradient (left to right)
		((< (abs dy) 0.001)
			(defq band_width (/ width (n2f num_bands)))
			(defq i 0)
			(while (< i num_bands)
				(defq fi (n2f i)
					bx (+ minx (* fi band_width))
					frac (/ (+ fi 0.5) (n2f num_bands))
					col (gradient-color-at stops frac spread))
				(.-> canvas
					(:set_color (+ (<< (n2i (* fill_opacity 0xff.0)) 24) (logand col 0xffffff)))
					(:fbox (n2i bx) (n2i miny) (n2i (+ band_width 1.0)) (n2i height)))
				(setq i (inc i))))
		;vertical gradient (top to bottom)
		((< (abs dx) 0.001)
			(defq band_height (/ height (n2f num_bands)))
			(defq i 0)
			(while (< i num_bands)
				(defq fi (n2f i)
					by (+ miny (* fi band_height))
					frac (/ (+ fi 0.5) (n2f num_bands))
					col (gradient-color-at stops frac spread))
				(.-> canvas
					(:set_color (+ (<< (n2i (* fill_opacity 0xff.0)) 24) (logand col 0xffffff)))
					(:fbox (n2i minx) (n2i by) (n2i width) (n2i (+ band_height 1.0))))
				(setq i (inc i))))
		;diagonal gradient - render as horizontal bands with color based on y position
		(:t
			;normalize gradient direction
			(defq len (sqrt (+ (* dx dx) (* dy dy))))
			(when (> len 0.001)
				(setq dx (/ dx len) dy (/ dy len)))
			;render in bands
			(defq band_height (max 1.0 (/ height (n2f num_bands))))
			(defq i 0)
			(while (< i num_bands)
				(defq fi (n2f i)
					by (+ miny (* fi band_height))
					;calculate gradient fraction based on center of band
					center_x (+ minx (* 0.5 width))
					center_y (+ by (* 0.5 band_height))
					;project onto gradient vector (relative to bbox)
					rel_x (/ (- center_x minx) width)
					rel_y (/ (- center_y miny) height)
					;calculate fraction along gradient direction
					frac (+ (* rel_x dx) (* rel_y dy))
					col (gradient-color-at stops frac spread))
				(.-> canvas
					(:set_color (+ (<< (n2i (* fill_opacity 0xff.0)) 24) (logand col 0xffffff)))
					(:fbox (n2i minx) (n2i by) (n2i width) (n2i (+ band_height 1.0))))
				(setq i (inc i))))))

(defun radial-gradient-fill (canvas minx miny maxx maxy cx cy r fx fy stops spread fill_opacity num_bands)
	; Fill with radial gradient using concentric squares (approximation)
	; fx/fy is the focal point - use as rendering center for gradient effect
	(defq width (- maxx minx)
		height (- maxy miny)
		;use focal point as rendering center (provides offset gradient effect)
		px_cx (+ minx (* fx width))
		px_cy (+ miny (* fy height))
		;radius in pixels (use max of width/height scaled by r)
		max_dim (if (> width height) width height)
		px_r (* r max_dim))
	;draw concentric squares from outside to inside
	(defq i (dec num_bands))
	(while (>= i 0)
		(defq fi (n2f i)
			frac (/ (+ fi 0.5) (n2f num_bands))
			col (gradient-color-at stops frac spread)
			;current radius
			curr_r (* px_r frac)
			;box bounds
			bx1 (- px_cx curr_r)
			by1 (- px_cy curr_r)
			bw (* curr_r 2.0)
			bh (* curr_r 2.0))
		(.-> canvas
			(:set_color (+ (<< (n2i (* fill_opacity 0xff.0)) 24) (logand col 0xffffff)))
			(:fbox (n2i bx1) (n2i by1) (n2i (+ bw 1.0)) (n2i (+ bh 1.0))))
		(setq i (dec i))))

(defun gradient-fill (canvas paths gradient transform fill_opacity fill_rule)
	; (gradient-fill canvas paths gradient transform fill_opacity fill_rule)
	; Fill paths with gradient (linear or radial)
	(defq grad_type (first gradient))
	;get bounding box
	(bind '(minx miny maxx maxy) (path-bounding-box paths))
	(defq width (- maxx minx)
		height (- maxy miny)
		max_dim (if (> width height) width height))
	;use more bands for better gradient quality (min 32, scale by dimension/2)
	(defq num_bands (max 32 (n2i (/ max_dim 2.0))))
	(case grad_type
		(:linear
			(bind '(_ gx1 gy1 gx2 gy2 grad_units spread stops) gradient)
			;for userSpaceOnUse, convert absolute coords to relative (0-1) for bounding box
			(when (eql grad_units :user)
				(setq gx1 (/ (- gx1 minx) width)
					gy1 (/ (- gy1 miny) height)
					gx2 (/ (- gx2 minx) width)
					gy2 (/ (- gy2 miny) height)))
			(linear-gradient-fill-bands canvas minx miny maxx maxy gx1 gy1 gx2 gy2 stops spread fill_opacity num_bands))
		(:radial
			(bind '(_ cx cy r fx fy grad_units spread stops) gradient)
			;for userSpaceOnUse, convert absolute coords to relative (0-1) for bounding box
			(when (eql grad_units :user)
				(setq cx (/ (- cx minx) width)
					cy (/ (- cy miny) height)
					fx (/ (- fx minx) width)
					fy (/ (- fy miny) height)
					r (/ r max_dim)))
			(radial-gradient-fill canvas minx miny maxx maxy cx cy r fx fy stops spread fill_opacity num_bands))))

(defun pattern-fill (canvas paths pattern transform fill_opacity fill_rule defs)
	; (pattern-fill canvas paths pattern transform fill_opacity fill_rule defs)
	; Fill paths with tiled pattern
	(bind '(_ px py pw ph pat_units pat_content_units content) pattern)
	(when (and (> pw 0.0) (> ph 0.0))
		;get bounding box of paths
		(bind '(minx miny maxx maxy) (path-bounding-box paths))
		(defq width (- maxx minx) height (- maxy miny))
		;calculate pattern tile dimensions
		(defq tile_w (if (eql pat_units :bbox) (* pw width) pw)
			tile_h (if (eql pat_units :bbox) (* ph height) ph)
			start_x (if (eql pat_units :bbox) (+ minx (* px width)) px)
			start_y (if (eql pat_units :bbox) (+ miny (* py height)) py))
		;TODO: when pattern content is stored, render tiles here
		;for now, just fill with a placeholder color
		(.-> canvas
			(:set_color (+ (<< (n2i (* fill_opacity 0xff.0)) 24) 0x808080))
			(:fpoly 0.0 0.0 fill_rule
				(map (lambda ((f p)) (path-transform transform p (cat p))) paths)))))

(defun path-length (p)
	; (path-length path) -> float
	; Calculate total length of a path
	(defq len 0.0 pts (partition p 2) prev :nil)
	(each (lambda ((x y))
		(when prev
			(bind '(px py) prev)
			(defq dx (- x px) dy (- y py))
			(setq len (+ len (sqrt (+ (* dx dx) (* dy dy))))))
		(setq prev (list x y)))
		pts)
	len)

(defun point-at-length (p target_len)
	; (point-at-length path length) -> (x y angle) | :nil
	; Get point and tangent angle at given length along path
	(defq len 0.0 pts (partition p 2) prev :nil result :nil i 0 n (length pts))
	(while (and (< i n) (not result))
		(bind '(x y) (elem-get pts i))
		(when prev
			(bind '(px py) prev)
			(defq dx (- x px) dy (- y py)
				seg_len (sqrt (+ (* dx dx) (* dy dy))))
			(when (>= (+ len seg_len) target_len)
				;found the segment
				(defq t (if (> seg_len 0.0) (/ (- target_len len) seg_len) 0.0)
					rx (+ px (* t dx))
					ry (+ py (* t dy))
					angle (atan2 dy dx))
				(setq result (list rx ry angle)))
			(setq len (+ len seg_len)))
		(setq prev (list x y) i (inc i)))
	result)

(defun render-textpath (canvas entry text ref_path defs)
	; (render-textpath canvas entry text ref_path defs)
	; Render text along a referenced path (skipped in TUI mode)
	(when (def? 'create-font)
		(bind '(family weight style size anchor baseline) (gather entry
			"font-family" "font-weight" "font-style" "font-size"
			"text-anchor" "dominant-baseline"))
		(defq font_suffix (if (> (length style) 0) (cat weight style) weight))
		(defq font (create-font (cat "fonts/" family "-" font_suffix ".ctf") (n2i size)))
		(setd font (create-font (cat "fonts/" family "-" weight ".ctf") (n2i size)))
		(setd font (create-font (cat "fonts/" family "-Regular.ctf") (n2i size)))
		(setd font (create-font "fonts/OpenSans-Regular.ctf" (n2i size)))
		;get the path data - ref_path is stored as list of (flag path) pairs
		(when (and ref_path (> (length ref_path) 0))
			(defq p (second (first ref_path)))
			(defq total_len (path-length p))
			;calculate starting offset based on text-anchor
			(defq text_width 0.0)
			(each (lambda (c)
				(bind '(w h) (font-glyph-bounds font (char c)))
				(setq text_width (+ text_width (n2f w))))
				text)
			(defq offset (case anchor
				("middle" (/ (- total_len text_width) 2.0))
				("end" (- total_len text_width))
				(:t 0.0)))
			;render each glyph along the path
			(defq curr_offset offset)
			(each (lambda (c)
				(defq char_str (char c))
				(bind '(w h) (font-glyph-bounds font char_str))
				(defq glyph_paths (font-glyph-paths font char_str))
				(when (defq pt (point-at-length p (+ curr_offset (/ (n2f w) 2.0))))
					(bind '(px py angle) pt)
					;baseline offset
					(defq by (case baseline
						("middle" (* (n2f h) 0.5))
						("hanging" (n2f h))
						(:t 0.0)))
					;transform: translate to point, rotate by tangent, offset by baseline
					(defq ca (cos angle) sa (sin angle)
						tx (- px (* by sa))
						ty (+ py (* by ca)))
					(defq glyph_transform (Mat3x2-f ca (neg sa) tx sa ca ty))
					;apply entry transform
					(bind '(transform) (gather entry "transform"))
					(defq final_transform (mat3x2-mul-f transform glyph_transform))
					(defq d (map (# (list :t (path-transform final_transform %0 %0))) glyph_paths))
					(path-fill-and-stroke canvas entry d defs))
				(setq curr_offset (+ curr_offset (n2f w))))
				text))))

(defun render-markers (canvas entry paths defs marker_start marker_mid marker_end)
	; (render-markers canvas entry paths defs marker_start marker_mid marker_end)
	; Render markers at path endpoints
	(each (lambda ((closed p))
		(defq pts (partition p 2) n (length pts))
		(when (> n 0)
			;marker-start at first point
			(when marker_start
				(when (defq marker (. defs :find marker_start))
					(bind '(_ refX refY markerW markerH orient content) marker)
					(bind '(x y) (first pts))
					;calculate angle for orient="auto"
					(defq angle 0.0)
					(when (and (eql orient "auto") (> n 1))
						(bind '(x2 y2) (second pts))
						(setq angle (atan2 (- y2 y) (- x2 x))))
					(render-marker-at canvas entry x y angle refX refY markerW markerH content defs)))
			;marker-mid at intermediate points
			(when (and marker_mid (> n 2))
				(when (defq marker (. defs :find marker_mid))
					(bind '(_ refX refY markerW markerH orient content) marker)
					(defq i 1)
					(while (< i (dec n))
						(bind '(x y) (elem-get pts i))
						(defq angle 0.0)
						(when (eql orient "auto")
							(bind '(px py) (elem-get pts (dec i)))
							(bind '(nx ny) (elem-get pts (inc i)))
							(setq angle (/ (+ (atan2 (- y py) (- x px))
								(atan2 (- ny y) (- nx x))) 2.0)))
						(render-marker-at canvas entry x y angle refX refY markerW markerH content defs)
						(setq i (inc i)))))
			;marker-end at last point
			(when marker_end
				(when (defq marker (. defs :find marker_end))
					(bind '(_ refX refY markerW markerH orient content) marker)
					(bind '(x y) (last pts))
					(defq angle 0.0)
					(when (and (eql orient "auto") (> n 1))
						(bind '(px py) (elem-get pts (- n 2)))
						(setq angle (atan2 (- y py) (- x px))))
					(render-marker-at canvas entry x y angle refX refY markerW markerH content defs)))))
		paths))

(defun render-marker-at (canvas entry x y angle refX refY markerW markerH content defs)
	; Render a marker at position x,y with given angle
	; TODO: when marker content is stored, render it here
	; For now, draw a simple triangle as placeholder
	(bind '(transform fill) (gather entry "transform" "fill"))
	(defq ca (cos angle) sa (sin angle)
		;scale marker to size
		scale (/ markerW 3.0)
		;create marker triangle points
		p0x (* scale 1.5) p0y 0.0
		p1x (* scale -0.75) p1y (* scale 0.866)
		p2x (* scale -0.75) p2y (* scale -0.866))
	;rotate and translate
	(defq rx0 (+ x (- (* p0x ca) (* p0y sa)))
		ry0 (+ y (+ (* p0x sa) (* p0y ca)))
		rx1 (+ x (- (* p1x ca) (* p1y sa)))
		ry1 (+ y (+ (* p1x sa) (* p1y ca)))
		rx2 (+ x (- (* p2x ca) (* p2y sa)))
		ry2 (+ y (+ (* p2x sa) (* p2y ca))))
	(defq marker_path (path rx0 ry0 rx1 ry1 rx2 ry2))
	(when (num? fill)
		(.-> canvas
			(:set_color fill)
			(:fpoly 0.0 0.0 +winding_none_zero
				(list (path-transform transform marker_path (cat marker_path)))))))

(defun path-fill-and-stroke (canvas entry paths defs)
	(bind '(stroke fill stroke_width stroke_linecap stroke_linejoin
			fill_rule fill_opacity stroke_opacity transform
			stroke_dasharray stroke_dashoffset stroke_miterlimit visibility display opacity &rest _) (get :vals entry))
	;skip rendering if hidden or display:none
	(unless (or (eql visibility "hidden") (eql display "none"))
	;apply element opacity to fill and stroke opacity
	(setq fill_opacity (* fill_opacity opacity)
		stroke_opacity (* stroke_opacity opacity))
	;handle fill
	(cond
		;fill is a gradient/pattern reference (string starting with "url(#")
		((and (not (num? fill)) (starts-with "url(#" fill))
			;extract id from "url(#id)" - skip "url(#" (5 chars) and ")" (1 char)
			(defq ref_id (slice fill 5 (dec (length fill)))
				ref_obj (. defs :find ref_id))
			(when (and ref_obj (/= fill_opacity 0.0))
				(case (first ref_obj)
					((:linear :radial)
						(gradient-fill canvas paths ref_obj transform fill_opacity fill_rule))
					(:pattern
						(pattern-fill canvas paths ref_obj transform fill_opacity fill_rule defs)))))
		;fill is a solid color (number)
		((and (num? fill) (/= fill 0) (/= fill_opacity 0.0))
			(.-> canvas
				(:set_color (+ (<< (n2i (* fill_opacity 0xff.0)) 24) (logand fill 0xffffff)))
				(:fpoly 0.0 0.0 fill_rule
					(map (lambda ((f p)) (path-transform transform p (cat p))) paths)))))
	(when (and (/= stroke 0) (/= stroke_opacity 0.0))
		(.-> canvas
			(:set_color (+ (<< (n2i (* stroke_opacity 0xff.0)) 24) (logand stroke 0xffffff)))
			(:fpoly 0.0 0.0 fill_rule
				(map (lambda (p) (path-transform transform p p))
					(reduce (lambda (l (f p))
						;apply dasharray if present
						(defq dashed_paths (if stroke_dasharray
							(path-dasharray p stroke_dasharray stroke_dashoffset)
							(list p)))
						(cond
							((and f (not stroke_dasharray))
								;closed path without dash - draw as solid polygon
								(bind '(p1 p2) (path-stroke-polygon p (* 0.5 stroke_width)
									stroke_linejoin))
								(push l p1 p2))
							(:t ;open path or dashed closed path - draw each segment as polyline
								(each (lambda (dp)
									(push l (path-stroke-polyline dp (* 0.5 stroke_width)
										stroke_linejoin stroke_linecap stroke_linecap)))
									dashed_paths)
								l)))
							paths (list))))))
	;render markers if present - DISABLED for debugging
	;(bind '(marker_start marker_mid marker_end) (gather entry
	;	"marker-start" "marker-mid" "marker-end"))
	;(when (or marker_start marker_mid marker_end)
	;	;transform paths for marker positioning
	;	(defq transformed_paths (map (lambda ((f p))
	;		(list f (path-transform transform p (cat p)))) paths))
	;	(render-markers canvas entry transformed_paths defs marker_start marker_mid marker_end))
	))

(defun SVG-Canvas (stream &optional scale)
	; (SVG-Canvas stream [scale]) -> :nil | canvas
	(setq scale (n2f (ifn scale 1)))
	(defq canvas :nil defs (Fmap 17)
		current_gradient :nil current_gradient_id :nil
		css_rules :nil in_style_element :nil style_text ""
		current_pattern :nil current_pattern_id :nil
		current_marker :nil current_marker_id :nil
		in_textpath :nil textpath_href :nil textpath_text ""
		stack (list (scatter (Lmap)
			;this block of defaults are in order !
			"stroke" 0
			"fill" +argb_black
			"stroke-width" 1.0
			"stroke-linecap" +cap_butt
			"stroke-linejoin" +join_miter
			"fill-rule" +winding_none_zero
			"fill-opacity" 1.0
			"stroke-opacity" 1.0
			"transform" (Mat3x2-f scale 0.0 0.0 0.0 scale 0.0)
			"stroke-dasharray" :nil
			"stroke-dashoffset" 0.0
			"stroke-miterlimit" 4.0
			"visibility" "visible"
			"display" "inline"
			"opacity" 1.0
			;this block can be any order
			"d" (path) "points" (path)
			"x" 0.0 "y" 0.0 "x1" 0.0 "y1" 0.0 "x2" 0.0 "y2" 0.0
			"cx" 0.0 "cy" 0.0 "r" 0.0 "rx" 0.0 "ry" 0.0
			"width" 0.0 "height" 0.0
			"text-anchor" "start" "dominant-baseline" "auto"
			"font-size" 16.0 "font-family" "OpenSans" "font-weight" "Regular" "font-style" ""
			"dx" 0.0 "dy" 0.0
			"marker-start" :nil "marker-mid" :nil "marker-end" :nil
			)))
	(XML-parse stream
		(lambda (command keys vals)
			(case command
				("svg"
					(bind '(w h vb) (gather (defq entry (push-attributes stack keys vals css_rules "svg"))
						"width" "height" "viewBox"))
					(defq x 0.0 y 0.0) (setd w 256.0 h 256.0)
					(if vb (bind '(x y w h) vb))
					(. (setq canvas (Canvas (n2i w) (n2i h) (n2i scale)))
						:set_canvas_flags +canvas_flag_antialias)
					(. entry :insert "transform" (Mat3x2-f scale 0.0 (* scale x -1.0) 0.0 scale (* scale y -1.0))))
				("circle"
					(bind '(cx cy r) (gather (defq entry (push-attributes stack keys vals css_rules "circle"))
						"cx" "cy" "r"))
					(defq d (path-gen-arc cx cy 0.0 +fp_2pi r (path)))
					(path-fill-and-stroke canvas entry (list (list :t d)) defs))
				("ellipse"
					(bind '(cx cy rx ry) (gather (defq entry (push-attributes stack keys vals css_rules "ellipse"))
						"cx" "cy" "rx" "ry"))
					(setd rx ry ry rx)
					(defq d (path-gen-ellipse cx cy rx ry (path)))
					(path-fill-and-stroke canvas entry (list (list :t d)) defs))
				("line"
					(bind '(x1 y1 x2 y2) (gather (defq entry (push-attributes stack keys vals css_rules "line"))
						"x1" "y1" "x2" "y2"))
					(defq d (path x1 y1 x2 y2))
					(path-fill-and-stroke canvas entry (list (list :nil d)) defs))
				("rect"
					(bind '(x y rx ry x1 y1) (gather (defq entry (push-attributes stack keys vals css_rules "rect"))
						"x" "y" "rx" "ry" "width" "height"))
					(setq x1 (+ x x1) y1 (+ y y1))
					(setd rx ry ry rx)
					(defq d (path-gen-rect x y x1 y1 rx ry (path)))
					(path-fill-and-stroke canvas entry (list (list :t d)) defs))
				("polygon"
					(defq entry (push-attributes stack keys vals css_rules "polygon")
						d (. entry :find "points"))
					(path-fill-and-stroke canvas entry (list (list :t d)) defs))
				("polyline"
					(defq entry (push-attributes stack keys vals css_rules "polyline")
						d (. entry :find "points"))
					(path-fill-and-stroke canvas entry (list (list :nil d)) defs))
				("path"
					(defq entry (push-attributes stack keys vals css_rules "path")
						d (. entry :find "d"))
					;store path in defs if it has an id (for textPath references)
					(when (defq path_id (. entry :find "id"))
						(. defs :insert path_id d))
					(path-fill-and-stroke canvas entry d defs))
				(("text" "tspan")
					(push-attributes stack keys vals css_rules command))
				(("g" "defs" "switch" "clipPath" "symbol" "a" "title" "desc" "metadata" "use" "image")
					(push-attributes stack keys vals css_rules command))
				("style"
					;start collecting CSS text
					(setq in_style_element :t style_text ""))
				("pattern"
					;start a new pattern definition
					(defq pat_id :nil px 0.0 py 0.0 pw 0.0 ph 0.0 pat_units :bbox pat_content_units :user)
					(each (lambda (k v)
						(case k
							("id" (setq pat_id v))
							("x" (setq px (parse-numeric v)))
							("y" (setq py (parse-numeric v)))
							("width" (setq pw (parse-numeric v)))
							("height" (setq ph (parse-numeric v)))
							("patternUnits" (setq pat_units (if (eql v "userSpaceOnUse") :user :bbox)))
							("patternContentUnits" (setq pat_content_units (if (eql v "objectBoundingBox") :bbox :user)))))
						keys vals)
					(setq current_pattern_id pat_id
						current_pattern (list :pattern px py pw ph pat_units pat_content_units (list)))
					(push-attributes stack keys vals css_rules "pattern"))
				("marker"
					;start a new marker definition
					(defq mark_id :nil refX 0.0 refY 0.0 markerW 3.0 markerH 3.0 orient "0")
					(each (lambda (k v)
						(case k
							("id" (setq mark_id v))
							("refX" (setq refX (parse-numeric v)))
							("refY" (setq refY (parse-numeric v)))
							("markerWidth" (setq markerW (parse-numeric v)))
							("markerHeight" (setq markerH (parse-numeric v)))
							("orient" (setq orient v))))
						keys vals)
					(setq current_marker_id mark_id
						current_marker (list :marker refX refY markerW markerH orient (list)))
					(push-attributes stack keys vals css_rules "marker"))
				("textPath"
					;text along a path
					(defq href :nil)
					(each (lambda (k v)
						(cond
							((or (eql k "href") (eql k "xlink:href"))
								;extract id from "#id" or "url(#id)"
								(setq href (cond
									((starts-with "#" v) (slice v 1 -1))
									((starts-with "url(#" v) (slice v 5 (dec (length v))))
									(:t v))))))
						keys vals)
					(setq in_textpath :t textpath_href href textpath_text "")
					(push-attributes stack keys vals css_rules "textPath"))
				("linearGradient"
					;start a new linear gradient definition
					(defq grad_id :nil gx1 0.0 gy1 0.0 gx2 100.0 gy2 0.0 grad_units :bbox spread :pad)
					(each (lambda (k v)
						(case k
							("id" (setq grad_id v))
							("gradientUnits" (setq grad_units (if (eql v "userSpaceOnUse") :user :bbox)))
							("spreadMethod" (setq spread (cond
								((eql v "repeat") :repeat)
								((eql v "reflect") :reflect)
								(:t :pad))))
							("x1" (setq gx1 (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v)))))
							("y1" (setq gy1 (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v)))))
							("x2" (setq gx2 (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v)))))
							("y2" (setq gy2 (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v))))))) keys vals)
					;for objectBoundingBox, normalize to 0-1; for userSpaceOnUse, keep raw values
					(if (eql grad_units :bbox)
						(setq current_gradient_id grad_id
							current_gradient (list :linear (/ gx1 100.0) (/ gy1 100.0) (/ gx2 100.0) (/ gy2 100.0) grad_units spread (list)))
						(setq current_gradient_id grad_id
							current_gradient (list :linear gx1 gy1 gx2 gy2 grad_units spread (list)))))
				("radialGradient"
					;start a new radial gradient definition
					(defq grad_id :nil cx 50.0 cy 50.0 r 50.0 fx :nil fy :nil grad_units :bbox spread :pad)
					(each (lambda (k v)
						(case k
							("id" (setq grad_id v))
							("gradientUnits" (setq grad_units (if (eql v "userSpaceOnUse") :user :bbox)))
							("spreadMethod" (setq spread (cond
								((eql v "repeat") :repeat)
								((eql v "reflect") :reflect)
								(:t :pad))))
							("cx" (setq cx (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v)))))
							("cy" (setq cy (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v)))))
							("r" (setq r (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v)))))
							("fx" (setq fx (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v)))))
							("fy" (setq fy (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v))))))) keys vals)
					;fx/fy default to cx/cy if not specified
					(setd fx cx fy cy)
					;for objectBoundingBox, normalize to 0-1; for userSpaceOnUse, keep raw values
					(if (eql grad_units :bbox)
						(setq current_gradient_id grad_id
							current_gradient (list :radial (/ cx 100.0) (/ cy 100.0) (/ r 100.0) (/ fx 100.0) (/ fy 100.0) grad_units spread (list)))
						(setq current_gradient_id grad_id
							current_gradient (list :radial cx cy r fx fy grad_units spread (list)))))
				("stop"
					;add stop to current gradient
					(when current_gradient
						(defq offset 0.0 stop_color +argb_black stop_opacity 1.0)
						(each (lambda (k v)
							(cond
								((eql k "offset")
									(setq offset (n2f (str-to-num (if (ends-with "%" v) (slice v 0 (dec (length v))) v))))
									(when (> offset 1.0) (setq offset (/ offset 100.0))))
								((eql k "stop-color")
									(setq stop_color
										(cond
											((starts-with "#" v) (read-col v))
											((starts-with "rgba(" v) (read-rgba v))
											((starts-with "rgb(" v) (read-rgb v))
											((starts-with "hsla(" v) (read-hsla v))
											((starts-with "hsl(" v) (read-hsl v))
											((svg-color v))
											(:t +argb_black))))
								((eql k "stop-opacity")
									(setq stop_opacity (n2f (str-to-num v)))))) keys vals)
						;also check style attribute for stop-color and stop-opacity
						(when (defq style_idx (some! (lambda (k i) (when (eql k "style") i)) (list keys (range 0 (length keys)))))
							(defq style_val (elem-get vals style_idx))
							(each (lambda (pair)
								(defq parts (split pair ":"))
								(when (> (length parts) 1)
									(defq sk (trim (elem-get parts 0) " \t")
										sv (trim (elem-get parts 1) " \t"))
									(cond
										((eql sk "stop-color")
											(setq stop_color
												(cond
													((starts-with "#" sv) (read-col sv))
													((starts-with "rgba(" sv) (read-rgba sv))
													((starts-with "rgb(" sv) (read-rgb sv))
													((starts-with "hsla(" sv) (read-hsla sv))
													((starts-with "hsl(" sv) (read-hsl sv))
													((svg-color sv))
													(:t +argb_black))))
										((eql sk "stop-opacity")
											(setq stop_opacity (n2f (str-to-num sv))))
										((eql sk "offset")
											(setq offset (n2f (str-to-num (if (ends-with "%" sv) (slice sv 0 (dec (length sv))) sv))))
											(when (> offset 1.0) (setq offset (/ offset 100.0)))))))
								(split style_val ";")))
						;apply stop-opacity to color's alpha channel
						(when (/= stop_opacity 1.0)
							(defq alpha (n2i (* stop_opacity 255.0)))
							(setq stop_color (+ (<< alpha 24) (logand stop_color 0xffffff))))
						;push stop to the stops list (last element of gradient)
						(push (last current_gradient) (list offset stop_color))))
				))
		(lambda (command)
			(case command
				(("svg" "g" "defs" "switch" "clipPath" "symbol" "a" "title" "desc" "metadata" "use" "circle" "ellipse" "path" "polygon" "polyline" "line" "rect" "text" "tspan" "image")
					(pop stack))
				("style"
					;parse collected CSS and store rules
					(setq css_rules (parse-css-rules style_text)
						in_style_element :nil))
				("pattern"
					;store pattern in defs
					(when (and current_pattern_id current_pattern)
						(. defs :insert current_pattern_id current_pattern))
					(setq current_pattern :nil current_pattern_id :nil)
					(pop stack))
				("marker"
					;store marker in defs
					(when (and current_marker_id current_marker)
						(. defs :insert current_marker_id current_marker))
					(setq current_marker :nil current_marker_id :nil)
					(pop stack))
				("textPath"
					;render text along path - DISABLED for debugging
					;(when (and textpath_href (> (length textpath_text) 0))
					;	(when (defq ref_path (. defs :find textpath_href))
					;		(render-textpath canvas (last stack) textpath_text ref_path defs)))
					(setq in_textpath :nil textpath_href :nil textpath_text "")
					(pop stack))
				(("linearGradient" "radialGradient")
					;store gradient in defs
					(when (and current_gradient_id current_gradient)
						(. defs :insert current_gradient_id current_gradient))
					(setq current_gradient :nil current_gradient_id :nil))
				))
		(lambda (text)
			(cond
				;collecting CSS text
				(in_style_element
					(setq style_text (cat style_text text)))
				;collecting textPath text
				(in_textpath
					(setq textpath_text (cat textpath_text text)))
				;render normal text (skipped in TUI mode)
				(:t
					(when (def? 'create-font)
						(bind '(x y family weight style size anchor baseline dx dy)
							(gather (defq entry (last stack))
								"x" "y" "font-family" "font-weight" "font-style" "font-size"
								"text-anchor" "dominant-baseline" "dx" "dy"))
						;build font name with weight and style (e.g., "Bold", "Italic", "BoldItalic")
						(defq font_suffix (if (> (length style) 0)
							(cat weight style)
							weight))
						(defq font (create-font (cat "fonts/" family "-" font_suffix ".ctf") (n2i size)))
						(setd font (create-font (cat "fonts/" family "-" weight ".ctf") (n2i size)))
						(setd font (create-font (cat "fonts/" family "-Regular.ctf") (n2i size)))
						(setd font (create-font "fonts/OpenSans-Regular.ctf" (n2i size)))
						(bind '(w h) (font-glyph-bounds font text))
						;apply dx/dy offsets to position
						(setq x (+ x dx) y (+ y dy))
						(defq ox (case anchor
								("middle" (* (n2f w) -1.0))
								("end" (* (n2f w) -2.0))
								(:t 0.0))
							oy (case baseline
								("middle" (* (n2f h) 0.5))
								("hanging" (n2f h))
								(:t 0.0))
							d (map (# (list :t (path-transform
									(Mat3x2-f 1.0 0.0 (+ x ox) 0.0 1.0 (+ y oy)) %0 %0)))
								(font-glyph-paths font text)))
						(path-fill-and-stroke canvas entry d defs))))))
	;resize to final output
	(bind '(w h) (. canvas :pref_size))
	(. (Canvas w h 1) :resize canvas))

(defun SVG-info (stream)
	; (SVG-info stream) -> (width height type) | (-1 -1 -1)
	(defq stack (list (Lmap)) width -1 height -1)
	(XML-parse stream
		(lambda (command keys vals)
			(when (eql command "svg")
				(bind '(w h vb) (gather (defq entry (push-attributes stack keys vals))
					"width" "height" "viewBox"))
				(setd w 256.0 h 256.0)
				(if vb (bind '(& & w h) vb))
				(setq width w height h)))
		(lambda (command))
		(lambda (text)))
	(list width height 32))

;module
(export-symbols '(SVG-Canvas SVG-info))
(env-pop)
