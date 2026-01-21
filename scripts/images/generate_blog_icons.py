#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "google-genai>=1.46.0",
#     "python-dotenv>=1.0.0",
#     "pillow>=10.0.0",
# ]
# ///
"""
Generate blog header images using Nano Banana Pro (Gemini 3 Pro Image).

This script generates complete blog card header images with:
- Light teal gradient background (from #F0FDFA to #CCFBF1)
- Topic-related icon positioned in bottom-right corner
- Clean, minimalist SalonUp brand style

Usage:
    cd scripts/images
    uv run generate_blog_icons.py                           # Process all blogs without icons
    uv run generate_blog_icons.py introducing-salonup       # Process specific blog
    uv run generate_blog_icons.py --force                   # Regenerate all icons

Model: Nano Banana Pro (gemini-3-pro-image-preview)
- Released: November 2025
- Cost: $0.134/image (1K-2K), $0.24/image (4K)
- Best for: Complex compositions, text rendering, multi-turn editing
"""

import os
import sys
import json
import argparse
from pathlib import Path
from datetime import datetime

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent))
from generate_images import GeminiImageGenerator

from PIL import Image


# Base prompt template for all blog headers
# Very specific to get consistent results
BASE_PROMPT = """Create a minimalist blog header image with these exact specifications:

BACKGROUND:
- Smooth diagonal gradient from top-left to bottom-right
- Start color: very light mint/teal (#F0FDFA) at top-left
- End color: slightly deeper mint (#CCFBF1) at bottom-right
- Clean, professional look with no texture or noise

ICON:
- Single minimalist line-art icon in bottom-right area
- Icon color: teal (#14B8A6)
- Icon style: simple, clean line art with consistent stroke width
- Icon opacity: subtle, approximately 20-30% opacity
- Icon slightly rotated (about -8 degrees)
- Icon should be: {icon_description}

COMPOSITION:
- Icon positioned in bottom-right quadrant
- Plenty of empty space on left side for text overlay
- Clean, modern, professional aesthetic
- No text, no watermarks, no additional elements

Style: Clean corporate SaaS design, minimalist, professional"""


# Icon descriptions for different blog topics
ICON_DESCRIPTIONS = {
    # Category-based defaults
    'tutorials': 'an open book with a small lightbulb or star above it, representing learning and guidance',
    'salon-tips': 'professional scissors crossing a styling comb, representing hair salon expertise',
    'business-growth': 'an upward trending graph or arrow with small growth indicators, representing business success',
    'client-experience': 'a smiling face or heart with small decorative elements, representing customer satisfaction',
    'industry-trends': 'a crystal ball or trending sparkle icon, representing future insights',

    # Blog-specific descriptions (override category defaults)
    'introducing-salonup': 'a calendar with a checkmark and small sparkle stars, representing organized scheduling and new beginnings',
    'salonup-getting-started-guide': 'a rocket ship launching upward with a small checklist, representing quick start and setup',
    'configure-automatic-reminders': 'a bell with notification indicator dots and small clock element, representing automated notifications',
    'first-week-online-booking': 'a smartphone showing a calendar interface with checkmarks, representing mobile booking success',
}


def get_icon_description(slug: str, category: str) -> str:
    """Get the appropriate icon description for a blog."""
    # Try blog-specific description first
    if slug in ICON_DESCRIPTIONS:
        return ICON_DESCRIPTIONS[slug]

    # Fall back to category description
    if category in ICON_DESCRIPTIONS:
        return ICON_DESCRIPTIONS[category]

    # Default fallback
    return 'a lightbulb with small decorative elements, representing ideas and knowledge'


def load_blog_metadata(blog_dir: Path) -> dict:
    """Load blog metadata from metadata.json."""
    metadata_file = blog_dir / 'metadata.json'
    if metadata_file.exists():
        with open(metadata_file) as f:
            return json.load(f)
    return {}


def generate_header_image(generator: GeminiImageGenerator, blog_dir: Path, slug: str, metadata: dict) -> bool:
    """Generate header image for a single blog."""
    category = metadata.get('category', 'tutorials')
    icon_description = get_icon_description(slug, category)

    # Build the full prompt
    prompt = BASE_PROMPT.format(icon_description=icon_description)

    print(f"\n📸 Generating header for: {slug}")
    print(f"   Category: {category}")
    print(f"   Icon: {icon_description[:60]}...")

    # Generate image with 21:9 aspect ratio (widest supported, ~2.33:1)
    # Then crop to 3:1 for blog card header
    output_file = f"header_{slug}.png"
    result = generator.generate_image(
        prompt=prompt,
        aspect_ratio='21:9',  # Widest supported ratio
        output_filename=output_file
    )

    if not result.get('success'):
        print(f"  ❌ Generation failed: {result.get('error', 'Unknown error')}")
        return False

    # Get the generated image path
    generated_path = Path(result['image_path'])

    # Move/copy to blog directory as header image
    target_path = blog_dir / 'header.png'

    # Crop from 21:9 (~2.33:1) to 3:1 ratio, then resize to 1200x400
    with Image.open(generated_path) as img:
        width, height = img.size

        # Calculate target height for 3:1 ratio
        target_height = width // 3

        # Center crop vertically if needed
        if height > target_height:
            top = (height - target_height) // 2
            img = img.crop((0, top, width, top + target_height))

        # Save full-size version (1200x400)
        img_resized = img.resize((1200, 400), Image.Resampling.LANCZOS)
        img_resized.save(target_path, 'PNG', optimize=True)

        # Save thumbnail version (740x247 for 2x retina at 370x123 display)
        thumb_path = blog_dir / 'header-thumb.webp'
        img_thumb = img.resize((740, 247), Image.Resampling.LANCZOS)
        img_thumb.save(thumb_path, 'WEBP', quality=85)

    # Remove temp file
    generated_path.unlink()

    print(f"  ✅ Header saved: {target_path}")
    print(f"     Full: 1200x400 PNG")
    print(f"     Thumb: 740x247 WebP ({thumb_path.stat().st_size // 1024}KB)")
    return True


def process_blogs(blog_slugs: list[str], force: bool = False, model: str = 'nano-banana-pro') -> dict:
    """Process multiple blogs to generate header images."""
    # Find media/blogs directory
    script_dir = Path(__file__).parent
    media_blogs_dir = script_dir.parent.parent / 'media' / 'blogs'

    if not media_blogs_dir.exists():
        print(f"❌ Blog directory not found: {media_blogs_dir}")
        return {'success': 0, 'failed': 0, 'skipped': 0}

    # Initialize generator
    output_dir = script_dir / 'generated_headers'
    output_dir.mkdir(exist_ok=True)

    try:
        generator = GeminiImageGenerator(
            output_dir=str(output_dir),
            model=model
        )
    except ValueError as e:
        print(f"❌ Failed to initialize generator: {e}")
        print("\nSet GOOGLE_API_KEY_IMAGES or GEMINI_API_KEY environment variable")
        return {'success': 0, 'failed': 0, 'skipped': 0}

    # Get blogs to process
    if blog_slugs:
        blog_dirs = [media_blogs_dir / slug for slug in blog_slugs if (media_blogs_dir / slug).exists()]
        not_found = [slug for slug in blog_slugs if not (media_blogs_dir / slug).exists()]
        if not_found:
            print(f"⚠️  Blogs not found: {', '.join(not_found)}")
    else:
        blog_dirs = [
            d for d in media_blogs_dir.iterdir()
            if d.is_dir() and not d.name.startswith(('.', '_', 'a_'))
        ]

    print(f"\n{'='*60}")
    print(f"SalonUp Blog Header Generator")
    print(f"{'='*60}")
    print(f"Model: {model} (Nano Banana Pro)")
    print(f"Blogs to process: {len(blog_dirs)}")
    print(f"Force regenerate: {force}")
    print(f"Output: 1200x400 PNG (3:1 aspect ratio)")
    print(f"{'='*60}")

    stats = {'success': 0, 'failed': 0, 'skipped': 0}
    total_cost = 0

    for blog_dir in sorted(blog_dirs):
        slug = blog_dir.name
        header_path = blog_dir / 'header.png'

        # Skip if header exists and not forcing
        if header_path.exists() and not force:
            print(f"⏭️  {slug}: header already exists")
            stats['skipped'] += 1
            continue

        # Load metadata
        metadata = load_blog_metadata(blog_dir)
        if not metadata:
            print(f"⚠️  {slug}: no metadata.json found")
            stats['failed'] += 1
            continue

        # Generate header image
        if generate_header_image(generator, blog_dir, slug, metadata):
            stats['success'] += 1
            total_cost += generator.model_config['cost']
        else:
            stats['failed'] += 1

    # Print summary
    print(f"\n{'='*60}")
    print(f"Generation Complete")
    print(f"{'='*60}")
    print(f"✅ Success: {stats['success']}")
    print(f"⏭️  Skipped: {stats['skipped']}")
    print(f"❌ Failed: {stats['failed']}")
    print(f"💰 Total cost: ${total_cost:.2f}")
    print(f"{'='*60}")

    return stats


def main():
    parser = argparse.ArgumentParser(
        description='Generate blog header images using Nano Banana Pro (Gemini 3 Pro Image)'
    )
    parser.add_argument(
        'slugs',
        nargs='*',
        help='Specific blog slug(s) to process (optional, processes all if omitted)'
    )
    parser.add_argument(
        '--force',
        action='store_true',
        help='Regenerate headers even if they already exist'
    )
    parser.add_argument(
        '--model',
        default='nano-banana-pro',
        choices=['nano-banana-pro', 'nano-banana', 'imagen-4'],
        help='Model to use for generation (default: nano-banana-pro)'
    )
    args = parser.parse_args()

    stats = process_blogs(args.slugs, args.force, args.model)

    return 0 if stats['failed'] == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
