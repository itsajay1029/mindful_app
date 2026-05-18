# Design System Specification

## 1. Overview & Creative North Star: "The Tactile Playground"

This design system is built to transform the mundane into the momentous. Our Creative North Star is **The Tactile Playground**. Unlike traditional "flat" utility apps, this system treats the UI as a physical set of high-end, collectible objects. It rejects the sterility of modern minimalism in favor of "Soft Maximalism"—where every interaction feels "squishy," every progress bar feels like a liquid-filled vessel, and every screen transition feels like a physical page turn in a premium storybook.

We break the "template" look by utilizing intentional asymmetry in our illustrative assets and "The Floating Grid," where components aren't just pinned to a line but appear to hover at different altitudes above the `surface`.

---

## 2. Colors: Tonal Depth & The Gamification Spectrum

Our palette uses high-chroma greens and golds to drive dopamine, balanced by a sophisticated neutral foundation.

### The Palette (Material Design Mapping)
- **Primary (`#2B664A`):** The Emerald Anchor. Used for key brand moments and success states.
- **Secondary (`#745700`):** The Achievement Gold. Reserved for streaks, rewards, and high-value milestones.
- **Tertiary (`#874E00`):** The Energy Orange. Used for urgent gamification elements like XP multipliers or "on-fire" streaks.
- **Background (`#F5F6FA`):** A soft, airy off-white that prevents eye fatigue while making vibrant colors pop.

### The "No-Line" Rule
To maintain a premium, editorial feel, **1px solid borders for sectioning are strictly prohibited.** Do not use lines to separate content. Instead, define boundaries through:
- **Background Shifts:** Place a `surface-container-low` card against a `surface` background.
- **Negative Space:** Use our generous spacing scale to let elements breathe.
- **Elevation:** Use the "squishy" shadow technique to define the edge of a component.

### The "Glass & Gradient" Rule
Standard flat colors feel "out-of-the-box." To elevate the experience, use **Signature Textures**:
- **Hero CTAs:** Apply a subtle linear gradient from `primary` to `primary-container` at a 15-degree angle.
- **Floating HUDs:** For top bars or navigation, use a Glassmorphism effect: `surface-container-low` at 80% opacity with a `24px` backdrop-blur.

---

## 3. Typography: Plus Jakarta Sans

We utilize **Plus Jakarta Sans** for its unique balance of geometric precision and organic warmth. Its open counters and modern "ink traps" make it legible even at small sizes while remaining incredibly friendly.

- **Display (L/M/S):** Heavy weights (700-800). Use for "Big Win" moments. 
- **Headline & Title:** Use for page headers. The `headline-lg` (2rem) is the cornerstone of our editorial layout.
- **Body:** Always use `body-lg` (1rem) for lesson content to ensure high readability.
- **Label:** Reserved for metadata. Use `label-md` (0.75rem) in all-caps with +5% letter spacing for a "badge" aesthetic.

**Hierarchy Tip:** Pair a `display-sm` headline with a `body-md` description to create a high-contrast, professional "editorial" look that avoids the "wall of text" trap.

---

## 4. Elevation & Depth: Tonal Layering

We move beyond traditional drop shadows. Depth in this system is achieved through **The Layering Principle**.

### Surface Hierarchy
- **Level 0 (Base):** `surface` (#F5F6FA)
- **Level 1 (Sections):** `surface-container-low`
- **Level 2 (Cards/Interactives):** `surface-container-lowest` (Pure White)

### The "Squishy" Shadow
When a component is interactive (like a card or button), use an **Ambient Shadow**:
- **Color:** A 10% opacity version of the component's own color (e.g., a green button gets a green-tinted shadow).
- **Blur:** `32px` to `48px` for a soft, "cloud" lift.
- **Offset:** Always downward (Y-axis), never centered.

### The "Ghost Border" Fallback
If contrast is required for accessibility on a card, use a **Ghost Border**: `outline-variant` at 15% opacity. This provides a structural hint without cluttering the UI with hard lines.

---

## 5. Components: The Physical UI

### Buttons (The "Tactile" Core)
- **Primary:** `primary` fill with a `4px` bottom-inset border of `on_primary_fixed_variant` to create a 3D "pressable" look. Radius: `xl` (3rem).
- **Interaction:** On tap, the button should shift `2px` downward, simulating a physical click.
- **Secondary:** `surface-container-highest` background with `on_surface` text.

### Cards & Lists
- **Rule:** Forbid the use of divider lines.
- **Layout:** Use `surface-container-lowest` for the card body. Use `24px` padding and `md` (1.5rem) or `lg` (2rem) corner radius.
- **Spacing:** Separate list items using `16px` of vertical white space from the Spacing Scale.

### Gamification Assets (The "Sticker" Look)
- **XP Pills:** High-gloss containers using `tertiary_container`. 
- **Progress Rings:** Use `primary` for the fill and `primary_container` for the empty track. Ensure the ends of the stroke are `round`.
- **Badges:** Treat badges as floating assets with a slight 5-degree rotation to break the rigid grid and feel more "tossed" onto the page like real stickers.

### Inputs
- **Field Styling:** Thick `2px` Ghost Borders. When focused, the border transitions to `primary` and the background shifts to `surface-lowest`.

---

## 6. Do's and Don'ts

### Do
- **DO** use generous padding (min 24px) around all core content blocks.
- **DO** use "squishy" physics in animations—overshoot the scale slightly before settling.
- **DO** overlap elements (e.g., an icon peaking out of the top-right corner of a card) to create depth.

### Don't
- **DON'T** use pure black (#000000) for shadows or text; use `on_surface` or `on_surface_variant`.
- **DON'T** use sharp corners. Everything in this world is soft to the touch.
- **DON'T** use "Standard" Material Design dividers. If you feel the need for a line, increase your white space instead.
- **DON'T** use 100% opaque borders. Keep them "Ghostly" or non-existent.

---