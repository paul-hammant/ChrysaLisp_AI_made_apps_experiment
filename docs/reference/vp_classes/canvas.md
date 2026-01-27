# :canvas

## :view

## Lisp Bindings

### (create-canvas width height scale)

### (create-canvas-pixmap pixmap)

### (canvas-fbox canvas x y w h)

### (canvas-fill canvas argb)

### (canvas-fpoly canvas x y mode list)

### (canvas-from-argb32 pixel type) -> pixel

### (canvas-ftri canvas path)

### (canvas-next-frame canvas)

### (canvas-plot canvas x y)

### (canvas-resize canvas canvas)

### (canvas-swap canvas flags)

### (canvas-to-argb32 pixel type) -> argb32

## VP methods

### :create -> gui/canvas/create

### :create_pixmap -> gui/canvas/create_pixmap

### :deinit -> gui/canvas/deinit

```code
inputs
:r0 = canvas object (ptr)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

### :fbox -> gui/canvas/fbox

```code
inputs
:r0 = canvas object (ptr)
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = w (pixels)
:r10 = h (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

### :fpoly -> gui/canvas/fpoly

```code
inputs
:r0 = canvas object (ptr)
:r1 = x (fixed)
:r2 = y (fixed)
:r3 = winding mode (winding_odd_even, winding_none_zero)
:r4 = list of path objects (ptr)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

### :ftri -> gui/canvas/ftri

```code
inputs
:r0 = canvas object (ptr)
:r1 = x0 (fixed)
:r2 = y0 (fixed)
:r3 = x1 (fixed)
:r4 = y1 (fixed)
:r5 = x2 (fixed)
:r6 = y2 (fixed)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

### :init -> gui/canvas/init

```code
inputs
:r0 = canvas object (ptr)
:r1 = vtable (pptr)
:r2 = width (pixels)
:r3 = height (pixels)
:r4 = aa scale (uint)
outputs
:r0 = canvas object (ptr)
:r1 = 0 if error, else ok
trashes
:r1-:r14
```

### :init_pixmap -> gui/canvas/init_pixmap

```code
inputs
:r0 = canvas object (ptr)
:r1 = vtable (pptr)
:r2 = pixmap object (ptr)
outputs
:r0 = canvas object (ptr)
:r1 = 0 if error, else ok
trashes
:r1-:r14
```

### :pick -> gui/canvas/pick

```code
inputs
:r0 = canvas object (ptr)
:r7 = x (pixels)
:r8 = y (pixels)
outputs
:r0 = canvas object (ptr)
:r1 = color (argb)
trashes
:r1-:r14
```

### :plot -> gui/canvas/plot

```code
inputs
:r0 = canvas object (ptr)
:r7 = x (pixels)
:r8 = y (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

### :set_clip -> gui/canvas/set_clip

```code
inputs
:r0 = canvas object (ptr)
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = x1 (pixels)
:r10 = y1 (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r2
```

### :set_edges -> gui/canvas/set_edges

```code
inputs
:r0 = canvas object (ptr)
:r1 = list of path objects (ptr)
:r2 = x (fixed)
:r3 = y (fixed)
:r4 = y scale (int)
outputs
:r0 = canvas object (ptr)
:r11 = min_x (fixed)
:r12 = min_y (fixed)
:r13 = max_x (fixed)
:r14 = max_y (fixed)
trashes
:r1-:r14
```

### :span -> gui/canvas/span

```code
inputs
:r0 = canvas object (ptr)
:r1 = coverage (long)
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = x1 (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r9
info
coverage is 0x0 to 0x80
```

### :span_noclip -> gui/canvas/span_noclip

```code
inputs
:r0 = canvas object (ptr)
:r1 = coverage (long)
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = x1 (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r9
info
coverage is 0x0 to 0x80
```

### :swap -> gui/canvas/swap

```code
inputs
:r0 = canvas object (ptr)
:r1 = canvas upload flags (uint)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

### :vtable -> gui/canvas/vtable

## Proposed Enhancements for SVG 1.1 Support

The ChrysaLisp SVG renderer (`lib/xml/svg.inc`) has achieved substantial SVG 1.1
coverage including shapes, paths, transforms, gradients (linear/radial with
spreadMethod and gradientUnits), text rendering, and basic styling. However,
three major SVG 1.1 feature categories remain blocked by current canvas API
limitations.

### Current Capabilities

The canvas currently provides:

- Rectangular clipping via `:set_clip` (x, y, x1, y1)
- Polygon/path filling via `:fpoly`
- Basic primitives: `:fbox`, `:ftri`, `:plot`
- Single pixel read via `:pick`
- No direct pixel buffer access for bulk operations

### Requested Additions

#### 1. Pixel Buffer Access (for SVG Filters)

SVG filters (`<filter>`, `<feGaussianBlur>`, `<feDropShadow>`,
`<feColorMatrix>`, etc.) require pixel-level operations.

**Proposed methods:**

```code
### :get_pixels -> gui/canvas/get_pixels

inputs
:r0 = canvas object (ptr)
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = w (pixels)
:r10 = h (pixels)
outputs
:r0 = canvas object (ptr)
:r1 = pixel buffer (ptr) or list of argb values
trashes
:r1-:r14

### :set_pixels -> gui/canvas/set_pixels

inputs
:r0 = canvas object (ptr)
:r1 = pixel buffer (ptr) or list of argb values
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = w (pixels)
:r10 = h (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

Or alternatively, a convolution/kernel operation:

```code
### :apply_kernel -> gui/canvas/apply_kernel

inputs
:r0 = canvas object (ptr)
:r1 = kernel matrix (ptr)
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = w (pixels)
:r10 = h (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
```

**Use cases:**

- Gaussian blur (3x3, 5x5 kernels)
- Drop shadows (blur + offset + color)
- Color matrix transforms (grayscale, sepia, hue-rotate)
- Brightness/contrast adjustments

#### 2. Arbitrary Path Clipping (for `<clipPath>`)

Current `:set_clip` only accepts rectangular bounds. SVG `<clipPath>` can use
any shape.

**Proposed method:**

```code
### :set_clip_path -> gui/canvas/set_clip_path

inputs
:r0 = canvas object (ptr)
:r1 = list of path objects (ptr)
:r2 = x (fixed)
:r3 = y (fixed)
:r4 = winding mode (winding_odd_even, winding_none_zero)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
info
Sets arbitrary polygon/path as clipping region.
Subsequent draw operations only affect pixels inside the path.
```

**Use cases:**

- Circular/elliptical clipping
- Text-shaped clipping
- Complex polygon clipping
- Combining multiple clip shapes

#### 3. Alpha Mask Compositing (for `<mask>`)

SVG masks use grayscale luminance or alpha values to control visibility.

**Proposed methods:**

```code
### :set_mask -> gui/canvas/set_mask

inputs
:r0 = canvas object (ptr)
:r1 = mask buffer (ptr) - alpha values 0x0 to 0xff per pixel
:r7 = x (pixels)
:r8 = y (pixels)
:r9 = w (pixels)
:r10 = h (pixels)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r14
info
Sets alpha mask for subsequent draw operations.
Each pixel's alpha is multiplied by corresponding mask value.

### :clear_mask -> gui/canvas/clear_mask

inputs
:r0 = canvas object (ptr)
outputs
:r0 = canvas object (ptr)
trashes
:r1-:r2
info
Removes alpha mask, restoring normal drawing.
```

**Use cases:**

- Soft-edged fades
- Complex transparency patterns
- Image masking

### Impact Assessment

| Feature | SVG Elements Blocked | Workaround? |
|---------|---------------------|-------------|
| Pixel ops | `<filter>`, `<feGaussianBlur>`, `<feDropShadow>`, `<feColorMatrix>` | No |
| Path clipping | `<clipPath>` with non-rect paths | Partial (bbox only) |
| Alpha masks | `<mask>` | No |

### Priority Suggestion

1. **Path clipping** - Most commonly used in real SVG files, extends existing
   clip functionality
2. **Pixel buffer access** - Enables entire filter subsystem
3. **Alpha masks** - Less common but enables advanced effects

### Features Implementable Now

These SVG features can be implemented with the current canvas API:

- `<pattern>` - tiled `:fpoly` calls
- `<marker>` - draw symbols at path endpoints
- `<textPath>` - position glyphs along paths
- CSS `<style>` blocks - pure parsing, no canvas changes
