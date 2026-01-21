# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Generic Guidelines
- reply extremely concisely, sacrifice grammar for concision
- don't write summary docs unless asked
- assign tasks to subagents, parallel where
- SRP and small files extremely important

## Commands
```bash
npm run dev      # Dev server at localhost:4321
npm run build    # Build to ./dist/
npm run preview  # Preview production build
```

Deploy: `./scripts/deploy_prod.sh` (interactive menu: build, deploy, SSL, nginx), deploymentalway done by user. 

## Stack
Astro 5 + React 19 + Tailwind. Static site output.

## i18n
- Default: `nl`, secondary: `en`
- Dutch pages at root, English at `/en/`
- Translations: `src/i18n/config.ts` (ui object)
- Use `getLangFromUrl()` and `useTranslations()` from `src/i18n/utils.ts`

## Content Collections
`src/content/` with Astro collections:
- `blog/` - markdown articles (nl + en suffixes)
- `guides/` - markdown guides
- `tools/` - JSON tool definitions

## Structure
```
src/
├── pages/          # Astro routes (file-based)
├── layouts/        # BaseLayout, BlogPost, GuideLayout
├── components/     # Astro + React components
│   ├── blog/       # Blog-specific
│   ├── tools/      # Tool comparison
│   ├── guides/     # Guide components
│   └── seo/        # Structured data components
├── content/        # Collections (blog, guides, tools)
└── i18n/           # Translations
```

## Docs
- `docs/ACCESSIBILITY.md` - a11y guidelines
- `docs/production-optimization.md` - performance tuning
- `workspace/infographic-style-guide.md` - image generation prompts

## Styling
Brand colors: teal (#14B8A6), navy (#1E293B). See `/styling-guide` page.
