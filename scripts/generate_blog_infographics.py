#!/usr/bin/env python3
"""
Generate infographics for Salongroei blog posts using Gemini 3.0 Pro (nano-banana-pro)
Adapted from WeCare Reservation infographic generation system
"""

import os
import sys
import json
from pathlib import Path

# Add scripts/images to path for imports
sys.path.insert(0, str(Path(__file__).parent / "images"))

try:
    from generate_images import GeminiImageGenerator
except ImportError:
    print("Error: Could not import generate_images.py")
    print("Make sure generate_images.py is in scripts/images/")
    sys.exit(1)


def generate_image(prompt, output_path, model="nano-banana-pro", aspect_ratio="3:2", return_base64=False):
    """Wrapper function for GeminiImageGenerator"""
    try:
        # Initialize generator with output directory
        output_dir = Path(output_path).parent
        generator = GeminiImageGenerator(output_dir=str(output_dir), model=model)

        # Generate image
        result = generator.generate_image(
            prompt=prompt,
            aspect_ratio=aspect_ratio,
            output_filename=Path(output_path).name,
            return_base64=return_base64
        )

        return result.get('success', False)
    except Exception as e:
        print(f"Error in generate_image: {e}")
        return False

# Infographic prompts for each blog post
BLOG_INFOGRAPHICS = {
    "reduce-no-shows": {
        "prompt": """Create a professional infographic (1200×800px, 3:2 ratio) about reducing no-shows in salons.

Layout: Stats Grid with 3 large numbers

Statistics to display:
• "67% MINDER NO-SHOWS" (large, Soft Sage #B4C7B0)
• "€75 PER NO-SHOW" (large, Expert Navy #1E3A5F)
• "€13,000 JAARLIJKS VERLIES" (large, Friendly Coral #ff8370)

Design:
- Background Cream (#FFF8F0) background
- Serif fonts for headings (Noto Serif), Sans-serif for body (Montserrat or Inter)
- Each stat in its own XL rounded card/box (1.5rem border-radius)
- Icons: calendar with X, euro symbol, trending down arrow
- Bottom text: "Bron: Zenoti Waitlist Study 2025, GlossGenius Data"
- Color palette: Friendly Coral #ff8370 (accents), Expert Navy #1E3A5F (dark text), Soft Sage #B4C7B0 (positive stats), Sunshine Yellow #FFD93D (highlights), Background Cream #FFF8F0

Style: Friendly yet authoritative, professional, data-driven""",
        "filename": "no-shows-statistics-infographic.png",
        "alt_nl": "Infographic toont 67% minder no-shows, €75 kosten per no-show, en €13.000 jaarlijks verlies",
        "alt_en": "Infographic shows 67% fewer no-shows, €75 cost per no-show, and €13,000 annual loss"
    },

    "24-7-booking-benefits": {
        "prompt": """Create a professional infographic (1200×800px, 3:2 ratio) about 24/7 online booking benefits for salons.

Layout: Stats Grid with 3 large numbers + visual

Statistics to display:
• "80% BUITEN KANTOORUREN" (large, Friendly Coral #ff8370)
• "5-10 UUR PER WEEK BESPAARD" (large, Soft Sage #B4C7B0)
• "15-20% HOGERE WINSTMARGE" (large, Expert Navy #1E3A5F)

Design:
- Background Cream (#FFF8F0) with white (#FFFFFF) cards
- Clock icon showing 24/7 availability
- Phone icon crossed out (no more phone calls)
- Calendar icon with checkmark
- Serif fonts for headings (Noto Serif), Sans-serif for body (Montserrat or Inter)
- Each stat in XL rounded card with icon (1.5rem border-radius)
- Bottom text: "Bron: SalonUp Industry Research 2025"
- Color palette: Friendly Coral #ff8370 (CTAs/accents), Expert Navy #1E3A5F (headings), Soft Sage #B4C7B0 (positive stats), Sunshine Yellow #FFD93D (highlights), Background Cream #FFF8F0

Style: Friendly yet authoritative, professional, energetic""",
        "filename": "online-booking-benefits-infographic.png",
        "alt_nl": "Infographic toont 80% boekingen buiten kantooruren, 5-10 uur per week bespaard, 15-20% hogere winstmarge",
        "alt_en": "Infographic shows 80% bookings outside office hours, 5-10 hours saved per week, 15-20% higher profit margin"
    },

    "waitlist-management": {
        "prompt": """Create a professional infographic (1200×800px, 3:2 ratio) about waitlist management impact for salons.

Layout: Before/After comparison

Left side - "ZONDER WAITLIST":
• "2-3 DAGEN tot opvulling" (large number, Friendly Coral #ff8370 - warning)
• "€65 omzet per slot" (Expert Navy #1E3A5F)
• Lost revenue visualization

Right side - "MET WAITLIST":
• "1-2 UUR tot opvulling" (large number, Soft Sage #B4C7B0 - positive)
• "€78 omzet per slot" (Expert Navy #1E3A5F)
• Increased revenue visualization

Bottom banner: "5-8x SNELLER • 20% HOGERE OMZET" (Sunshine Yellow #FFD93D background)

Design:
- Background Cream (#FFF8F0) with white (#FFFFFF) cards
- Clean split design with arrow from left to right
- Icons: hourglass, euro symbols, trending up
- Serif fonts for headings (Noto Serif), Sans-serif for body (Montserrat or Inter)
- XL rounded corners (1.5rem border-radius)
- Bottom text: "Bron: Zenoti Waitlist Study 2025"
- Color palette: Friendly Coral #ff8370 (warnings/CTAs), Expert Navy #1E3A5F (dark text), Soft Sage #B4C7B0 (positive stats), Sunshine Yellow #FFD93D (highlights), Background Cream #FFF8F0, White #FFFFFF (cards)

Style: Friendly yet authoritative, professional, impact-focused, data-driven""",
        "filename": "waitlist-management-infographic.png",
        "alt_nl": "Infographic vergelijkt salon zonder en met waitlist: 2-3 dagen vs 1-2 uur opvulling, €65 vs €78 omzet",
        "alt_en": "Infographic compares salon without and with waitlist: 2-3 days vs 1-2 hours fill time, €65 vs €78 revenue"
    },

    "prevent-double-bookings": {
        "prompt": """Create a professional infographic (1200×800px, 3:2 ratio) about preventing double bookings with real-time calendar sync.

Layout: Problem/Solution flow with 3 steps

Step 1 - PROBLEEM (Friendly Coral #ff8370):
• Calendar icon with overlapping appointments
• "15% van salons heeft wekelijks double bookings"
• Frustrated customer icon

Step 2 - OPLOSSING (Sunshine Yellow #FFD93D):
• Real-time sync icon (two calendars with sync arrows)
• "Real-time synchronisatie"
• Cloud icon

Step 3 - RESULTAAT (Soft Sage #B4C7B0):
• Checkmark icon
• "0% double bookings"
• Happy customer icon
• "30% meer boekingen"

Design:
- Background Cream (#FFF8F0) with white (#FFFFFF) cards
- Horizontal flow with arrows between steps
- Icons for each step
- Serif fonts for headings (Noto Serif), Sans-serif for body (Montserrat or Inter)
- Each step in XL rounded card (1.5rem border-radius)
- Bottom text: "Bron: Phorest Sync Study 2025"
- Color palette: Friendly Coral #ff8370 (problems/CTAs), Expert Navy #1E3A5F (dark text), Soft Sage #B4C7B0 (positive results), Sunshine Yellow #FFD93D (solutions/highlights), Background Cream #FFF8F0, White #FFFFFF (cards)

Style: Friendly yet authoritative, clean, flow-based, solution-focused""",
        "filename": "prevent-double-bookings-infographic.png",
        "alt_nl": "Infographic toont probleem van double bookings, oplossing met real-time sync, en resultaat van 0% double bookings",
        "alt_en": "Infographic shows double booking problem, real-time sync solution, and result of 0% double bookings"
    },

    "capacity-planning": {
        "prompt": """Create a professional infographic (1200×800px, 3:2 ratio) about salon capacity planning for busy periods.

Layout: Weekly pattern chart with insights

Top: Weekly booking pattern graph showing:
• Monday-Friday bars increasing
• Weekend peak (Saturday highest)
• Color-coded by booking volume (use Friendly Coral #ff8370 for peak, Soft Sage #B4C7B0 for moderate, Expert Navy #1E3A5F for low)

Key Insights (3 boxes below):
• "PIEKDAG: ZATERDAG" (Friendly Coral #ff8370) - "75-85% bezetting"
• "RUSTIGE DAG: MAANDAG" (Expert Navy #1E3A5F) - "40-50% bezetting"
• "OPTIMALE BEZETTING: 75-80%" (Soft Sage #B4C7B0)

Bottom section:
• "Predictieve staffing bespaart 15-20% loonkosten" (Sunshine Yellow #FFD93D highlight)
• Calendar icon + staff icons

Design:
- Background Cream (#FFF8F0) with white (#FFFFFF) cards
- Bar chart visualization at top
- Three insight cards with XL rounded corners (1.5rem border-radius)
- Serif fonts for headings (Noto Serif), Sans-serif for body (Montserrat or Inter)
- Bottom text: "Bron: Timely Analytics Report 2025"
- Color palette: Friendly Coral #ff8370 (peak/CTAs), Expert Navy #1E3A5F (dark text/low volume), Soft Sage #B4C7B0 (optimal/moderate), Sunshine Yellow #FFD93D (highlights), Background Cream #FFF8F0, White #FFFFFF (cards)

Style: Friendly yet authoritative, data visualization, professional, analytics-focused""",
        "filename": "capacity-planning-infographic.png",
        "alt_nl": "Infographic toont weekpatroon van salonboekingen met zaterdag als piekdag en optimale bezetting van 75-80%",
        "alt_en": "Infographic shows weekly salon booking pattern with Saturday as peak day and optimal occupancy of 75-80%"
    }
}


def ensure_output_directory():
    """Create output directory for infographics"""
    output_dir = Path(__file__).parent.parent / "public" / "images" / "infographics"
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def generate_all_infographics(model="nano-banana-pro"):
    """Generate infographics for all blog posts"""
    output_dir = ensure_output_directory()

    print(f"🎨 Generating {len(BLOG_INFOGRAPHICS)} infographics for Salongroei blog posts...")
    print(f"   Model: {model}")
    print(f"   Output: {output_dir}\n")

    results = {}

    for blog_slug, config in BLOG_INFOGRAPHICS.items():
        print(f"📊 Generating infographic for '{blog_slug}'...")
        print(f"   Filename: {config['filename']}")

        try:
            # Generate image using Gemini
            output_path = output_dir / config['filename']

            success = generate_image(
                prompt=config['prompt'],
                output_path=str(output_path),
                model=model,
                aspect_ratio="3:2",  # 1200×800px
                return_base64=False
            )

            if success:
                print(f"   ✅ Success: {output_path}")
                results[blog_slug] = {
                    "success": True,
                    "path": str(output_path),
                    "filename": config['filename'],
                    "alt_nl": config['alt_nl'],
                    "alt_en": config['alt_en']
                }
            else:
                print(f"   ❌ Failed to generate infographic")
                results[blog_slug] = {"success": False}

        except Exception as e:
            print(f"   ❌ Error: {e}")
            results[blog_slug] = {"success": False, "error": str(e)}

        print()

    # Save metadata
    metadata_path = output_dir / "infographics-metadata.json"
    with open(metadata_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"📝 Metadata saved to: {metadata_path}")

    # Summary
    successful = sum(1 for r in results.values() if r.get("success"))
    print(f"\n✨ Summary: {successful}/{len(BLOG_INFOGRAPHICS)} infographics generated successfully")

    # Update image versions if any infographics were generated
    if successful > 0:
        print(f"\n🔄 Updating image versions...")
        import subprocess
        try:
            subprocess.run([
                "python3",
                str(Path(__file__).parent / "update_image_versions.py"),
                "--increment",
                "/images/infographics/"
            ], check=True)
        except subprocess.CalledProcessError as e:
            print(f"   ⚠️  Warning: Failed to update image versions: {e}")
        except FileNotFoundError:
            print(f"   ⚠️  Warning: update_image_versions.py not found")

    return results


def generate_single_infographic(blog_slug, model="nano-banana-pro"):
    """Generate infographic for a single blog post"""
    if blog_slug not in BLOG_INFOGRAPHICS:
        print(f"❌ Error: Blog slug '{blog_slug}' not found")
        print(f"   Available: {', '.join(BLOG_INFOGRAPHICS.keys())}")
        return False

    output_dir = ensure_output_directory()
    config = BLOG_INFOGRAPHICS[blog_slug]

    print(f"📊 Generating infographic for '{blog_slug}'...")
    print(f"   Model: {model}")
    print(f"   Filename: {config['filename']}")

    output_path = output_dir / config['filename']

    try:
        success = generate_image(
            prompt=config['prompt'],
            output_path=str(output_path),
            model=model,
            aspect_ratio="3:2",
            return_base64=False
        )

        if success:
            print(f"   ✅ Success: {output_path}")

            # Update image version
            print(f"\n🔄 Updating image version...")
            import subprocess
            try:
                image_path = f"/images/infographics/{config['filename']}"
                subprocess.run([
                    "python3",
                    str(Path(__file__).parent / "update_image_versions.py"),
                    "--increment",
                    "/images/infographics/"
                ], check=True)
            except subprocess.CalledProcessError as e:
                print(f"   ⚠️  Warning: Failed to update image version: {e}")
            except FileNotFoundError:
                print(f"   ⚠️  Warning: update_image_versions.py not found")

            return True
        else:
            print(f"   ❌ Failed to generate infographic")
            return False

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Generate infographics for Salongroei blog posts")
    parser.add_argument(
        "blog_slug",
        nargs="?",
        help="Blog slug to generate infographic for (omit to generate all)"
    )
    parser.add_argument(
        "--model",
        default="nano-banana-pro",
        choices=["nano-banana-pro", "nano-banana", "imagen-4", "imagen-3"],
        help="Model to use for generation (default: nano-banana-pro)"
    )

    args = parser.parse_args()

    if args.blog_slug:
        generate_single_infographic(args.blog_slug, args.model)
    else:
        generate_all_infographics(args.model)
