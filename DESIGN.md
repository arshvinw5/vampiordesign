# Vampior Auth — DESIGN.md

Design spec for the onboarding, login, registration and password-reset flow. Prototype: `Auth Flow v3.dc.html`. Target: Flutter mobile app.

---

## 1. Colour

| Token | Hex | Use |
|---|---|---|
| `navy` | #023E8A | Primary buttons, headings, active states, brand mark |
| `blue` | #0096C7 | Hover / pressed tint, focus ring, valid check, counters |
| `sky` | #48CAE4 | Valid input border, onboarding art |
| `pale` | #ADE8F4 | Idle input border, dividers, inactive progress |
| `ice` | #CAF0F8 | App background, onboarding art |
| `ink` | #0B1D33 | Body text (100%) |
| `ink-80` | rgba(11,29,51,.80) | Body copy |
| `ink-64` | rgba(11,29,51,.64) | Secondary text, hints |
| `ink-40` | rgba(11,29,51,.40) | Placeholders, idle icons |
| `error` | #C62828 | Error border, icon, message |
| `surface` | #FFFFFF | Screens, inputs |

60 / 30 / 10: white surface, ink text, navy accent. Navy is reserved for the primary action and headings.

## 2. Typography

Family: **Archivo**. Two weights only: **400** and **700**.

| Role | Size / line-height | Weight |
|---|---|---|
| Title | 28 / 1.15 | 700 |
| Body, input, button | 16 / 1.5 | 400 · buttons 700 |
| Label, link, secondary | 14 | 700 / 400 |
| Meta, hint, error, counter | 12 / 16 | 400 · counter 700, +0.08em tracking |

Inputs are always 16px (prevents iOS zoom).

## 3. Spacing & shape

- 8-point grid: 4, 8, 16, 24, 32, 48, 64.
- Screen side padding 24. App bar height 64.
- Radius: **8** on inputs and buttons; 0 elsewhere.
- Borders: 2px. Inputs use `pale` idle, `sky` valid, `blue` focus, `error` invalid.
- Minimum tap target 44×44.
- Shadows (tinted to navy): device `0 24 48 rgba(2,62,138,.12)`; primary button `0 8 24 rgba(2,62,138,.20)` + inner top highlight `inset 0 1 0 rgba(255,255,255,.18)`.

## 4. Motion

| Token | Value |
|---|---|
| `ease-out` | cubic-bezier(.23, 1, .32, 1) — entrances, presses, label swaps |
| `ease-in-out` | cubic-bezier(.77, 0, .175, 1) — on-screen movement (shake) |
| `ease-drawer` | cubic-bezier(.32, .72, 0, 1) — onboarding track settle |

| Interaction | Spec |
|---|---|
| Button press | scale 0.97, 160ms ease-out |
| Screen change | fade + translateX 24px (forward from right, back from left), 260ms ease-out |
| Invalid submit | fields shake −6 / 5 / −3px, 280ms ease-in-out; focus first invalid field |
| Valid check icon | scale 0.9→1 + fade, 200ms ease-out |
| Colour / border changes | 150–200ms ease |
| Success badge | scale 0.8→1.06→1, 420ms ease-out; ring pulse ×2; summary rows rise 8px, 60ms stagger |

Reduced motion: movement and blur removed; opacity fades kept; spinner keeps turning.
Never animate from scale(0). Animate transform and opacity only.

## 5. Components

### PrimaryButton
- Height 56 (48 on onboarding), radius 8, navy fill, white 16/700 label, flush-left label with trailing arrow.
- Hover `blue`, pressed `#012A5E` + scale 0.97.
- **Loading crossfade** — two labels stacked in the same cell; button never resizes.

  | | Idle label | Busy label |
  |---|---|---|
  | Opacity | 1 → 0 | 0 → 1 |
  | Blur | 0 → 2px | 2px → 0 |
  | Position | moves up 6px | rises 6px into place |

  200ms `ease-out`. Spinner: 18px ring, 2px stroke, track white 35%, head solid white, 600ms linear per turn.
  While loading: form above dims to 55% and ignores taps; repeat taps ignored; busy label announced (`aria-live` / `Semantics(liveRegion: true)`).

### SecondaryButton
- Height 56, radius 8, 2px navy border, navy 5% fill, navy label. Hover `ice`.

### TextButton / link
- 14/700 navy, no underline box, min 44 tall. Hover `blue`.

### TextField
- Label 14/700 above; field 48 tall, radius 8, 2px border, 16px text.
- Leading 20px Lucide icon (mail, user, phone, lock) coloured by state.
- Trailing: eye / eye-off toggle on passwords (44×44); check icon when valid.
- Message row 12px under field, always reserved (no layout jump): error › Caps Lock warning › hint.
- Focus: `blue` border + 4px `sky` 25% ring.
- Keyboard: `next` between fields, `go` on the last; correct input types.

### PhoneField (+94)
- Fixed non-editable `+94` prefix (16/700 navy, right divider).
- Stores 9 digits; strips leading 0 or pasted 94; displays `77 123 4567`.

### PasswordStrength
- 4 segments, 4px tall. Score: length ≥ 8, mixed case, digit, symbol. Weak/Fair/Good/Strong in error/sky/blue/navy.

### Onboarding pager
- Full-bleed slides (no card chrome): 3×3 colour-block art, counter, title, body.
- Drag follows the finger; commits on > 25% width **or** velocity > 0.11 px/ms; rubber-band ×0.35 at ends; settles 300ms `ease-drawer`.
- Progress: three 24×4 segments, tappable. Back (48, outlined) + Next / Get started (primary).

## 6. Screens & flow

```
Onboarding (3) ──Skip / Get started──▶ Login ──▶ Success
                                        │  ├──Forgot password?──▶ Reset ──(link sent, resend 30s)
                                        │  └──Create one──▶ Register ──▶ Success
Success ──Log out──▶ Login   ·   Replay onboarding──▶ Onboarding
```

Layout for form screens: fixed app bar (back + brand) · scrollable content (title block, fields) · CTA bar pinned in the thumb zone with safe-area padding.

## 7. Validation rules

| Field | Rule | Message |
|---|---|---|
| Email or mobile | required; valid email or 9–15 digits | Enter a valid email or mobile number |
| Password (login) | required; ≥ 6 chars | Password must be at least 6 characters |
| Full name | required; letters; first + last | Enter first and last name |
| Email | required; valid format | Enter a valid email address |
| Mobile (+94) | 9 digits starting with 7 | Enter a 9-digit number starting with 7 |
| Password | ≥ 8; letters + number | Use letters and at least one number |
| Confirm password | matches password | Passwords do not match |

Errors show on blur (when filled) or on submit, then update live.

## 8. Flutter mapping

| Spec | Flutter |
|---|---|
| Colours / type | `ThemeData` with `ColorScheme(primary: navy …)`, `GoogleFonts.archivo` |
| Onboarding pager | `PageView` + custom `ScrollPhysics` (or `PageController.animateToPage` with `Cubic(.32,.72,0,1)`) |
| Form screens | `Scaffold` → `SingleChildScrollView` body + `bottomNavigationBar`-slot CTA in `SafeArea` |
| PrimaryButton loading | `Stack` of two `AnimatedOpacity` + `AnimatedSlide`, each in `ImageFiltered(ImageFilter.blur)`, 200ms `Cubic(.23,1,.32,1)` |
| Press feedback | `AnimatedScale(scale: pressed ? .97 : 1, duration: 160ms)` |
| Shake | `AnimationController` 280ms + `TweenSequence` on `Transform.translate` |
| PhoneField | `TextField(prefix: Text('+94'))` + `FilteringTextInputFormatter.digitsOnly` + custom formatter |
| Validation | `Form` + `TextFormField.validator`, `AutovalidateMode.onUserInteraction` |
| Remember me | `shared_preferences` |
| Reduced motion | `MediaQuery.of(context).disableAnimations` |
| Navigation | `go_router` (back stack mirrors flow above) |
