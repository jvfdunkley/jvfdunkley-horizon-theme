# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## File Modification Guideline

### When Working with Liquid Files

**Sections** (`sections/*.liquid`):

- Each section is standalone and can be added via theme editor
- Include schema blocks at the end defining settings
- Use `{% render 'snippet-name' %}` to include snippets
- Reference settings via `section.settings.setting_name`

**Section Schema Design Patterns**:

- **Parent-Child Settings Hierarchy**: Parent section settings should control child block behavior
  - Section-level settings (e.g., `text_alignment`, `element_gap`) should apply to ALL child blocks
  - Use CSS variables to cascade parent settings to children (e.g., `--alignment`, `--text-align`, `--element-gap`)
  - Layout control belongs exclusively at the parent section level

  **CSS Implementation Pattern**:
  - Set CSS variables on the section container based on Liquid settings
  - Example:
    ```liquid
    <div class="section" style="
      {% if section.settings.text_alignment == 'center' %}
        --alignment: center;
        --text-align: center;
      {% endif %}
    ">
    ```
  - Child elements inherit these variables automatically
  - Wrapper uses flexbox/grid with alignment from CSS variables: `align-items: var(--alignment)`
  - Individual blocks inherit text alignment: `text-align: inherit` or `text-align: var(--text-align)`

- **Settings Organization**: Group related settings logically
  - Layout settings (alignment, width, spacing)
  - Animation/interaction settings (speed, transitions)
  - Visual settings (colors, typography)
  - Content settings (text, images)

- **Block Limits**: Use `"limit": N` in block definitions to control how many can be added
  - Example: `"limit": 1` for static text blocks, `"limit": 5` for repeating items

- **Preset Structure**: Presets should demonstrate typical usage patterns
  - Include representative blocks showing feature variety
  - Use realistic default values

### Mandatory Settings Rules for New Sections/Blocks

When creating new sections or blocks, always include these companion settings:

**Text Content Settings**:
When adding any text/heading setting, ALWAYS include these companion settings:

- **Text size**: Select dropdown with options `paragraph`, `h1`, `h2`, `h3`, `h4`, `h5`, `h6`
- **Text alignment**: Select with `left`, `center`, `right` options

Example schema pattern:

```json
{
  "type": "text",
  "id": "heading",
  "label": "t:settings.heading"
},
{
  "type": "select",
  "id": "heading_size",
  "label": "t:content.heading_size",
  "options": [
    { "value": "paragraph", "label": "t:options.paragraph" },
    { "value": "h1", "label": "t:options.h1" },
    { "value": "h2", "label": "t:options.h2" },
    { "value": "h3", "label": "t:options.h3" },
    { "value": "h4", "label": "t:options.h4" },
    { "value": "h5", "label": "t:options.h5" },
    { "value": "h6", "label": "t:options.h6" }
  ],
  "default": "h2"
},
{
  "type": "range",
  "id": "text_max_width",
  "label": "t:settings.text_max_width",
  "min": 200,
  "max": 1200,
  "step": 20,
  "unit": "px",
  "default": 800
},
{
  "type": "select",
  "id": "text_alignment",
  "label": "t:settings.alignment",
  "options": [
    { "value": "left", "label": "t:options.left" },
    { "value": "center", "label": "t:options.center" },
    { "value": "right", "label": "t:options.right" }
  ],
  "default": "center"
}
```

**Button/CTA Settings**:
When adding any button or CTA setting, ALWAYS include a style setting:

- **Button style**: Select with `primary` and `secondary` options
- Use `button` class for primary, `button-secondary` for secondary (matches theme defaults)

Example schema pattern:

```json
{
  "type": "text",
  "id": "cta_text",
  "label": "t:settings.cta_text"
},
{
  "type": "url",
  "id": "cta_link",
  "label": "t:settings.cta_link"
},
{
  "type": "select",
  "id": "cta_style",
  "label": "t:settings.style",
  "options": [
    { "value": "button", "label": "t:options.primary" },
    { "value": "button-secondary", "label": "t:options.secondary" }
  ],
  "default": "button"
}
```

**Section vs Block Level Settings**:
Some settings like `text_max_width` can legitimately exist at BOTH section and block levels when they control different content areas:

- Section-level `text_max_width`: Controls section header content (heading, description, CTA)
- Block-level `text_max_width`: Controls individual block content (typically smaller range)

This is an exception to the "layout settings only at parent level" rule when different content areas need independent control.

**Snippets** (`snippets/*.liquid`):

- Small, reusable components meant to be rendered within sections/templates
- Accept parameters passed from the render tag
- Examples: `button.liquid`, `product-card.liquid`, `price.liquid`

**Templates**:

- JSON templates (`templates/*.json`) define section composition - edit via theme editor or JSON structure
- Liquid templates (`templates/gift_card.liquid`) are traditional full-page templates

### Liquid Gotchas

**Nested Filters in Filter Parameters**:
Liquid CANNOT parse nested filters inside filter parameters. This is a common source of bugs.

❌ **BROKEN** - nested filters in parameter:

```liquid
{{ block.settings.image | image_url: width: 800 | image_tag: alt: block.settings.heading | strip_html | escape }}
```

✅ **CORRECT** - assign to variable first:

```liquid
{%- assign image_alt = block.settings.heading | strip_html | escape -%}
{{ block.settings.image | image_url: width: 800 | image_tag: alt: image_alt }}
```

**Rule**: When a filter parameter needs to use another filter, ALWAYS assign to a variable first.

### Shopify Image Tag Best Practices

Always use Shopify's `image_tag` filter for responsive images with proper lazy loading:

**Basic Pattern**:

```liquid
{%- assign image_alt = block.settings.heading | default: 'Image' | strip_html | escape -%}
{{ block.settings.image | image_url: width: 800 | image_tag:
  loading: 'lazy',
  class: 'block__image',
  widths: '400, 600, 800, 1000, 1200',
  sizes: '(min-width: 750px) 40vw, 100vw',
  alt: image_alt
}}
```

**Key Parameters**:

- `loading: 'lazy'` - Lazy load images below the fold
- `widths` - Comma-separated list of image widths to generate
- `sizes` - Media query hints for browser to select appropriate size
- `alt` - Must be a variable (see Liquid Gotchas above)

**Common `sizes` Patterns**:

```liquid
sizes: '100vw'                                    {# Full-width images #}
sizes: '(min-width: 750px) 50vw, 100vw'          {# 2-column on desktop #}
sizes: '(min-width: 750px) 33vw, 100vw'          {# 3-column on desktop #}
sizes: '(min-width: 750px) 40vw, 100vw'          {# Offset 2-column #}
```

### When Working with JavaScript

- All JS files are in `assets/` as ES6 modules
- Components extend the base `Component` class from `component.js`
- Use `this.refs` to access elements with `ref` attributes
- Event listeners should be declarative where possible
- Critical JS (`critical.js`) is loaded with `blocking="render"`

### When Working with CSS

- `base.css` contains core styles and CSS custom properties
- Theme uses CSS variables extensively (e.g., `var(--color-foreground)`)
- Responsive design uses modern CSS (container queries, logical properties)
- Color schemes applied via CSS custom properties

**Responsive Breakpoints**:

- **Mobile**: `@media (max-width: 749px)`
- **Tablet**: `@media (min-width: 750px) and (max-width: 1100px)`
- **Desktop**: `@media (min-width: 1101px)` or no media query (desktop-first for grids)

For scroll rows that should appear on both mobile and tablet:

```css
@media (max-width: 1100px) {
  .container {
    display: flex;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
  }
}
```

**Theme Font Variables**:
The theme provides responsive typography through CSS custom properties:

- **Font size variables**: `--font-h1--size`, `--font-h2--size`, etc. include built-in responsive scaling
- **Font family/weight**: `--font-h1--family`, `--font-h1--weight`, `--font-h1--style`
- **Use these instead of hardcoded values** to get automatic mobile scaling:
  ```css
  .title {
    font-size: var(--font-h4--size, 1.5rem);
    font-family: var(--font-h4--family, var(--font-heading--family));
    font-weight: var(--font-h4--weight, 600);
  }
  ```
- **Avoid mobile overrides** for font sizes when using theme variables—they already scale responsively.

**Badge Styling with Theme Variables**:
When adding badges, use the theme's global badge settings for consistency:

```liquid
<span class="badge" style="
  --badge-border-radius: {{ settings.badge_corner_radius }}px;
  --badge-font-family: var(--font-{{ settings.badge_font_family }}--family);
  --badge-font-weight: var(--font-{{ settings.badge_font_family }}--weight);
  --badge-text-transform: {{ settings.badge_text_transform }};
">
```

Reference `snippets/product-card-badges.liquid` and `config/settings_schema.json` (search for "badge") for the theme's badge implementation patterns.

**Flexbox and Text Alignment**:
`text-align` on a flex container does NOT affect flex item alignment.

- For flex children, alignment is controlled by `justify-content` and `align-items`
- If you need text inside a flex child to be aligned, apply `text-align` directly to that child:
  ```css
  .card--inline .card__content {
    display: flex;
  }
  .card--inline .card__title {
    text-align: var(--text-alignment); /* Must be on the element itself */
  }
  ```
- Inline blocks often need different padding (no block padding, only inline padding):
  ```css
  .card--inline {
    padding-block: 0;
    padding-inline: 24px;
  }
  ```

**Hover State Conditional Classes**:
When implementing hover effects that swap content (e.g., hover images):

- **Add conditional classes** based on whether hover content exists:
  ```liquid
  <div class="image-wrapper{% if has_hover_image %} image-wrapper--has-hover{% endif %}">
  ```
- **Target hover effects only when the class is present**:
  ```css
  /* Only hide primary when hover image exists */
  .card:hover .image-wrapper--has-hover .image--primary {
    opacity: 0;
  }
  ```
- This prevents unintended behavior when optional hover content is not provided.

**Responsive Element Sizing with `clamp()`**:
Use `clamp()` for elements that should scale with viewport but have min/max bounds:

```css
.image-wrapper {
  width: clamp(40px, 18vw, var(--image-size));
}
```

- First value: minimum size
- Second value: preferred size (viewport-relative)
- Third value: maximum size (often from a Liquid setting)

This ensures elements scale smoothly on resize while respecting user-configured maximums.

**CRITICAL: Section Grid System Architecture**

- **NEVER override `display: grid` on elements with the `.section` class**
  - The `.section` class uses a 3-column grid system for page-width constraints
  - Grid columns: `[margin] [content] [margin]`
  - `.section--page-width > *` places children in column 2 (constrained width)
  - `.section--full-width > *` places children in columns 1-3 (full width)
- **If you need flexbox or other layout**:
  - Apply it to the WRAPPER element (direct child of `.section`), not the section itself
  - Example: `.rotating-header-wrapper { display: flex; }` ✓
  - Example: `.rotating-header-section { display: flex; }` ✗ (breaks page-width constraint)
- **Before writing section CSS**:
  - Search for similar sections: `grep -l "section--page-width\|section--full-width" sections/*.liquid`
  - Examine their CSS to see how they structure containers vs wrappers
  - Preserve the grid system; add your layout to child elements

### When Working with Configuration

**`config/settings_schema.json`**:

- Defines all theme settings visible in the Shopify theme editor
- Organized into named groups (colors, typography, buttons, etc.)
- Changes here affect what merchants can customize

**`config/settings_data.json`**:

- Contains actual values for theme settings
- Modified when merchants change theme settings in the editor

## Pre-Completion Validation Checklist

Before considering any implementation complete, verify:

### Functionality

- [ ] Feature works as specified in all edge cases
- [ ] Tested with minimum and maximum block limits
- [ ] Responsive behavior verified on mobile/tablet/desktop
- [ ] Accessibility: Works with keyboard navigation and screen readers
- [ ] Respects `prefers-reduced-motion` for animations

### Code Quality

- [ ] No duplicated code - existing snippets/blocks reused where possible
- [ ] Follows existing theme patterns (examined 2-3 similar sections as reference)
- [ ] CSS variables used consistently with theme conventions
- [ ] JavaScript extends appropriate base class (`Component`, etc.)
- [ ] **CSS Architecture Verified**:
  - [ ] `.section` class retains `display: grid` (not overridden)
  - [ ] Custom layout (flex/grid) applied to wrapper elements, not section root
  - [ ] Page-width constraint tested: section content is constrained when `section_width: "page-width"` is selected
  - [ ] Full-width tested: section content spans edge-to-edge when `section_width: "full-width"` is selected

### Schema & Settings

- [ ] Parent-level settings control child blocks appropriately
- [ ] **CRITICAL**: Individual blocks do NOT have layout settings (alignment, spacing, width)
- [ ] Layout settings exist ONLY at parent section level, not in blocks
- [ ] Settings organized logically (Layout → Animation → Spacing → Colors)
- [ ] Block limits set appropriately
- [ ] `@theme` and `@app` blocks included if applicable
- [ ] Preset demonstrates typical usage

### Translations

- [ ] All `t:` references verified to exist in correct hierarchical location
- [ ] Keys added to all 20+ locale schema files
- [ ] Grepped locale files to confirm key existence before referencing
- [ ] Consistent naming with existing translation keys

### Integration

- [ ] Section appears correctly in theme editor
- [ ] All settings display with proper labels
- [ ] `shopify_attributes` included on blocks for editor integration
- [ ] Color scheme support works correctly

## Important Notes

### This is NOT a Development Environment

- No build process, package.json, or npm scripts
- Files are meant to be uploaded to Shopify via Theme Kit, CLI, or admin
- To work with this theme in development:
  - Use Shopify CLI: `shopify theme dev` (if set up as a proper theme directory)
  - Or use Shopify Theme Kit for legacy deployments
  - Or upload via Shopify admin (Themes → Add theme → Upload ZIP)

### Shopify Theme Development Commands

If this were configured as a Shopify theme development project:

```bash
# Start development server (requires Shopify CLI)
shopify theme dev

# Push theme to Shopify store
shopify theme push

# Pull latest theme from store
shopify theme pull

# Check for theme errors
shopify theme check
```

**Note**: These commands require Shopify CLI setup and store authentication, which this export doesn't include.

### Template Language

All `.liquid` files use **Liquid template language**:

- Variables: `{{ variable }}`
- Tags: `{% if condition %}...{% endif %}`
- Filters: `{{ product.price | money }}`
- Shopify-specific objects: `product`, `collection`, `cart`, `shop`, etc.

### Customization Workflow

Modifications should consider:

1. **Theme editor compatibility** - Settings in section schemas allow merchant customization
2. **Section Rendering API** - Sections can be dynamically reloaded
3. **Responsive design** - Mobile-first approach with breakpoints
4. **Accessibility** - ARIA labels, semantic HTML, keyboard navigation
5. **Performance** - Lazy loading, async scripts, optimized images

### Multi-language Support

When adding new text:

1. **Add translation keys to appropriate files**:
   - Runtime text: `locales/en.default.json`
   - Theme editor text: `locales/en.default.schema.json`

2. **Understand locale file structure**:
   - Schema files are hierarchical: `names`, `settings`, `info`, `content`, etc.
   - Reference keys with full path: `t:names.section_name` or `t:settings.setting_name`
   - **CRITICAL**: Verify the key exists in the referenced section, not just somewhere in the file

3. **Translation validation checklist**:
   - [ ] **CRITICAL: Search for existing usage patterns FIRST** before using any translation key
     - For settings: `grep -A 10 '"id": "setting_name"' sections/*.liquid` to see what keys other sections use
     - Example: For `section_width`, search existing sections to find they use `t:options.page` not `t:options.page_width`
   - [ ] Key exists in `locales/en.default.schema.json` in the correct hierarchical section
   - [ ] Key path in schema matches the actual location (e.g., `t:content.animation` requires "animation" key inside "content" object)
   - [ ] Grep for existing similar keys to maintain consistency: `grep -r "alignment" locales/en.default.schema.json`
   - [ ] When in doubt between two similar keys (e.g., `page` vs `page_width`), use Grep to see which one existing sections reference
   - [ ] Update all 20+ locale schema files (use English text for non-translated locales)

4. **Usage in Liquid**:
   - Runtime translations: `{{ 'key.path' | t }}`
   - Schema translations: `"name": "t:key.path"`

5. **Batch Locale Updates Workflow**:
   When adding new translation keys to all 20+ locale schema files, use this efficient bash pattern:

   ```bash
   # Navigate to locales directory first
   cd locales

   # Add a new key after an existing key in all schema files (except en.default)
   for file in *.schema.json; do
     if [ "$file" != "en.default.schema.json" ]; then
       if ! grep -q "new_key" "$file"; then
         sed -i '' '/"existing_key":/a\
       "new_key": "New value",
   ' "$file"
       fi
     fi
   done
   ```

   **Pattern explanation**:
   - Loops through all `.schema.json` files
   - Skips `en.default.schema.json` (edit that one manually first)
   - Checks if key already exists to avoid duplicates
   - Uses `sed` to insert new line after a reference key
   - Use English text for non-translated locales (matches theme convention)

   **Example - Adding `text_max_width` after `text_presets`**:

   ```bash
   for file in *.schema.json; do
     if [ "$file" != "en.default.schema.json" ]; then
       if ! grep -q "text_max_width" "$file"; then
         sed -i '' '/"text_presets":/a\
       "text_max_width": "Text max width",
   ' "$file"
       fi
     fi
   done
   ```
