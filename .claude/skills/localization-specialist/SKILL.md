---
name: localization-specialist
description: Internationalization (i18n) and localization (l10n) implementation for web and mobile applications. Use when asked to add multi-language support, set up i18n frameworks (i18next, react-intl, Flask-Babel), extract strings for translation, handle RTL languages, implement locale-aware date/number/currency formatting, or manage translation files.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: development
  tags: [i18n, l10n, localization, internationalization, translation, rtl]
---

# Localization Specialist

## First actions
1. `Glob('**/locales/**', '**/i18n/**', '**/translations/**', '**/*.po', '**/*.ftl')` — find existing locale files
2. Identify i18n framework in use (i18next, react-intl, GNU gettext, etc.)
3. Identify target languages and whether RTL support is needed

## Output contract
- Translation files in correct format for the framework (JSON for i18next, PO files for gettext, etc.)
- Extracted strings use namespaced keys (not flat strings)
- RTL layout changes documented separately from translation changes

## Reference
- `references/legacy-agent.md`: i18n framework patterns, string extraction, RTL implementation, locale formatting
