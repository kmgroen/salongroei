# SalonGroei Blog Image Style Guide

## Brand Identity
- **Primary**: Teal (#14B8A6) — trust, growth, professionalism
- **Secondary**: Navy (#1E293B) — expertise, authority
- **Accent**: Sunshine Yellow (#FBBF24) — warmth, optimism
- **Soft Sage**: (#B4C7B0) — calm, natural, wellness
- **Background**: Cream (#FFF8F0) — clean, warm, approachable
- **Coral accent**: (#ff8370) — energy, beauty

## Visual Style — "Salon Expert Editorial"

All blog images follow a consistent 3D pastel illustration style:

```
3D minimalistic pastel illustration viewed from slightly elevated angle,
clean warm cream (#FFF8F0) background with very subtle gradient to soft peach,
frosted glass texture with slight transparency effects,
pastel color palette (teal, cream, soft sage, coral, warm gold accents),
matte clay texture, rounded organic forms,
warm editorial salon aesthetic,
rendered in soft natural lighting, volumetric gentle shadows,
center composition, inviting and professional,
no text, no labels, no words, no numbers
```

## Image Dimensions

| Type | Dimensions | Format | Use |
|------|-----------|--------|-----|
| Blog hero | 1200×630px | WebP or PNG | Blog detail page + OG image |
| Aspect ratio | 1.91:1 | — | Matches Open Graph standard |

## Prompt Template

### Base Prompt
```
3D minimalistic pastel illustration of [SUBJECT],
viewed from slightly elevated angle showing top surfaces,
clean warm cream background with very subtle gradient to soft peach,
frosted glass texture with slight transparency effects,
pastel color palette (teal, cream, soft sage, coral, warm gold accents),
matte clay texture, rounded organic forms,
warm editorial salon aesthetic with beauty industry elements,
rendered in soft natural lighting with volumetric gentle shadows,
center composition, inviting and professional,
no text, no labels, no words, no numbers
```

### Category-Specific Subjects

| Blog Topic | Subject Description |
|-----------|-------------------|
| **No-shows / Reminders** | salon chair with floating notification bell and checkmark, calendar with teal highlights, small clock |
| **Online Booking / 24/7** | open laptop showing booking calendar, floating clock showing 9pm, small moon and stars, coffee cup |
| **Capacity Planning** | salon floor plan with 3 chairs, bar chart showing occupancy, small calendar with peak day highlighted |
| **Waitlist Management** | queue of cute clay figures waiting, clipboard with list, green arrow showing progress |
| **Double Bookings** | two overlapping calendar blocks (one red, one green), sync arrows, salon mirror |
| **Software Comparison** | multiple app windows side-by-side, magnifying glass, star ratings, teal checkmarks |
| **Marketing / Growth** | small salon storefront with growth arrow rising behind, social media icons, megaphone |
| **Client Retention** | heart shape with customer silhouette inside, loyalty card, returning arrow |

### Growth/Success Topics — Add Growth Arrow
For topics about improvement, ROI, or growth, add:
```
with large, bold, smooth curved teal growth arrow fully positioned behind [SUBJECT],
rising diagonally toward upper right corner in a flowing arc,
arrow partially obscured by [SUBJECT] creating layered depth,
```

## Generation Command

```bash
uv run /Users/kaspergroen/moltbot/skills/nano-banana-pro/scripts/generate_image.py \
  --prompt "[FULL PROMPT]" \
  --filename "blog-[slug]-hero.png" \
  --resolution 2K
```

## Quality Checklist

- [ ] Matches SalonGroei brand colors (teal, cream, sage, coral)
- [ ] Warm, inviting salon/beauty aesthetic
- [ ] No text, labels, or words in image
- [ ] Clean composition, not cluttered
- [ ] 3D clay/pastel style consistent across all blog images
- [ ] Relevant to blog content
- [ ] Works as OG image (readable at small size)

## Current Blog Posts Needing Images

| Blog | Current Image | Status |
|------|--------------|--------|
| reduce-no-shows | picsum.photos placeholder | ❌ Need hero |
| 24-7-booking-benefits | picsum.photos placeholder | ❌ Need hero |
| capacity-planning | picsum.photos placeholder | ❌ Need hero |
| prevent-double-bookings | picsum.photos placeholder | ❌ Need hero |
| waitlist-management | picsum.photos placeholder | ❌ Need hero |

Note: Infographics already exist in `/public/images/infographics/` — those are data-focused.
Blog hero images are visual/editorial — different purpose.
