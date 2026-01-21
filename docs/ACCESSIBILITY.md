# Accessibility Documentation

## WCAG Compliance Level

Salongroei targets **WCAG 2.1 Level AA** compliance to ensure the website is accessible to all users, including those using assistive technologies.

## Accessibility Features

### 1. Keyboard Navigation

All interactive elements are accessible via keyboard:

- **Tab Navigation**: All links, buttons, and form inputs can be accessed using the Tab key
- **Skip to Main Content**: A skip link at the top allows keyboard users to bypass navigation
- **Focus Indicators**: Visible focus outlines on all interactive elements
- **Logical Tab Order**: Tab order follows the visual layout of the page

#### Keyboard Shortcuts

- `Tab`: Move forward through interactive elements
- `Shift + Tab`: Move backward through interactive elements
- `Enter/Space`: Activate buttons and links
- `Escape`: Close modals and dropdowns (when implemented)

### 2. Screen Reader Support

The website is optimized for screen readers:

- **Semantic HTML**: Proper use of `<header>`, `<nav>`, `<main>`, `<article>`, `<section>`, `<footer>`
- **ARIA Labels**: Descriptive labels on navigation, interactive elements, and sections
- **ARIA Landmarks**: Main content areas are properly labeled
- **Alt Text**: Images have appropriate alternative text or are marked decorative
- **Screen Reader Only Text**: Hidden text provides context for icon-only buttons

### 3. Visual Design

#### Color Contrast

All text meets WCAG AA contrast ratios:

- **Normal Text**: Minimum 4.5:1 contrast ratio
- **Large Text**: Minimum 3:1 contrast ratio
- **Expert Navy (#1E3A5F) on Background Cream (#FFF8F0)**: ✓ Passes AA
- **Primary (#ff8370) on white**: May need darker text overlay for small text

#### Focus States

All interactive elements have visible focus indicators:

- **Links**: `focus:outline-2 focus:outline-primary focus:outline-offset-2`
- **Buttons**: `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2`
- **Form Inputs**: `focus:border-primary focus:ring-2 focus:ring-primary/50`

### 4. Content Structure

#### Heading Hierarchy

Each page follows proper heading structure:

- **One `<h1>` per page**: Page title
- **No skipped levels**: Headings follow h1 → h2 → h3 order
- **Descriptive headings**: Clear and meaningful heading text

Example:
```
h1: Expert Blog
  h2: Featured Articles
  h2: Alle Artikelen
```

### 5. Forms

All forms include proper accessibility features:

- **Labels**: All inputs have associated `<label>` elements
- **Required Fields**: Marked with `aria-required="true"`
- **Error Messages**: Would use `aria-describedby` for validation errors
- **Input Types**: Correct semantic types (`email`, `search`, etc.)

### 6. Images

Images follow accessibility best practices:

- **Decorative Images**: Empty alt text (`alt=""`)
- **Informative Images**: Descriptive alt text
- **Icons**: Marked with `aria-hidden="true"` when decorative
- **Functional Images**: Descriptive labels on parent elements

### 7. Navigation

#### Main Navigation

- `<nav>` element with `aria-label="Main navigation"`
- Active page indicated with `aria-current="page"`
- Keyboard accessible with visible focus states

#### Language Switcher

- `<nav>` element with `aria-label="Language selection"`
- Current language marked with `aria-current="true"`
- `hreflang` attributes for language links

### 8. Reduced Motion

Respects user preferences for reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Testing Procedures

### Automated Testing

1. **Browser DevTools**
   - Chrome Lighthouse Accessibility Audit
   - Firefox Accessibility Inspector
   - WAVE Browser Extension

2. **Keyboard Navigation**
   - Tab through entire page
   - Verify all interactive elements are reachable
   - Check focus visibility on all elements

3. **Screen Reader Testing**
   - **macOS**: VoiceOver (Cmd + F5)
   - **Windows**: NVDA (free) or JAWS
   - **Mobile**: TalkBack (Android) or VoiceOver (iOS)

### Manual Testing Checklist

- [ ] All images have appropriate alt text
- [ ] Color contrast passes WCAG AA (4.5:1 for normal text)
- [ ] Keyboard navigation works on all pages
- [ ] Focus indicators are visible on all interactive elements
- [ ] Heading hierarchy is correct (one h1, no skipped levels)
- [ ] ARIA labels present on navigation and interactive elements
- [ ] Skip to content link works
- [ ] Forms have proper labels and validation
- [ ] No content relies solely on color
- [ ] Text can be resized to 200% without loss of functionality

## Known Issues

### Current Limitations

None at this time. All critical accessibility issues have been addressed.

### Planned Improvements

1. **High Contrast Mode**: Enhanced support for Windows High Contrast Mode
2. **Dark Mode**: Full dark mode implementation with proper contrast ratios
3. **Form Validation**: Enhanced error messaging with ARIA live regions
4. **Dynamic Content**: ARIA live regions for loading states and notifications

## Browser Support

Accessibility features are tested and supported in:

- Chrome/Edge (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Mobile browsers (iOS Safari, Chrome Android)

## Assistive Technology Support

Tested with:

- **Screen Readers**: VoiceOver, NVDA, JAWS
- **Keyboard Navigation**: Full keyboard support
- **Voice Control**: Compatible with voice navigation software
- **Screen Magnification**: Supports zoom up to 200%

## Reporting Accessibility Issues

If you encounter any accessibility barriers while using Salongroei, please report them:

1. **Email**: accessibility@salongroei.com (example)
2. **GitHub Issues**: Create an issue with the "accessibility" label
3. **Contact Form**: Use our contact form with "Accessibility Issue" in the subject

Please include:

- Description of the issue
- Page URL where the issue occurs
- Browser and version
- Assistive technology used (if applicable)
- Steps to reproduce the issue

## Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)

## Compliance Statement

Salongroei is committed to ensuring digital accessibility for people with disabilities. We are continually improving the user experience for everyone and applying the relevant accessibility standards.

Last Updated: January 16, 2026
