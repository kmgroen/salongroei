import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

const SITE_URL = 'https://salongroei.com';

export const GET: APIRoute = async () => {
  // Get all content collections
  const blogPosts = await getCollection('blog');
  const tools = await getCollection('tools');
  const guides = await getCollection('guides');

  // Static pages (NL and EN)
  const staticPages = [
    { url: '/', priority: '1.0', changefreq: 'daily' },
    { url: '/en', priority: '1.0', changefreq: 'daily' },
    { url: '/blog', priority: '0.9', changefreq: 'daily' },
    { url: '/en/blog', priority: '0.9', changefreq: 'daily' },
    { url: '/tools', priority: '0.9', changefreq: 'weekly' },
    { url: '/guides', priority: '0.8', changefreq: 'weekly' },
    { url: '/en/guides', priority: '0.8', changefreq: 'weekly' },
  ];

  // Build sitemap URLs
  const staticUrls = staticPages
    .map(
      (page) => `
  <url>
    <loc>${SITE_URL}${page.url}</loc>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>`
    )
    .join('');

  // Blog post URLs (both NL and EN)
  const blogUrls = blogPosts
    .flatMap((post) => {
      const slug = post.id.replace('.md', '');
      return [
        {
          url: `/blog/${slug}`,
          lastmod: post.data.date.toISOString().split('T')[0],
          priority: '0.8',
          changefreq: 'weekly',
        },
        {
          url: `/en/blog/${slug}`,
          lastmod: post.data.date.toISOString().split('T')[0],
          priority: '0.8',
          changefreq: 'weekly',
        },
      ];
    })
    .map(
      (page) => `
  <url>
    <loc>${SITE_URL}${page.url}</loc>
    <lastmod>${page.lastmod}</lastmod>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>`
    )
    .join('');

  // Tool page URLs
  const toolUrls = tools
    .map((tool) => ({
      url: `/tools/${tool.data.slug}`,
      priority: '0.9',
      changefreq: 'monthly',
    }))
    .map(
      (page) => `
  <url>
    <loc>${SITE_URL}${page.url}</loc>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>`
    )
    .join('');

  // Guide page URLs (both NL and EN)
  const guideUrls = guides
    .flatMap((guide) => {
      const slug = guide.id.replace('.md', '');
      const lang = guide.data.lang || 'nl';
      const lastmod = guide.data.updatedDate
        ? guide.data.updatedDate.toISOString().split('T')[0]
        : guide.data.publishDate.toISOString().split('T')[0];

      return [
        {
          url: lang === 'nl' ? `/guides/${slug}` : `/en/guides/${slug}`,
          lastmod,
          priority: '0.8',
          changefreq: 'monthly',
        },
      ];
    })
    .map(
      (page) => `
  <url>
    <loc>${SITE_URL}${page.url}</loc>
    <lastmod>${page.lastmod}</lastmod>
    <changefreq>${page.changefreq}</changefreq>
    <priority>${page.priority}</priority>
  </url>`
    )
    .join('');

  // Generate sitemap XML
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
${staticUrls}${blogUrls}${toolUrls}${guideUrls}
</urlset>`;

  return new Response(sitemap, {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
      'Cache-Control': 'max-age=3600, public',
    },
  });
};
