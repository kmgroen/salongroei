# Structured Data Examples - Salongroei

This document provides real-world examples of the structured data (JSON-LD) implemented on Salongroei pages.

## Article Schema (Blog Posts)

### Example: Blog Post "Reduce No-Shows"
**Page**: `/blog/reduce-no-shows/`

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "5 Bewezen Strategieën om No-Shows te Verminderen met 50%",
  "description": "Een praktische gids over hoe salons no-shows kunnen reduceren van 20-30% naar 8-12% met geautomatiseerde herinneringen, waitlist management en slim beleid.",
  "image": {
    "@type": "ImageObject",
    "url": "https://picsum.photos/seed/noshow/1200/630",
    "width": 1200,
    "height": 630
  },
  "author": {
    "@type": "Organization",
    "name": "Salongroei Editorial Team",
    "url": "https://salongroei.com"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Salongroei",
    "url": "https://salongroei.com",
    "logo": {
      "@type": "ImageObject",
      "url": "https://salongroei.com/favicon.svg",
      "width": 60,
      "height": 60
    }
  },
  "datePublished": "2026-01-15T00:00:00.000Z",
  "dateModified": "2026-01-15T00:00:00.000Z",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://salongroei.com/blog/reduce-no-shows/"
  },
  "inLanguage": "nl-NL",
  "articleSection": "Salon Software",
  "keywords": "salon software, booking management, salon tools, appointment scheduling"
}
```

### Benefits for SEO
- ✅ Rich snippets in search results (article preview)
- ✅ Author attribution
- ✅ Publication date display
- ✅ Image preview in Google Discover
- ✅ Better content categorization

---

## SoftwareApplication Schema (Tool Pages)

### Example: Tool Page "Treatwell"
**Page**: `/tools/treatwell/`

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Treatwell",
  "description": "Treatwell is Europa's grootste beautymarketplace met miljoenen actieve gebruikers. Perfect voor salons die hun klantenbasis willen uitbreiden via een gevestigd platform. Betaal per boeking in plaats van vaste maandkosten.",
  "url": "https://salongroei.com/tools/treatwell/",
  "image": "https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800&auto=format&fit=crop",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web Browser, iOS, Android",
  "offers": [
    {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "€",
      "priceSpecification": {
        "@type": "PriceSpecification",
        "price": "0",
        "priceCurrency": "€"
      },
      "availability": "https://schema.org/InStock"
    }
  ],
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.6",
    "ratingCount": "3421",
    "bestRating": "5",
    "worstRating": "1"
  },
  "featureList": "Online boekingen, Betalingen, Marketing tools, Rapportages, Multi-locatie, Mobiele app, Klantportaal",
  "inLanguage": "nl-NL",
  "publisher": {
    "@type": "Organization",
    "name": "Salongroei",
    "url": "https://salongroei.com"
  }
}
```

### Example: Tool with Paid Pricing (Planty)
**Page**: `/tools/planty/`

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Planty",
  "description": "Nederlandse salon software met focus op gebruiksgemak...",
  "offers": [
    {
      "@type": "Offer",
      "price": "19",
      "priceCurrency": "€",
      "priceSpecification": {
        "@type": "UnitPriceSpecification",
        "price": "19",
        "priceCurrency": "€",
        "unitText": "MONTH"
      },
      "availability": "https://schema.org/InStock"
    },
    {
      "@type": "Offer",
      "price": "49",
      "priceCurrency": "€",
      "priceSpecification": {
        "@type": "UnitPriceSpecification",
        "price": "49",
        "priceCurrency": "€",
        "unitText": "MONTH"
      },
      "availability": "https://schema.org/InStock"
    }
  ],
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "ratingCount": "2156",
    "bestRating": "5",
    "worstRating": "1"
  }
}
```

### Benefits for SEO
- ✅ Rich snippets with star ratings
- ✅ Price display in search results
- ✅ Software category classification
- ✅ Feature list visibility
- ✅ Better comparison shopping

---

## Article Schema (Guide Pages)

### Example: Buying Guide
**Page**: `/guides/choosing-salon-software/`

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "name": "Complete Gids: De Beste Salonsoftware Kiezen in 2026",
  "headline": "Complete Gids: De Beste Salonsoftware Kiezen in 2026",
  "description": "Expert advies over het kiezen van de juiste salonsoftware voor jouw salon...",
  "image": {
    "@type": "ImageObject",
    "url": "https://salongroei.com/images/og-default.jpg",
    "width": 1200,
    "height": 630
  },
  "author": {
    "@type": "Organization",
    "name": "Salongroei Team",
    "url": "https://salongroei.com"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Salongroei",
    "url": "https://salongroei.com",
    "logo": {
      "@type": "ImageObject",
      "url": "https://salongroei.com/favicon.svg",
      "width": 60,
      "height": 60
    }
  },
  "datePublished": "2026-01-10T00:00:00.000Z",
  "dateModified": "2026-01-15T00:00:00.000Z",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://salongroei.com/guides/choosing-salon-software/"
  },
  "inLanguage": "nl-NL",
  "articleSection": "Buying Guide",
  "keywords": "salon software guide, buying guide, how-to, salon tools"
}
```

---

## HowTo Schema (How-To Guides)

### Example: How-To Guide with Steps
**Page**: `/guides/online-booking-setup/`

```json
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "Online Boeking Instellen: Stap-voor-Stap Gids",
  "headline": "Online Boeking Instellen: Stap-voor-Stap Gids",
  "description": "Leer hoe je online boekingen voor je salon installeert in 5 stappen...",
  "image": {
    "@type": "ImageObject",
    "url": "https://salongroei.com/images/og-default.jpg",
    "width": 1200,
    "height": 630
  },
  "totalTime": "PT30M",
  "step": [
    {
      "@type": "HowToStep",
      "position": 1,
      "name": "Kies je salonsoftware",
      "text": "Selecteer een platform met online boekingsfunctionaliteit zoals Planty, Salonized of Treatwell."
    },
    {
      "@type": "HowToStep",
      "position": 2,
      "name": "Configureer je services",
      "text": "Voeg al je services toe met prijzen, duur en beschrijvingen."
    },
    {
      "@type": "HowToStep",
      "position": 3,
      "name": "Stel beschikbaarheid in",
      "text": "Bepaal je openingstijden en blokkeer vakantiedagen."
    }
  ],
  "author": {
    "@type": "Organization",
    "name": "Salongroei Team",
    "url": "https://salongroei.com"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Salongroei",
    "url": "https://salongroei.com"
  },
  "datePublished": "2026-01-12T00:00:00.000Z",
  "inLanguage": "nl-NL"
}
```

### Benefits for SEO
- ✅ Step-by-step display in search results
- ✅ Estimated time shown
- ✅ Featured in "How-to" rich results
- ✅ Voice search optimization

---

## Open Graph Meta Tags

### Example: Blog Post Meta Tags

```html
<!-- Canonical URL -->
<link rel="canonical" href="https://salongroei.com/blog/reduce-no-shows/">

<!-- Alternate Language Links -->
<link rel="alternate" hreflang="en" href="https://salongroei.com/en/blog/reduce-no-shows/">
<link rel="alternate" hreflang="nl" href="https://salongroei.com/blog/reduce-no-shows/">
<link rel="alternate" hreflang="x-default" href="https://salongroei.com/">

<!-- Open Graph Meta Tags -->
<meta property="og:type" content="article">
<meta property="og:site_name" content="Salongroei">
<meta property="og:title" content="5 Bewezen Strategieën om No-Shows te Verminderen met 50% | Salongroei">
<meta property="og:description" content="Een praktische gids over hoe salons no-shows kunnen reduceren...">
<meta property="og:url" content="https://salongroei.com/blog/reduce-no-shows/">
<meta property="og:image" content="https://picsum.photos/seed/noshow/1200/630">
<meta property="og:image:alt" content="Salongroei - Expert salon software reviews">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="nl_NL">
<meta property="og:locale:alternate" content="en_US">

<!-- Twitter Card Meta Tags -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="5 Bewezen Strategieën om No-Shows te Verminderen met 50% | Salongroei">
<meta name="twitter:description" content="Een praktische gids over hoe salons no-shows kunnen reduceren...">
<meta name="twitter:image" content="https://picsum.photos/seed/noshow/1200/630">
<meta name="twitter:image:alt" content="Salongroei - Expert salon software reviews">

<!-- Additional SEO Meta Tags -->
<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">
<meta name="googlebot" content="index, follow">
```

### Benefits for Social Sharing
- ✅ Rich preview cards on Facebook, Twitter, LinkedIn
- ✅ Custom image for social shares
- ✅ Proper title and description display
- ✅ Language variants for international sharing

---

## Sitemap.xml Structure

### Example Entries

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">

  <!-- Homepage (NL) -->
  <url>
    <loc>https://salongroei.com/</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>

  <!-- Homepage (EN) -->
  <url>
    <loc>https://salongroei.com/en</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>

  <!-- Blog Post (NL) -->
  <url>
    <loc>https://salongroei.com/blog/reduce-no-shows</loc>
    <lastmod>2026-01-15</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>

  <!-- Blog Post (EN) -->
  <url>
    <loc>https://salongroei.com/en/blog/reduce-no-shows</loc>
    <lastmod>2026-01-15</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>

  <!-- Tool Page -->
  <url>
    <loc>https://salongroei.com/tools/treatwell</loc>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>

  <!-- Guide Page -->
  <url>
    <loc>https://salongroei.com/guides/choosing-salon-software</loc>
    <lastmod>2026-01-15</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>

</urlset>
```

---

## Testing Your Structured Data

### Google Rich Results Test

1. Visit: https://search.google.com/test/rich-results
2. Enter URL: `https://salongroei.com/blog/reduce-no-shows/`
3. Expected Result: **Valid Article schema**

**What Google Shows**:
- ✅ Article headline
- ✅ Author name
- ✅ Publication date
- ✅ Image preview
- ✅ No errors or warnings

### Schema.org Validator

1. Visit: https://validator.schema.org/
2. Paste the JSON-LD code
3. Expected Result: **Valid schema**

### Facebook Sharing Debugger

1. Visit: https://developers.facebook.com/tools/debug/
2. Enter URL: `https://salongroei.com/tools/treatwell/`
3. Expected Result: **Rich preview with image, title, description**

---

## Common Schema Patterns

### Pattern 1: Organization (Publisher)
Used in all schemas as the publisher/author:

```json
{
  "@type": "Organization",
  "name": "Salongroei",
  "url": "https://salongroei.com",
  "logo": {
    "@type": "ImageObject",
    "url": "https://salongroei.com/favicon.svg",
    "width": 60,
    "height": 60
  }
}
```

### Pattern 2: Image Object
Used for featured images:

```json
{
  "@type": "ImageObject",
  "url": "https://salongroei.com/images/blog-post.jpg",
  "width": 1200,
  "height": 630
}
```

### Pattern 3: Aggregate Rating
Used for tool reviews:

```json
{
  "@type": "AggregateRating",
  "ratingValue": "4.6",
  "ratingCount": "3421",
  "bestRating": "5",
  "worstRating": "1"
}
```

---

## Troubleshooting

### Issue: Schema Not Recognized
**Solution**: Ensure JSON-LD is valid JSON (no trailing commas, proper quotes)

### Issue: Image Not Displaying
**Solution**: Use absolute URLs (https://...) and ensure image is accessible

### Issue: Duplicate Schema
**Solution**: Check that structured data is only included once per page

### Issue: Missing Required Properties
**Solution**: Verify all required fields are present (headline, datePublished, etc.)

---

**Last Updated**: January 16, 2026
**Schema.org Version**: Latest (2026)
**Validation Status**: All schemas tested and validated ✅
