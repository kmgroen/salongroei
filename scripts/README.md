# Salongroei Infographic Generation

This directory contains scripts for generating AI-powered infographics for blog posts using Google Gemini 3.0 Pro.

## Setup

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Set up your Gemini API key:
   ```bash
   export GEMINI_API_KEY="your-api-key-here"
   ```

   Or create a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your-api-key-here
   ```

## Usage

### Generate All Infographics

Generate infographics for all 5 blog posts:

```bash
python3 scripts/generate_blog_infographics.py
```

This will create 5 infographics in `public/images/infographics/`:
- `no-shows-statistics-infographic.png` (reduce-no-shows blog)
- `online-booking-benefits-infographic.png` (24-7-booking-benefits blog)
- `waitlist-management-infographic.png` (waitlist-management blog)
- `prevent-double-bookings-infographic.png` (prevent-double-bookings blog)
- `capacity-planning-infographic.png` (capacity-planning blog)

### Generate Single Infographic

Generate for a specific blog post:

```bash
python3 scripts/generate_blog_infographics.py reduce-no-shows
python3 scripts/generate_blog_infographics.py 24-7-booking-benefits
python3 scripts/generate_blog_infographics.py waitlist-management
python3 scripts/generate_blog_infographics.py prevent-double-bookings
python3 scripts/generate_blog_infographics.py capacity-planning
```

### Model Selection

Use a different Gemini model:

```bash
# Use Gemini 3.0 Pro (best quality, text rendering) - $0.134/image
python3 scripts/generate_blog_infographics.py --model nano-banana-pro

# Use Gemini 2.5 Flash (faster, cheaper) - $0.039/image
python3 scripts/generate_blog_infographics.py --model nano-banana

# Use Imagen 4 (high quality alternative) - $0.04/image
python3 scripts/generate_blog_infographics.py --model imagen-4
```

**Recommended:** `nano-banana-pro` for best text rendering and professional infographics.

## Infographic Specifications

All infographics are generated with:
- **Size:** 1200×800px (3:2 aspect ratio)
- **Format:** PNG
- **Style:** Professional, data-driven, modern salon industry
- **Colors:** Teal (#14B8A6), Navy (#1E3A5F), Green (#22C55E), Red (#EF4444)
- **Typography:** Sans-serif (Montserrat, Inter, or Open Sans)

## Cost Estimation

Using `nano-banana-pro` (recommended):
- **Per infographic:** $0.134
- **All 5 infographics:** ~$0.67

Using `nano-banana` (faster, cheaper):
- **Per infographic:** $0.039
- **All 5 infographics:** ~$0.20

## Infographic Details

### 1. No-Shows Statistics
- **Blog:** reduce-no-shows
- **Type:** Stats Grid (3 large numbers)
- **Key Stats:** 67% fewer no-shows, €75 per no-show, €13,000 annual loss

### 2. Online Booking Benefits
- **Blog:** 24-7-booking-benefits
- **Type:** Stats Grid with icons
- **Key Stats:** 80% bookings after hours, 5-10 hours saved, 15-20% higher margin

### 3. Waitlist Management Impact
- **Blog:** waitlist-management
- **Type:** Before/After comparison
- **Key Stats:** 2-3 days vs 1-2 hours fill time, €65 vs €78 revenue per slot

### 4. Prevent Double Bookings
- **Blog:** prevent-double-bookings
- **Type:** Problem/Solution flow (3 steps)
- **Key Message:** 15% have double bookings → Real-time sync → 0% double bookings

### 5. Capacity Planning
- **Blog:** capacity-planning
- **Type:** Weekly pattern chart
- **Key Insights:** Saturday peak, optimal 75-80% occupancy, 15-20% labor cost savings

## Troubleshooting

### API Key Not Found
```bash
Error: GEMINI_API_KEY environment variable not set
```
**Solution:** Set the `GEMINI_API_KEY` environment variable or create a `.env` file.

### Import Error
```bash
Error: Could not import generate_images.py
```
**Solution:** Ensure `generate_images.py` is in `scripts/images/` directory.

### Rate Limiting
If you hit API rate limits, wait a few minutes between generations or use `--model nano-banana` for faster processing.

## Adding New Infographics

To add a new infographic for a new blog post:

1. Edit `generate_blog_infographics.py`
2. Add a new entry to the `BLOG_INFOGRAPHICS` dictionary:
   ```python
   "your-blog-slug": {
       "prompt": "Your detailed Gemini prompt...",
       "filename": "your-infographic.png",
       "alt_nl": "Dutch alt text",
       "alt_en": "English alt text"
   }
   ```

3. Generate:
   ```bash
   python3 scripts/generate_blog_infographics.py your-blog-slug
   ```

## Integration with Blog Posts

Infographics are automatically available at:
```
/images/infographics/{filename}
```

Example in markdown:
```markdown
![Alt text](/images/infographics/no-shows-statistics-infographic.png)
```

## Image Versioning System

To prevent frontend caching issues, all images use an automatic versioning system.

### How It Works

1. **Version Registry**: `src/utils/imageVersion.ts` maintains version numbers for all images
2. **Versioned URLs**: Images are loaded with query parameters (e.g., `/images/infographic.png?v=2`)
3. **Auto-Increment**: When regenerating infographics, version numbers increment automatically
4. **Cache Busting**: New version numbers force browser to reload images

### Automatic Version Updates

When you generate infographics, versions update automatically:

```bash
# Generates infographics AND increments versions
python3 scripts/generate_blog_infographics.py
```

The script will:
1. Generate all 5 infographics
2. Automatically increment version numbers in `imageVersion.ts`
3. Force browsers to reload new images (no cache issues)

### Manual Version Updates

If you need to manually update versions:

```bash
# Increment all infographic versions
python3 scripts/update_image_versions.py --increment /images/infographics/

# Increment all image versions
python3 scripts/update_image_versions.py --increment all

# Set specific version for an image
python3 scripts/update_image_versions.py --set /images/infographics/no-shows.png 5
```

### Using Versioned Images in Code

**In Astro Components:**
```astro
---
import { getVersionedImageUrl } from '@/utils/imageVersion'
---

<img src={getVersionedImageUrl('/images/blog/hero.jpg')} alt="..." />
```

**In Blog Markdown:**
Images in frontmatter are automatically versioned by the BlogPost layout:
```yaml
---
image: "/images/infographics/no-shows-statistics-infographic.png"
---
```

The image URL automatically becomes `/images/infographics/no-shows-statistics-infographic.png?v=2`

### Adding New Images

When adding new images to the project:

1. Add the image to the appropriate directory (e.g., `public/images/blog/`)
2. Register it in `src/utils/imageVersion.ts`:
   ```typescript
   export const IMAGE_VERSIONS: Record<string, number> = {
     '/images/blog/my-new-image.jpg': 1,
     // ... existing entries
   }
   ```
3. Use `getVersionedImageUrl()` when referencing the image

### Troubleshooting

**Image not updating after regeneration?**
- Check that the image path is registered in `imageVersion.ts`
- Verify version number incremented (check `imageVersion.ts`)
- Clear browser cache (hard reload: Shift+Cmd+R on Mac, Ctrl+Shift+R on Windows)

**Version script not running?**
- Ensure `update_image_versions.py` is executable
- Check Python 3 is installed
- Run manually: `python3 scripts/update_image_versions.py --increment /images/infographics/`

## Source Attribution

This infographic generation system is adapted from the WeCare Reservation project and uses:
- Google Gemini 3.0 Pro (nano-banana-pro)
- Gemini 2.5 Flash (nano-banana)
- Imagen 4/3 models

Original scripts: `/Users/kaspergroen/GitHub/wecarereservations/scripts/images/`
