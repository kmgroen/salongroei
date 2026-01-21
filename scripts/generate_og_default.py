#!/usr/bin/env python3
"""
Generate Default OG Image for Salongroei using Gemini 3.0 Pro (nano-banana-pro)
Uses the same infrastructure as blog infographic generation
"""

import os
import sys
from pathlib import Path

# Add scripts/images to path for imports
sys.path.insert(0, str(Path(__file__).parent / "images"))

try:
    from generate_images import GeminiImageGenerator
except ImportError:
    print("Error: Could not import generate_images.py")
    print("Make sure generate_images.py is in scripts/images/")
    sys.exit(1)


# OG Image prompt following Salongroei brand guidelines
OG_IMAGE_PROMPT = """Create a professional Open Graph social media preview image (1200×630px, 16:9 ratio) for Salongroei.

Layout: Clean, branded social media preview

Content:
• "SALONGROEI" (very large, centered, Serif font like Noto Serif Black)
• Tagline below: "Vind de Beste Salon Software" (medium size, Sans-serif like Noto Sans Bold)
• Subtitle: "Vergelijk • Reviews • Gidsen" (small, with bullet points)

Design:
- Background Cream (#FFF8F0) main background
- Expert Navy (#1E3A5F) for all text (very high contrast, readable)
- Organic decorative shapes in corners:
  - Top-left: Soft Sage (#B4C7B0) blob, 30% opacity
  - Bottom-right: Friendly Coral (#ff8370) blob, 20% opacity
  - Optional: Small Sunshine Yellow (#FFD93D) accent shape
- XL rounded corners on decorative shapes (border-radius: 40-70% organic shapes)
- Generous white space around text for readability
- Professional, clean layout (not cluttered)

Typography:
- Heading "SALONGROEI": Serif font (Noto Serif Black or similar), 72-90pt, Expert Navy (#1E3A5F)
- Tagline: Sans-serif (Noto Sans Bold or Inter Bold), 36-42pt, Expert Navy (#1E3A5F)
- Subtitle: Sans-serif, 24-28pt, Expert Navy (#1E3A5F) at 70% opacity

Spacing:
- Generous padding from edges (80-100px)
- Text centered vertically and horizontally
- Breathing room between text elements

Style: Friendly yet authoritative, professional, clean, social media optimized
Purpose: This image will appear when links are shared on Facebook, Twitter, LinkedIn, WhatsApp

CRITICAL: All text must be clearly readable at small sizes (social media thumbnails). High contrast between text and background is essential."""


def generate_og_image(model="nano-banana-pro", output_dir=None):
    """Generate the default OG image"""

    # Set output directory
    if output_dir is None:
        output_dir = Path(__file__).parent.parent / "public" / "images"
    else:
        output_dir = Path(output_dir)

    output_dir.mkdir(parents=True, exist_ok=True)
    output_filename = "og-default.jpg"
    output_path = output_dir / output_filename

    print(f"🎨 Generating default OG image for Salongroei...")
    print(f"   Model: {model}")
    print(f"   Output: {output_path}")
    print(f"   Size: 1200×630px (16:9 aspect ratio)\n")

    try:
        # Initialize generator
        generator = GeminiImageGenerator(output_dir=str(output_dir), model=model)

        # Generate image (use 16:9 for OG images)
        result = generator.generate_image(
            prompt=OG_IMAGE_PROMPT,
            aspect_ratio="16:9",  # 1200×630 falls into 16:9 category
            output_filename=output_filename,
            return_base64=False
        )

        if result.get('success', False):
            print(f"✅ Success! OG image generated: {output_path}")
            print(f"\n📋 Next steps:")
            print(f"   1. Verify the image looks good")
            print(f"   2. Check text is readable")
            print(f"   3. Rebuild Docker: docker-compose build --no-cache")
            print(f"   4. Test social sharing: https://developers.facebook.com/tools/debug/")
            print(f"\n💰 Cost: ~$0.134 (Gemini 3.0 Pro - nano-banana-pro)")
            return True
        else:
            print(f"❌ Failed to generate OG image")
            return False

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Generate default OG image for Salongroei")
    parser.add_argument(
        "--model",
        default="nano-banana-pro",
        choices=["nano-banana-pro", "nano-banana", "imagen-4", "imagen-3"],
        help="Model to use for generation (default: nano-banana-pro for best quality)"
    )
    parser.add_argument(
        "--output-dir",
        help="Output directory (default: public/images/)"
    )

    args = parser.parse_args()

    success = generate_og_image(model=args.model, output_dir=args.output_dir)
    sys.exit(0 if success else 1)
