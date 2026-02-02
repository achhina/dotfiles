# Mermaid Configuration Reference

## Configuration Methods

Mermaid supports three hierarchical configuration levels:

1. **Default configuration** - Built-in base settings
2. **Site-wide configuration** - Set via `mermaid.initialize()` (applies to all diagrams)
3. **Diagram-level configuration** - Frontmatter or directives (overrides site settings)

**Priority Order:** Frontmatter > Site config > Default config

## YAML Frontmatter Configuration (Recommended)

Use YAML frontmatter at the top of diagrams to override configuration. This is the current standard method for diagram-specific settings (since v10.5.0).

**Syntax:**
```
---
config:
  key: value
  nested:
    key: value
---
```

**Basic Example:**
```mermaid
---
config:
  theme: dark
  logLevel: info
---
flowchart TD
    A-->B
```

**With Diagram-Specific Config:**
```mermaid
---
config:
  theme: neutral
  sequence:
    mirrorActors: true
---
sequenceDiagram
    Alice->>Bob: Hello
```

**With Theme Variables:**
```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#ff0000'
---
flowchart TD
    A-->B
```

## Site-Wide Configuration

Use `mermaid.initialize()` to set defaults for all diagrams. Called once during setup.

**Example:**
```javascript
import mermaid from 'mermaid';

mermaid.initialize({
  startOnLoad: true,
  theme: 'default',
  logLevel: 'info',
  securityLevel: 'loose',
  flowchart: {
    useMaxWidth: true,
    htmlLabels: true
  }
});
```

## Key Configuration Options

### General Settings

- **theme** - `'default'`, `'neutral'`, `'dark'`, `'forest'`, `'base'`
- **fontFamily** - CSS font family string
- **logLevel** - `'fatal'`, `'error'`, `'warn'`, `'info'`, `'debug'`, `'trace'`
- **securityLevel** - `'strict'`, `'loose'`, `'antiscript'`, `'sandbox'`
- **startOnLoad** - `true` or `false` (auto-render on page load)

### Diagram-Specific Settings

Each diagram type supports specific configuration under its key:

**Flowchart:**
```javascript
{
  flowchart: {
    useMaxWidth: true,
    htmlLabels: true,
    curve: 'basis',
    diagramPadding: 8
  }
}
```

**Sequence:**
```javascript
{
  sequence: {
    mirrorActors: true,
    showSequenceNumbers: false,
    actorMargin: 50,
    boxMargin: 10,
    messageMargin: 35
  }
}
```

**Gantt:**
```javascript
{
  gantt: {
    titleTopMargin: 25,
    barHeight: 20,
    barGap: 4,
    numberSectionStyles: 4
  }
}
```

## Directives (Deprecated)

**Important:** Directive syntax (`%%{init}%%`) is deprecated as of v10.5.0. Use YAML frontmatter with the `config` key instead.

**Deprecated directive syntax (still works but avoid):**
```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TD
    A-->B
```

**Current YAML frontmatter syntax (use this):**
```mermaid
---
config:
  theme: dark
---
flowchart TD
    A-->B
```

**Ancient directive syntax (removed, don't use):**
```
%%{initialize: {'theme': 'dark'}}%%
```

The YAML frontmatter method is preferred because it:
- Separates configuration from diagram content
- Provides clearer document structure
- Aligns with modern documentation practices
- Is more readable and maintainable

## Configuration Best Practices

### For Diagram Authors

**Always use YAML frontmatter** unless you're setting up site-wide defaults:

```mermaid
---
config:
  theme: neutral
---
flowchart TD
    Start-->End
```

### For Site Integrators

Use `initialize()` for site-wide defaults:

```javascript
mermaid.initialize({
  theme: 'default',
  startOnLoad: true,
  securityLevel: 'strict'
});
```

### Security Considerations

Secure configuration keys can only be set via `initialize()` and cannot be overridden by diagram authors:

- `secure`
- `securityLevel`
- `startOnLoad`
- `maxTextSize`

## Complete Configuration Schema

For the complete list of all available configuration options, see:
- [Mermaid Config Schema Documentation](https://mermaid.js.org/config/schema-docs/config.html)
- [Configuration Guide](https://mermaid.js.org/config/configuration.html)

## Icon Registration

Register custom icon packs to use in diagrams (available for architecture diagrams).

**Using CDN:**
```javascript
mermaid.registerIconPacks([
  {
    name: 'logos',
    loader: () =>
      fetch('https://unpkg.com/@iconify-json/logos@1/icons.json')
        .then((res) => res.json()),
  },
]);
```

**Using npm package (with lazy loading):**
```javascript
import mermaid from 'mermaid';

mermaid.registerIconPacks([
  {
    name: 'logos',
    loader: () =>
      import('@iconify-json/logos').then((module) => module.icons),
  },
]);
```

**Direct import:**
```javascript
import { icons } from '@iconify-json/logos';

mermaid.registerIconPacks([
  {
    name: icons.prefix,
    icons,
  },
]);
```

**Using icons in diagrams:**
```mermaid
architecture-beta
    service api[API Server] (logos:nodejs)
    service db[Database] (logos:postgresql)
```

Icon packs are sourced from [icones.js.org](https://icones.js.org/) with over 200,000+ available icons.
