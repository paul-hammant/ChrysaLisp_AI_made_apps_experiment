# SVG Implementation Status Report
Date: 2026-01-22 (Updated)

## Recent Changes

### Merge Conflict Resolution (2026-01-22)
Resolved merge conflict in `lib/xml/svg.inc`, keeping the more complete version with:
- CSS `<style>` element text collection
- textPath text collection support
- `font-style` attribute support (italic/oblique)
- `dx`/`dy` text position offset support
- Proper `defs` parameter passing to `path-fill-and-stroke`

### Test Suite Fixes (2026-01-22)
Fixed stream reuse issues in test files (streams are consumed after use, need fresh `file-stream` for each operation):
- `svg_minimal_test.lisp`
- `svg_notext_test.lisp`
- `svg_features_test.lisp` - rewrote to use file-based testing

## Test Suite Results

**All tests PASS**

| Suite | File | Result |
|-------|------|--------|
| Main test suite | `svg_test.lisp` | 20/20 |
| Feature tests | `svg_features_test.lisp` | 28/28 |
| Feature file tests | `svg_features_file_test.lisp` | 10/10 |
| No-text SVG tests | `svg_notext_test.lisp` | 10/10 |
| Large production files | `svg_large_files_test.lisp` | 9/9 |
| Stress tests | `svg_stress_test.lisp` | 11/11 |
| Minimal test | `svg_minimal_test.lisp` | PASS |
| Info-only test | `svg_info_only.lisp` | PASS |
| Canvas check | `svg_canvas_check.lisp` | PASS |

## Current Coverage: ~70-75% of SVG 1.1

### Fully Implemented
- Basic shapes: rect, circle, ellipse, line, polyline, polygon
- Path commands: M, L, H, V, C, S, Q, T, Z, A/a (all case variants)
- Color formats: hex (#RRGGBB, #RGB), rgb(), rgba(), hsl(), hsla()
- Full SVG 1.1 named colors (147 colors)
- Stroke: width, linecap, linejoin, dasharray, dashoffset, miterlimit
- Fill: fill, fill-opacity, fill-rule
- Opacity: fill-opacity, stroke-opacity, opacity
- Transforms: translate, scale, rotate, matrix, skewX, skewY
- Structure: g, defs, svg, switch, a
- Gradients: linearGradient, radialGradient (stops, spreadMethod, gradientUnits)
- Visibility: visibility, display
- CSS: inline style, embedded `<style>` element
- Text: text, tspan (GUI mode only, gracefully skipped in TUI)
- Text attributes: font-family, font-weight, font-style, font-size, dx, dy
- Text alignment: text-anchor, dominant-baseline

### Partially Implemented
- clipPath - parses, no clipping applied
- pattern - parses, no pattern fill
- marker - parses, not rendered at endpoints
- use/symbol - parses, doesn't clone elements
- textPath - code exists but disabled

### Not Implemented
- image, filter, mask, foreignObject
- Animation (animate, animateTransform, etc.)
- Interactivity (events, cursor)

---

## TODO: SVG 1.1 Compatibility Roadmap

### Phase 1: Element Reuse (No API Changes)

#### 1.1 `use` Element
**Priority: HIGH** | **Complexity: MEDIUM**

Enable `<use href="#id">` to clone elements from defs.

```
Location: lib/xml/svg.inc
```

Tasks:
- [ ] Store full element entries in defs (not just path data)
- [ ] Store all shapes with IDs (rect, circle, path, g, etc.)
- [ ] Parse `use` href/xlink:href attribute
- [ ] Look up referenced element in defs
- [ ] Apply use's x/y offset as translation
- [ ] Combine transforms (use transform + element transform)
- [ ] Recursively render referenced content

Test file needed: `apps/media/images/data/use_test.svg`

#### 1.2 `symbol` Element
**Priority: HIGH** | **Complexity: LOW** (after use works)

Tasks:
- [ ] Store symbol content in defs
- [ ] Handle viewBox on symbol
- [ ] Render via use reference

#### 1.3 Enable `textPath`
**Priority: MEDIUM** | **Complexity: LOW**

Tasks:
- [ ] Uncomment textPath rendering code (lines ~1071-1075)
- [ ] Test with textpath_test.svg
- [ ] Verify path lookup in defs works

Test file needed: `apps/media/images/data/textpath_test.svg`

---

### Phase 2: Markers & Patterns (No API Changes)

#### 2.1 Marker Rendering
**Priority: MEDIUM** | **Complexity: MEDIUM**

Render markers at path start/mid/end points.

Tasks:
- [ ] Extract first/last/mid points from paths
- [ ] Calculate tangent angles at marker positions
- [ ] Apply marker transform (translate + rotate)
- [ ] Scale by markerWidth/markerHeight
- [ ] Render marker content at each position
- [ ] Handle orient="auto" vs fixed angle

Test file needed: `apps/media/images/data/marker_test.svg`

#### 2.2 Pattern Fills
**Priority: LOW** | **Complexity: HIGH**

Tasks:
- [ ] Render pattern content to temporary canvas
- [ ] Tile pattern across fill area
- [ ] Handle patternUnits (objectBoundingBox vs userSpaceOnUse)
- [ ] Handle patternContentUnits
- [ ] Apply patternTransform

Test file needed: `apps/media/images/data/pattern_test.svg`

---

### Phase 3: Text Enhancements (No API Changes)

#### 3.1 Text Attributes
**Priority: LOW** | **Complexity: MEDIUM**

Tasks:
- [ ] letter-spacing
- [ ] word-spacing
- [ ] text-decoration (underline, line-through)
- [ ] font-variant (small-caps)

#### 3.2 `tref` Element
**Priority: LOW** | **Complexity: LOW**

Reference text content from defs.

---

### Phase 4: Gradient Enhancements (No API Changes)

#### 4.1 gradientTransform
**Priority: LOW** | **Complexity: MEDIUM**

Tasks:
- [ ] Parse gradientTransform attribute
- [ ] Apply transform to gradient coordinates
- [ ] Test with rotated/skewed gradients

Test file needed: `apps/media/images/data/gradient_transform_test.svg`

---

### Phase 5: Canvas API Extensions Required

These features require changes to `gui/canvas/*.vp`:

#### 5.1 Polygon Clipping (for clipPath)
**Priority: MEDIUM** | **Complexity: HIGH**

Canvas API needs:
- `:set_clip_path` method accepting path data
- Sutherland-Hodgman or similar clipping algorithm

#### 5.2 Pixel Buffer Access (for filters)
**Priority: LOW** | **Complexity: VERY HIGH**

Canvas API needs:
- `:get_pixels` - read pixel buffer
- `:set_pixels` - write pixel buffer
- Or shader-like per-pixel operations

Filter effects to implement:
- feGaussianBlur
- feColorMatrix
- feOffset
- feMerge
- feBlend
- feDropShadow

#### 5.3 Alpha Masking (for mask)
**Priority: LOW** | **Complexity: HIGH**

Canvas API needs:
- Luminance-to-alpha conversion
- Alpha compositing modes

#### 5.4 Image Element
**Priority: MEDIUM** | **Complexity: MEDIUM**

Tasks:
- [ ] Parse image href (data URI or file path)
- [ ] Load PNG/JPEG via existing pixmap code
- [ ] Render at specified x, y, width, height
- [ ] Apply preserveAspectRatio

---

### Phase 6: Not Planned

These SVG 1.1 features are out of scope:

- **Animation** (animate, animateTransform, animateMotion, set)
- **Interactivity** (onclick, onmouseover, cursor)
- **foreignObject** (embedded HTML/XML)
- **Scripting** (script element)
- **Linking** (view element, fragment identifiers)

---

## Implementation Notes

### Storing Elements in Defs

Current: Only path data string stored
```lisp
(. defs :insert path_id d)  ; just the "d" attribute
```

Needed: Store full element info
```lisp
(. defs :insert id (list :path entry d))  ; type, attributes, data
(. defs :insert id (list :g entry children))  ; groups need children
```

### Use Element Transform Composition

```lisp
; use has x="10" y="20" transform="rotate(45)"
; referenced element has transform="scale(2)"
; final transform = translate(10,20) * rotate(45) * scale(2)
```

### Stream Usage Pattern

Streams are consumed after use. For multiple operations on the same SVG:
```lisp
; WRONG - stream exhausted after SVG-info
(defq stream (file-stream path))
(SVG-info stream)
(SVG-Canvas stream 1)  ; fails - stream at EOF

; CORRECT - fresh stream for each operation
(SVG-info (file-stream path))
(SVG-Canvas (file-stream path) 1)
```

### Test-Driven Development

For each feature:
1. Create test SVG in `apps/media/images/data/`
2. Add to appropriate test file in `tests/`
3. Implement feature
4. Verify all tests still pass

---

## Summary

| Phase | Features | API Changes | Complexity |
|-------|----------|-------------|------------|
| 1 | use, symbol, textPath | None | Medium |
| 2 | markers, patterns | None | Medium-High |
| 3 | Text enhancements | None | Medium |
| 4 | gradientTransform | None | Medium |
| 5 | clipPath, filters, mask, image | Canvas API | High-Very High |
| 6 | Animation, scripting | N/A | Out of scope |

**Recommended priority:** Phase 1 (use/symbol) provides most value for least effort.
