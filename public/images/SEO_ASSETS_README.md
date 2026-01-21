# SEO Assets

## Required Images

### Open Graph Default Image
**Location**: `/public/images/og-default.jpg`
**Dimensions**: 1200 x 630 pixels
**Format**: JPG or PNG
**Max size**: 300KB recommended

This image is used as the default social media preview when sharing Salongroei pages.

**Design Requirements**:
- Include Salongroei branding/logo
- Use brand colors: primary (#ff8370), expert-navy (#1E3A5F), soft-sage (#B4C7B0)
- Clear, readable text
- Professional salon-related imagery
- Works well at different scales (Facebook, Twitter, LinkedIn)

**How to Create**:
1. Use a design tool (Figma, Canva, Photoshop)
2. Create a 1200x630px canvas
3. Add Salongroei logo and tagline
4. Export as JPG with 85% quality or PNG
5. Save as `/public/images/og-default.jpg`

**Temporary Note**:
Until a custom image is created, the SEO meta tags will reference this file.
Update the image path in `/src/components/seo/SEOMetaTags.astro` if using a different name or location.
