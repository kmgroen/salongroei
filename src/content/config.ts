import { defineCollection, z } from 'astro:content';

const guidesCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    type: z.enum(['buying-guide', 'how-to', 'comparison', 'checklist']),
    difficulty: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
    estimatedTime: z.string().optional(),
    author: z.string().default('Salongroei Team'),
    publishDate: z.date(),
    updatedDate: z.date().optional(),
    image: z.string().optional(),
    relatedTools: z.array(z.string()).optional(),
    lang: z.enum(['nl', 'en']).default('nl'),
  }),
});

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.object({
      nl: z.string(),
      en: z.string(),
    }),
    description: z.object({
      nl: z.string(),
      en: z.string(),
    }),
    category: z.string(),
    date: z.date(),
    image: z.string().optional(),
    author: z.string().default('Salongroei Editorial Team'),
    tags: z.array(z.string()).optional(),
    featured: z.boolean().default(false),
  }),
});

const toolsCollection = defineCollection({
  type: 'data',
  schema: z.object({
    name: z.string(),
    slug: z.string(),
    tagline: z.object({
      nl: z.string(),
      en: z.string(),
    }),
    description: z.object({
      nl: z.string(),
      en: z.string(),
    }),
    accentColor: z.enum(['soft-sage', 'sunshine-yellow', 'primary']),
    isEditorsPick: z.boolean().default(false),
    displayOrder: z.number().optional(),
    imageUrl: z.string(),
    imageAlt: z.string(),
    rating: z.object({
      score: z.number().min(0).max(5),
      count: z.number(),
    }),
    pricing: z.object({
      starter: z.object({
        price: z.number().optional(),
        currency: z.string().default('€'),
        period: z.string().default('month'),
        label: z.object({
          nl: z.string(),
          en: z.string(),
        }),
        features: z.array(z.object({
          nl: z.string(),
          en: z.string(),
        })),
        isFree: z.boolean().default(false),
        hasCommission: z.boolean().default(false),
        commissionRate: z.number().optional(),
      }),
      pro: z.object({
        price: z.number(),
        currency: z.string().default('€'),
        period: z.string().default('month'),
        label: z.object({
          nl: z.string(),
          en: z.string(),
        }),
        features: z.array(z.object({
          nl: z.string(),
          en: z.string(),
        })),
      }).optional(),
      enterprise: z.object({
        isCustom: z.boolean().default(true),
        label: z.object({
          nl: z.string(),
          en: z.string(),
        }),
        features: z.array(z.object({
          nl: z.string(),
          en: z.string(),
        })),
      }).optional(),
    }),
    features: z.object({
      booking: z.boolean(),
      payments: z.boolean(),
      marketing: z.boolean(),
      inventory: z.boolean(),
      reporting: z.boolean(),
      multiLocation: z.boolean(),
      mobileApp: z.boolean(),
      clientPortal: z.boolean(),
    }),
    pros: z.array(z.object({
      nl: z.string(),
      en: z.string(),
    })),
    cons: z.array(z.object({
      nl: z.string(),
      en: z.string(),
    })),
    bestFor: z.object({
      nl: z.string(),
      en: z.string(),
    }),
    freeTrial: z.object({
      available: z.boolean(),
      days: z.number().optional(),
    }),
    website: z.string().url(),
    affiliateLink: z.string().url().optional(),
  }),
});

export const collections = {
  guides: guidesCollection,
  blog,
  tools: toolsCollection,
};
