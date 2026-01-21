# Create Default OG Image for Salongroei

## Required Specifications

**Dimensions**: 1200×630px (1.91:1 aspect ratio)
**Format**: JPG or PNG
**File Name**: `og-default.jpg`
**Location**: `/public/images/og-default.jpg`

## Design Requirements

### Brand Colors (from Styling Guide)
- **Primary (Friendly Coral)**: #ff8370
- **Expert Navy**: #1E3A5F
- **Background Cream**: #FFF8F0
- **Soft Sage**: #B4C7B0
- **Sunshine Yellow**: #FFD93D

### Typography
- **Display Font**: Noto Serif (bold/black weight)
- **Body Font**: Noto Sans

### Content to Include

1. **Logo/Brand Name**: "Salongroei" (top or center)
2. **Tagline**: "Vind de Beste Salon Software" (NL) or "Find the Best Salon Software" (EN)
3. **Visual Elements**:
   - Organic shapes (scribbles/blobs)
   - Soft rounded corners
   - Professional salon imagery (optional)

### Layout Suggestions

**Option 1: Simple & Clean**
```
+--------------------------------------------+
|                                            |
|            [Background Cream]              |
|                                            |
|         SALONGROEI                         |
|         (Expert Navy, Noto Serif Bold)     |
|                                            |
|    Vind de Beste Salon Software            |
|    (Expert Navy, Noto Sans)                |
|                                            |
|    [Coral accent shape bottom-right]       |
|                                            |
+--------------------------------------------+
```

**Option 2: Colorful with Shapes**
```
+--------------------------------------------+
|  [Soft Sage blob top-left]                 |
|                                            |
|         SALONGROEI                         |
|         (Expert Navy)                      |
|                                            |
|    Vergelijk • Reviews • Gidsen            |
|    (Primary Coral)                         |
|                                            |
|              [Sunshine accent shape]       |
|  [Coral blob bottom-right]                 |
+--------------------------------------------+
```

## Quick Creation Methods

### Method 1: Figma/Sketch (Recommended)
1. Create 1200×630px canvas
2. Background: #FFF8F0 (Background Cream)
3. Add "Salongroei" text: Noto Serif Black, 80-100pt, #1E3A5F
4. Add tagline: Noto Sans Bold, 36-48pt, #1E3A5F
5. Add organic shapes using pen tool (Friendly Coral #ff8370)
6. Export as JPG (quality 90%)

### Method 2: Canva (Quick)
1. Create custom size: 1200×630px
2. Background: #FFF8F0
3. Add text with Google Fonts (Noto Serif + Noto Sans)
4. Use shape elements for organic blobs
5. Download as PNG/JPG

### Method 3: Photoshop/GIMP
1. New document: 1200×630px, 72 DPI
2. Fill background: #FFF8F0
3. Text tool: Noto Serif Bold, "Salongroei"
4. Add tagline with Noto Sans
5. Create shapes on separate layers
6. Save for Web (JPG, optimized)

### Method 4: HTML/CSS Screenshot (Developer Friendly)
Create HTML file, open in browser, screenshot at exact dimensions:

```html
<!DOCTYPE html>
<html>
<head>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@600&family=Noto+Serif:wght@900&display=swap" rel="stylesheet">
  <style>
    body {
      margin: 0;
      width: 1200px;
      height: 630px;
      background: #FFF8F0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      position: relative;
      overflow: hidden;
    }
    h1 {
      font-family: 'Noto Serif', serif;
      font-weight: 900;
      font-size: 80px;
      color: #1E3A5F;
      margin: 0 0 20px 0;
    }
    p {
      font-family: 'Noto Sans', sans-serif;
      font-weight: 600;
      font-size: 36px;
      color: #1E3A5F;
      margin: 0;
    }
    .blob1 {
      position: absolute;
      top: -50px;
      left: -50px;
      width: 300px;
      height: 300px;
      background: #B4C7B0;
      border-radius: 40% 60% 70% 30% / 40% 50% 60% 50%;
      opacity: 0.3;
    }
    .blob2 {
      position: absolute;
      bottom: -80px;
      right: -80px;
      width: 400px;
      height: 400px;
      background: #ff8370;
      border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%;
      opacity: 0.2;
    }
  </style>
</head>
<body>
  <div class="blob1"></div>
  <div class="blob2"></div>
  <h1>Salongroei</h1>
  <p>Vind de Beste Salon Software</p>
</body>
</html>
```

## After Creating

1. Save as `/public/images/og-default.jpg`
2. Verify file size < 500KB (optimize if needed)
3. Test with Facebook Sharing Debugger: https://developers.facebook.com/tools/debug/
4. Test with Twitter Card Validator: https://cards-dev.twitter.com/validator
5. Rebuild Docker to include the image

## Verification

After adding the image, verify it appears in:
- Homepage meta tags
- Blog posts without custom images
- Tool pages without custom images
- Guide pages without custom images
- 404 pages

The image will automatically be used by the SEOMetaTags component for pages without a specific `image` prop.
