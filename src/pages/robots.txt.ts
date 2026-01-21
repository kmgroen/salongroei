import type { APIRoute } from 'astro';

const SITE_URL = 'https://salongroei.com';

export const GET: APIRoute = () => {
  const robotsTxt = `# Salongroei - Robots.txt
# Allow all crawlers to access the site

User-agent: *
Allow: /

# Sitemap location
Sitemap: ${SITE_URL}/sitemap.xml

# Disallow admin/private paths (if any)
Disallow: /api/
Disallow: /.well-known/

# Crawl delay (optional - uncomment if needed)
# Crawl-delay: 1

# Specific bot instructions (optional)
User-agent: Googlebot
Allow: /

User-agent: Bingbot
Allow: /
`;

  return new Response(robotsTxt, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'max-age=86400, public',
    },
  });
};
