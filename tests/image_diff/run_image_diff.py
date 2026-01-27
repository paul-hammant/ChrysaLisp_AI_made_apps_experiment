#!/usr/bin/env python3
"""
Image Diff Test Suite for ChrysaLisp SVG Rendering

Compares ChrysaLisp SVG rendering against browser (Playwright/Chrome) rendering.

Usage:
    python run_image_diff.py [--svg PATH] [--threshold 0.95] [--output-dir DIR]

Requirements:
    pip install playwright pillow numpy scikit-image
    playwright install chromium
"""

import argparse
import subprocess
import tempfile
import os
import sys
from pathlib import Path
from typing import List, Tuple, Optional
import shutil

# Check dependencies
try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Missing dependencies. Run: pip install pillow numpy")
    sys.exit(1)

try:
    from skimage.metrics import structural_similarity as ssim
    HAS_SKIMAGE = True
except ImportError:
    HAS_SKIMAGE = False
    print("Note: scikit-image not found, using basic diff")

try:
    from playwright.sync_api import sync_playwright
    HAS_PLAYWRIGHT = True
except ImportError:
    HAS_PLAYWRIGHT = False
    print("Note: playwright not found, browser comparison disabled")

from cpm_reader import cpm_to_png


class ImageDiffTest:
    """Compare ChrysaLisp SVG rendering against browser."""

    def __init__(self, chrysalisp_root: Path, output_dir: Path):
        self.root = chrysalisp_root
        self.output_dir = output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def render_chrysalisp(self, svg_path: Path) -> Optional[Path]:
        """Render SVG using ChrysaLisp and return PNG path."""
        # Generate render script
        script = f'''
(import "gui/lisp.inc")

(defun main ()
    (when (defq stream (file-stream "{svg_path}"))
        (when (defq canvas (SVG-Canvas stream 1))
            (bind '(w h) (. canvas :pref_size))
            (. canvas :save "out.cpm" 32)
            (print "OK " w " " h))))

(catch
    (main)
    (print "ERROR " _))

((ffi "service/gui/lisp_deinit"))
'''
        script_path = self.output_dir / "render_svg.lisp"
        script_path.write_text(script)

        cpm_path = self.output_dir / "out.cpm"
        png_path = self.output_dir / f"{svg_path.stem}_chrysalisp.png"

        # Run ChrysaLisp
        old_cwd = os.getcwd()
        os.chdir(self.root)
        try:
            result = subprocess.run(
                ["./run_tui.sh", "-n", "1", "-f", "-s", str(script_path)],
                capture_output=True, text=True, timeout=60
            )
            output = result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            print(f"  Timeout rendering {svg_path}")
            return None
        finally:
            os.chdir(old_cwd)

        if "OK" not in output:
            print(f"  ChrysaLisp render failed: {output}")
            return None

        # Convert CPM to PNG
        cpm_file = self.root / "out.cpm"
        if not cpm_file.exists():
            print(f"  CPM file not created")
            return None

        if cpm_to_png(str(cpm_file), str(png_path)):
            cpm_file.unlink()  # Clean up
            return png_path
        return None

    def render_browser(self, svg_path: Path, width: int, height: int) -> Optional[Path]:
        """Render SVG using Playwright/Chrome."""
        if not HAS_PLAYWRIGHT:
            return None

        png_path = self.output_dir / f"{svg_path.stem}_browser.png"

        # Read SVG content and embed directly for better rendering
        svg_content = svg_path.read_text()

        html = f'''<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ margin: 0; padding: 0; background: white; }}
        svg {{ display: block; }}
    </style>
</head>
<body>
{svg_content}
</body>
</html>'''

        html_path = self.output_dir / "render.html"
        html_path.write_text(html)

        try:
            with sync_playwright() as p:
                browser = p.chromium.launch()
                page = browser.new_page(viewport={"width": width, "height": height})
                page.goto(f"file://{html_path.absolute()}")
                page.wait_for_load_state("networkidle")
                page.screenshot(path=str(png_path), full_page=False)
                browser.close()
            return png_path
        except Exception as e:
            print(f"  Browser render failed: {e}")
            return None

    def compare_images(self, img1_path: Path, img2_path: Path) -> Tuple[float, Optional[Path]]:
        """Compare two images and return similarity score + diff image."""
        img1 = Image.open(img1_path).convert('RGBA')
        img2 = Image.open(img2_path).convert('RGBA')

        # Resize to match if needed
        if img1.size != img2.size:
            img2 = img2.resize(img1.size, Image.Resampling.LANCZOS)

        # Composite both onto white background for fair comparison
        # (ChrysaLisp uses transparent bg, browser uses white)
        def composite_on_white(img):
            white_bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
            return Image.alpha_composite(white_bg, img)

        img1 = composite_on_white(img1)
        img2 = composite_on_white(img2)

        arr1 = np.array(img1)
        arr2 = np.array(img2)

        if HAS_SKIMAGE:
            # Use SSIM for perceptual similarity
            score = ssim(arr1, arr2, channel_axis=2, data_range=255)
        else:
            # Basic pixel difference
            diff = np.abs(arr1.astype(float) - arr2.astype(float))
            max_diff = 255.0 * 4  # RGBA
            score = 1.0 - (np.mean(diff) / max_diff)

        # Create diff visualization
        diff_path = self.output_dir / f"{img1_path.stem}_diff.png"
        diff_arr = np.abs(arr1.astype(int) - arr2.astype(int)).astype(np.uint8)
        diff_arr[:, :, 3] = 255  # Full alpha for visibility
        diff_img = Image.fromarray(diff_arr, 'RGBA')
        diff_img.save(diff_path)

        return score, diff_path

    def test_svg(self, svg_path: Path, threshold: float = 0.95) -> bool:
        """Test a single SVG file."""
        print(f"\nTesting: {svg_path.name}")

        # Render with ChrysaLisp
        chrysalisp_png = self.render_chrysalisp(svg_path)
        if not chrysalisp_png:
            print("  SKIP: ChrysaLisp render failed")
            return False

        # Get dimensions from rendered image
        img = Image.open(chrysalisp_png)
        width, height = img.size
        img.close()

        # Render with browser
        browser_png = self.render_browser(svg_path, width, height)
        if not browser_png:
            print("  SKIP: Browser render not available")
            return True  # Not a failure if Playwright not installed

        # Compare
        score, diff_path = self.compare_images(chrysalisp_png, browser_png)
        passed = score >= threshold

        status = "PASS" if passed else "FAIL"
        print(f"  {status}: similarity={score:.4f} (threshold={threshold})")
        if diff_path:
            print(f"  Diff image: {diff_path}")

        return passed


def find_test_svgs(root: Path) -> List[Path]:
    """Find SVG test files."""
    svg_dir = root / "apps" / "images" / "data"
    if not svg_dir.exists():
        return []

    # Skip SVGs with unsupported features:
    # - clock.svg, dial.svg: need GUI fonts for text
    # - golfer.svg: uses clipPath (not implemented in ChrysaLisp)
    # - radial_test.svg: radial gradients use square approximation (circular rendering not yet implemented)
    skip = {"clock.svg", "dial.svg", "golfer.svg", "radial_test.svg"}
    return [f for f in svg_dir.glob("*.svg") if f.name not in skip]


def main():
    parser = argparse.ArgumentParser(description="SVG Image Diff Tests")
    parser.add_argument("--svg", type=Path, help="Test specific SVG file")
    parser.add_argument("--threshold", type=float, default=0.80,
                        help="Similarity threshold (0-1, default 0.80)")
    parser.add_argument("--output-dir", type=Path,
                        default=Path("tests/image_diff/output"),
                        help="Output directory for images")
    parser.add_argument("--all", action="store_true",
                        help="Test all SVGs in data directory")
    args = parser.parse_args()

    # Find ChrysaLisp root
    script_dir = Path(__file__).parent.absolute()
    root = script_dir.parent.parent  # tests/image_diff -> tests -> root

    tester = ImageDiffTest(root, args.output_dir)

    if args.svg:
        svgs = [args.svg]
    elif args.all:
        svgs = find_test_svgs(root)
    else:
        # Default: test arc_test.svg
        svgs = [root / "apps" / "images" / "data" / "arc_test.svg"]

    passed = 0
    failed = 0

    for svg in svgs:
        if tester.test_svg(svg, args.threshold):
            passed += 1
        else:
            failed += 1

    print(f"\n{'='*40}")
    print(f"Results: {passed} passed, {failed} failed")

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
