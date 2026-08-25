// @ts-check
import { defineConfig } from "astro/config";
import preact from "@astrojs/preact";
import sitemap from "@astrojs/sitemap";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  site: "https://nickmckay.org",
  integrations: [preact(), sitemap()],
  vite: {
    plugins: [tailwindcss()],
  },
  // GitHub Pages has no server redirects; these emit meta-refresh stub pages
  // for URLs retired in the 2026 Hugo -> Astro migration (blog removed, form
  // page folded into /contact/).
  redirects: {
    "/blog/": "/publications/",
    "/blog/4.2ka-event-not-remarkable/": "/publications/",
    "/blog/arctic-snowline-rise/": "/publications/",
    "/blog/damp21ka-data-assimilation/": "/publications/",
    "/blog/global-water-cycle-response/": "/publications/",
    "/form/": "/contact/",
  },
});
