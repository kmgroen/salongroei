# Production Optimization Guide

This document provides recommendations for production deployment optimizations that should be configured at the server/hosting level for optimal performance of the Salongroei website.

## Overview

The application code has been optimized with lazy loading, responsive images, and font optimization. This guide covers additional server-side optimizations that will significantly improve performance metrics.

## 1. Compression

### Brotli Compression (Recommended)

Brotli provides better compression ratios than Gzip, especially for text-based assets.

**Configuration:**
- Enable Brotli compression for all text-based assets
- Compression level: 4-6 (balance between compression ratio and CPU usage)
- Pre-compress static assets during build time when possible

**File Types to Compress:**
```
text/html
text/css
text/javascript
application/javascript
application/json
application/xml
text/xml
image/svg+xml
application/font-woff
application/font-woff2
```

**Expected Impact:**
- 15-30% smaller file sizes compared to Gzip
- Faster page load times, especially on slower connections
- Reduced bandwidth costs

### Gzip Compression (Fallback)

For browsers that don't support Brotli, Gzip should be enabled as a fallback.

**Configuration:**
- Compression level: 6 (default)
- Same file types as Brotli

### Implementation Examples

**Nginx:**
```nginx
# Brotli
brotli on;
brotli_comp_level 4;
brotli_types text/plain text/css application/javascript application/json image/svg+xml application/xml+rss text/xml;

# Gzip fallback
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/javascript application/json image/svg+xml application/xml+rss text/xml;
```

**Apache (.htaccess):**
```apache
# Enable Brotli if available
<IfModule mod_brotli.c>
    AddOutputFilterByType BROTLI_COMPRESS text/html text/css application/javascript application/json image/svg+xml
</IfModule>

# Enable Gzip
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/css application/javascript application/json image/svg+xml
</IfModule>
```

**Cloudflare/CDN:**
- Most CDNs enable Brotli and Gzip automatically
- Verify in CDN settings that compression is enabled for all relevant file types

## 2. Cache-Control Headers

Proper caching significantly reduces server load and improves repeat visit performance.

### Static Assets (Long-term Caching)

**File Types:**
- CSS files: `/assets/*.css`
- JavaScript files: `/assets/*.js`
- Images: `*.jpg`, `*.png`, `*.webp`, `*.svg`
- Fonts: `*.woff`, `*.woff2`

**Recommended Headers:**
```
Cache-Control: public, max-age=31536000, immutable
```

**Explanation:**
- `public`: Can be cached by browsers and CDNs
- `max-age=31536000`: Cache for 1 year (365 days)
- `immutable`: Tells browser the file will never change (perfect for versioned assets)

### HTML Pages (Short-term Caching)

**File Types:**
- `*.html`
- `/` (root)

**Recommended Headers:**
```
Cache-Control: public, max-age=3600, must-revalidate
```

**Explanation:**
- `max-age=3600`: Cache for 1 hour
- `must-revalidate`: Check with server after cache expires

### Dynamic Content / API Responses

**Recommended Headers:**
```
Cache-Control: no-cache, must-revalidate
```

### Implementation Examples

**Nginx:**
```nginx
# Static assets (versioned)
location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, max-age=31536000, immutable";
}

# HTML pages
location ~* \.html$ {
    expires 1h;
    add_header Cache-Control "public, max-age=3600, must-revalidate";
}

# Root and other routes
location / {
    expires 1h;
    add_header Cache-Control "public, max-age=3600, must-revalidate";
}
```

**Apache (.htaccess):**
```apache
<IfModule mod_expires.c>
    ExpiresActive On

    # Static assets
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType font/woff "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"

    # HTML
    ExpiresByType text/html "access plus 1 hour"
</IfModule>

<IfModule mod_headers.c>
    # Add immutable to static assets
    <FilesMatch "\.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2)$">
        Header set Cache-Control "public, max-age=31536000, immutable"
    </FilesMatch>

    # HTML caching
    <FilesMatch "\.html$">
        Header set Cache-Control "public, max-age=3600, must-revalidate"
    </FilesMatch>
</IfModule>
```

**Vercel (vercel.json):**
```json
{
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/(.*)\\.html",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=3600, must-revalidate"
        }
      ]
    }
  ]
}
```

## 3. ETags for Images

ETags provide validation caching for resources that might change.

**Recommended Configuration:**
- Enable ETags for all image assets
- Combine with Cache-Control headers
- Allows browsers to validate cached images with lightweight requests

**Expected Impact:**
- Reduced bandwidth for unchanged images
- Faster validation of cached resources
- Better user experience for frequently updated content

### Implementation Examples

**Nginx:**
```nginx
# ETags are enabled by default in Nginx
# Ensure they're not disabled
etag on;

# For images specifically
location ~* \.(jpg|jpeg|png|gif|svg|webp)$ {
    etag on;
    expires 1y;
    add_header Cache-Control "public, max-age=31536000, immutable";
}
```

**Apache:**
```apache
# ETags are enabled by default in Apache
# Configure ETag format (optional)
FileETag MTime Size

<FilesMatch "\.(jpg|jpeg|png|gif|svg|webp)$">
    # ETags will be automatically generated
</FilesMatch>
```

## 4. Additional Performance Optimizations

### Image Format Optimization

**Recommendation:**
- Serve WebP images with JPEG/PNG fallbacks
- Use Astro's Image component for automatic optimization
- Consider AVIF for even better compression (with fallbacks)

### Content Delivery Network (CDN)

**Recommendation:**
- Use a CDN (Cloudflare, Vercel, Netlify, etc.)
- Benefits:
  - Global edge caching
  - Automatic Brotli/Gzip compression
  - DDoS protection
  - Automatic SSL/TLS

### HTTP/2 and HTTP/3

**Recommendation:**
- Enable HTTP/2 (most hosting providers support this by default)
- Consider HTTP/3/QUIC for even better performance
- Benefits:
  - Multiplexing (parallel requests)
  - Header compression
  - Server push capabilities

### Preload Key Resources

Already implemented in the codebase:
- Critical fonts are preloaded
- Consider preloading hero images for specific pages

## 5. Monitoring and Validation

### Tools to Measure Performance

**Lighthouse (Chrome DevTools):**
```bash
# Run Lighthouse CI
npm install -g @lhci/cli
lhci autorun
```

**WebPageTest:**
- Visit: https://www.webpagetest.org
- Test from multiple locations
- Check compression and caching headers

**GTmetrix:**
- Visit: https://gtmetrix.com
- Verify Brotli/Gzip compression
- Check cache-control headers

### Expected Lighthouse Scores (After Implementation)

**Before Optimizations:**
- Performance: 70-80
- Best Practices: 80-90

**After Optimizations:**
- Performance: 90-100
- Best Practices: 95-100
- Accessibility: 95-100
- SEO: 100

### Key Metrics to Monitor

1. **First Contentful Paint (FCP):** < 1.8s
2. **Largest Contentful Paint (LCP):** < 2.5s
3. **Time to Interactive (TTI):** < 3.8s
4. **Cumulative Layout Shift (CLS):** < 0.1
5. **Total Blocking Time (TBT):** < 200ms

## 6. Deployment Checklist

- [ ] Enable Brotli compression on server/CDN
- [ ] Enable Gzip compression as fallback
- [ ] Configure Cache-Control headers for static assets (1 year)
- [ ] Configure Cache-Control headers for HTML (1 hour)
- [ ] Enable ETags for images
- [ ] Test compression with browser DevTools
- [ ] Verify caching headers with curl or browser
- [ ] Run Lighthouse audit on production URL
- [ ] Test from multiple geographic locations
- [ ] Monitor Core Web Vitals in Google Search Console

## 7. Platform-Specific Guides

### Vercel

Vercel handles most optimizations automatically:
- Brotli/Gzip: Automatic
- HTTP/2: Automatic
- CDN: Automatic
- Custom headers: Use `vercel.json`

### Netlify

Netlify also handles most optimizations:
- Brotli/Gzip: Automatic
- HTTP/2: Automatic
- CDN: Automatic
- Custom headers: Use `_headers` file

### Docker/Self-Hosted

Follow Nginx/Apache configuration examples above.

## Summary

Implementing these production optimizations will:
- Reduce page load time by 30-50%
- Improve Lighthouse performance score by 10-20 points
- Reduce bandwidth costs by 20-40%
- Improve user experience significantly
- Boost SEO rankings (page speed is a ranking factor)

All optimizations are non-breaking and can be implemented gradually. Start with compression and caching headers for the biggest impact.
