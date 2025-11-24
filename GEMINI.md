# GEMINI.md

## Project Overview

**Awesome Claude Code** (Claude Code Academy) is a comprehensive, open-source learning resource hub for Claude Code developers, catering specifically to the Chinese-speaking community. It serves as a documentation site built with **Next.js** and **Nextra**.

### Key Technologies
*   **Framework:** Next.js 14
*   **Documentation Theme:** Nextra 3 (Docs Theme)
*   **Styling:** Tailwind CSS (via Nextra)
*   **Language:** TypeScript / JavaScript / MDX
*   **Package Manager:** `pnpm` (Preferred over npm/yarn per `CLAUDE.md`)

## Building and Running

This project prefers `pnpm`. Ensure you have Node.js 18+ installed.

### Core Commands
*   **Install Dependencies:**
    ```bash
    pnpm install
    ```
*   **Start Development Server:**
    ```bash
    pnpm dev
    ```
    Access at `http://localhost:3000`.
*   **Build for Production:**
    ```bash
    pnpm build
    ```
    This generates a static export (configured in `next.config.mjs`).
*   **Preview Production Build:**
    ```bash
    pnpm start
    ```
*   **Lint Code:**
    ```bash
    pnpm lint
    ```

## Development Conventions

### File Structure
*   `pages/`: Contains the content as `.mdx` files.
    *   `_meta.js`: Configuration file in each directory defining the navigation order and titles.
*   `components/`: Custom React components.
*   `public/`: Static assets (images, global CSS).
*   `theme.config.jsx`: Global configuration for the Nextra theme.

### Content Management (MDX)
*   **Frontmatter:** Every `.mdx` file should include `title` and `description`.
    ```yaml
    ---
    title: Page Title
    description: Brief description for SEO
    ---
    ```
*   **Navigation:** When adding a new page, update the `_meta.js` in the same directory to include the filename (without extension) and its display title.

### UI Components
Use built-in Nextra components imported from `nextra/components`:
*   `<Callout type="info|warning|error|success">Content</Callout>`
*   `<Cards><Cards.Card ... /></Cards>`
*   `<Tabs><Tabs.Tab ... /></Tabs>`
*   `<Steps>...</Steps>` (for tutorials)

### Git & Contribution
*   **Branch Naming:** `feature/xxx`, `fix/xxx`, `docs/xxx`, `style/xxx`.
*   **Commit Messages:**
    *   `Add:` New content/features
    *   `Update:` Modifications to existing content
    *   `Fix:` Bug fixes
    *   `Style:` Formatting changes
    *   Example: `git commit -m "Add: Tutorial for MCP Servers"`

### Troubleshooting
*   **Broken Links:** Run `pnpm build` and use a link checker if available (or manual verification).
*   **Cache Issues:** If changes aren't reflecting, remove the `.next` directory: `rm -rf .next && pnpm dev`.
