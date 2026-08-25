import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const projects = defineCollection({
  loader: glob({ pattern: "*.md", base: "./src/content/projects" }),
  schema: z.object({
    title: z.string(),
    subtitle: z.string().default(""),
    excerpt: z.string().default(""),
    date: z.string(),
    image: z.string(),
    links: z.array(z.object({ name: z.string(), url: z.string() })).default([]),
  }),
});

export const collections = { projects };
