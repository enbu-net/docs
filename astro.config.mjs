// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import starlightLlmsTxt from "starlight-llms-txt";
import starlightDotMd from "starlight-dot-md";
import starlightCopyButton from "starlight-copy-button";

// https://astro.build/config
export default defineConfig({
  site: "https://enbu.net",
  integrations: [
    starlight({
      title: "enbu",
      social: [{ icon: "github", label: "GitHub", href: "https://github.com/yashikota/enbu" }],
      sidebar: [
        {
          label: "Documentation",
          items: [{ autogenerate: { directory: "docs" } }],
        },
      ],
      plugins: [starlightLlmsTxt(), starlightDotMd(), starlightCopyButton({ label: "Copy as MD" })],
    }),
  ],
});
