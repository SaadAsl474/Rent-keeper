---
name: RentKeeper Operational Precision
colors:
  surface: '#f9f9ff'
  surface-dim: '#d1daf4'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8ff'
  surface-container-highest: '#d9e2fc'
  on-surface: '#121b2e'
  on-surface-variant: '#44474e'
  inverse-surface: '#273044'
  inverse-on-surface: '#edf0ff'
  outline: '#74777e'
  outline-variant: '#c4c6ce'
  surface-tint: '#4a5f81'
  primary: '#001632'
  on-primary: '#ffffff'
  primary-container: '#142b4a'
  on-primary-container: '#7d93b7'
  inverse-primary: '#b2c7ee'
  secondary: '#006b5f'
  on-secondary: '#ffffff'
  secondary-container: '#6df5e1'
  on-secondary-container: '#006f64'
  tertiary: '#231300'
  on-tertiary: '#ffffff'
  tertiary-container: '#3f2500'
  on-tertiary-container: '#cb8200'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#b2c7ee'
  on-primary-fixed: '#021c3a'
  on-primary-fixed-variant: '#324768'
  secondary-fixed: '#71f8e4'
  secondary-fixed-dim: '#4fdbc8'
  on-secondary-fixed: '#00201c'
  on-secondary-fixed-variant: '#005048'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f9f9ff'
  on-background: '#121b2e'
  surface-variant: '#d9e2fc'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: 0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1rem
  margin-tablet: 1.5rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system is engineered for local commercial rental enterprises managing mission-critical inventory—such as studio cameras, commercial diesel generators, wedding banquet infrastructure, industrial PA systems, and heavy power equipment—across diverse physical and network environments. 

The aesthetic is anchored in **Modern Enterprise Utility with Material 3 Tactility**. The interface communicates reliability, fiscal discipline, and speed. Designed primarily for Flutter-based mobile and handheld Android terminal workflows, the system minimizes cognitive load under intense retail counters and noisy warehouse environments. 

### Core Tenets
- **Offline Certainty:** Visual patterns communicate local state, pending sync queues, and database integrity without alarming the operator.
- **Transactional Density:** High scannability of inventory status, Pakistani Rupee (Rs.) figures, customer phone numbers, and return timestamps.
- **Physical Feedback:** Clear visual active states and high-contrast boundaries to compensate for varying ambient lighting conditions.

## Colors

The palette balances authoritative structure with precise operational indicators. 

### Application Rules
- **Primary (`#142B4A`):** Anchors core chrome, AppBars, primary action buttons, and dominant headers. Conveys structural permanence and security.
- **Primary Hover/Focus (`#1E3A5F`):** Applied to active navigation rail items, pressed touch targets, and secondary deep surfaces.
- **Secondary / Teal Accent (`#14B8A6`):** Signals forward-progress workflows, positive state transitions, primary FABs, and action cues. Paired with `#CCFBF1` for calm informational pill backdrops.
- **Operational Semantics:**
  - **Pending / In-Transit:** Amber (`#F59E0B`) with surface container `#FEF3C7`. Used for security deposits pending clearance or equipment booked but uncollected.
  - **Overdue / Alert:** Coral Red (`#EF4444`) with surface container `#FEE2E2`. Used strictly for defaulted returns, damaged inventory flags, and sync conflicts.
  - **Settled / Active:** Emerald Green (`#10B981`) with surface container `#D1FAE5`. Used for cleared payments, verified returns, and active inventory.
- **Base Canvas (`#F5F7FA`):** Cool light grey foundation preventing eye strain across prolonged counter shifts, distinct from elevated pure white surfaces (`#FFFFFF`).

## Typography

The typography uses Inter across all view hierarchy levels to ensure immediate character recognition, tabular numeral alignment, and low-latency rendering on mid-tier Android devices.

### Numerical & Financial Formatting
- Currency values must always explicitly state "Rs." followed by a non-breaking space (e.g., `Rs. 45,000`).
- All rental duration counters, unit quantities, and financial ledgers use standard tabular figure alignment (`font-feature-settings: 'tnum' on`).
- Serial numbers, IMEI records, and generator engine codes must employ medium weights (`600`) at `label-md` to avoid visual confusion between characters like `0` and `O`.

## Layout & Spacing

The layout model implements a structured responsive fluid grid designed around single-hand Android terminal interactions and tablet counter docks.

### Grid Breakpoints
- **Mobile (< 600dp):** 4-column layout, `margin`: `1rem` (16px), `gutter`: `1rem` (16px). All modal flows and rental agreements occupy full width. Bottom navigation handles top-level routing.
- **Tablet (600dp - 1024dp):** 8-column layout, `margin`: `1.5rem` (24px), `gutter`: `1.5rem` (24px). Primary split-view enabled: left list pane (40%) showing asset queue (e.g., Sony FX3, 50kVA Generator) and right detail pane (60%) displaying customer CNIC, booking dates, and payment history.
- **Desktop / POS Dock (> 1024dp):** 12-column fixed-max layout, `margin`: `2rem` (32px), centered canvas maximum 1280dp.

### Layout Principles
- Use vertical rhythm multiples of `0.25rem` (4px).
- Maintain minimum touch target heights of 48dp on all action triggers, even when typography renders at `label-sm`.

## Elevation & Depth

Visual hierarchy leverages crisp card boundaries paired with diffused ambient shadows, adhering to Material 3's surface layer conventions while preventing muddy displays on low-cost LCD screens.

### Elevation Hierarchy
- **Level 0 (Canvas Base):** `#F5F7FA` flat ground.
- **Level 1 (Card & Surface Default):** Pure White (`#FFFFFF`) with a dual shadow: `0px 1px 3px rgba(20, 43, 74, 0.05), 0px 4px 12px rgba(20, 43, 74, 0.03)`. Surfaces are reinforced with a hairline border (`1px solid #E2E8F0`) to ensure contrast against the canvas.
- **Level 2 (Active Sheets / Hovered Cards):** `#FFFFFF` with shadow: `0px 4px 16px rgba(20, 43, 74, 0.08), 0px 2px 4px rgba(20, 43, 74, 0.04)`.
- **Level 3 (Sticky Bottom Bars / Snackbars):** `#142B4A` (Dark Navy surface) with shadow: `0px 8px 24px rgba(20, 43, 74, 0.16)`.
- **Offline Banner Indicator:** Docked underneath the app bar with zero elevation, using `#1E3A5F` and `#CCFBF1` text, establishing systemic operational state without overlaying actionable surfaces.

## Shapes

The design system implements a **Rounded (Level 2)** geometry to balance modern Android aesthetics with structural utility.

### Geometry Assignments
- **Core Cards & Invoices:** `rounded-lg` (16px / 1rem) to frame equipment details cleanly.
- **Modals & Bottom Sheets:** `rounded-xl` (24px / 1.5rem) applied to top corners only for smooth gesture-driven dismissal.
- **Buttons, Form Inputs, & Search Fields:** `rounded` (8px / 0.5rem) to ensure clear input boundaries.
- **Status Badges & Quick Action Chips:** Pill-shaped (9999px) to distinctly segregate meta labels from actionable rectangular inputs.

## Components

### Buttons
- **Primary:** Dark Navy (`#142B4A`) background, `#FFFFFF` text, `title-md`, height 48px, `rounded` (8px). Pressed state shifts to `#1E3A5F`. Disabled state is `#94A3B8` with `#F1F5F9` text.
- **Secondary (Teal Action):** Background `#14B8A6`, text `#FFFFFF`. Used exclusively for forward-driving actions such as "Dispatch Gear" or "Print Challan".
- **Outlined:** 1px border `#CBD5E1`, transparent background, text `#142B4A`. Hover/focus reveals `#F1F5F9`.

### Chips & Status Badges
- **Status Pills:** Height 24px, padding horizontal 10px, typography `label-sm`.
  - *Active Rental:* Background `#D1FAE5`, text `#065F46`.
  - *Pending / Deposit Due:* Background `#FEF3C7`, text `#92400E`.
  - *Overdue / Damage Alert:* Background `#FEE2E2`, text `#991B1B`.
- **Filter Chips:** Height 32px, `rounded` (8px), border `1px solid #E2E8F0`, background `#FFFFFF`. Active filter switches to `#142B4A` background and `#FFFFFF` text.

### Cards
- **Equipment Inventory Card:** `#FFFFFF` background, `rounded-lg` (16px), 1px border `#E2E8F0`, padding 16px. Displays product category thumbnail (e.g., Shure Wireless Mic, 25kVA Soundproof Generator), stock available vs. rented (e.g., "3 of 5 Available"), daily rate (`Rs. 4,500/day`), and current tracking status.
- **Rental Order Summary Card:** Segmented structure with customer CNIC indicator, return countdown, and collateral holding badge.

### Input Fields
- Height 52px, background `#FFFFFF`, border `1px solid #CBD5E1`, `rounded` (8px), padding horizontal 16px, text `#172033`.
- Floating label or top-anchored label in `label-md` (`#64748B`).
- Focus state features a 2px ring in `#142B4A`. Error state shifts border to `#EF4444`.

### Lists
- Separated items with `#F1F5F9` divider lines, padding vertical 12px, padding horizontal 16px.
- Leading icon or avatar slot (40x40px, `rounded` 8px, `#F1F5F9` fill).
- Trailing section configured for monetary sums in `title-md` (`#172033`) stacked over timestamp labels in `body-sm` (`#64748B`).

### Checkboxes & Radios
- Checkbox dimensions: 20x20px, `rounded` (4px). Active fill `#142B4A` with pure white check mark.
- Radio buttons: 20x20px with `#142B4A` ring and `#142B4A` centered dot.

### Specialized Offline System Banner
- Sticky horizontal bar, height 36px, background `#1E3A5F`, icon: cloud-off indicator in `#14B8A6`, text: "Offline Mode — 14 Bookings Queued for Sync" in `label-md` (`#FFFFFF`).