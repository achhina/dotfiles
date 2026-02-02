# Mindmap

## When to Use

Use mindmaps for:
- Brainstorming and idea organization
- Hierarchical concept mapping
- Knowledge structure visualization
- Topic breakdown and exploration

## Example

```mermaid
---
config:
  theme: default
---
mindmap
  root((Web Application Architecture))
    Frontend
      React Framework
        Components
        Hooks
        State Management
      UI/UX
        Responsive Design
        Accessibility
        Theme System
    Backend
      Node.js Server
        Express.js
        Middleware
        Error Handling
      Database
        PostgreSQL
        Redis Cache
        Migrations
      Authentication
        JWT Tokens
        OAuth 2.0
        Role-Based Access
    Infrastructure
      Cloud Provider
        AWS
        Load Balancing
        Auto-scaling
      CI/CD
        GitHub Actions
        Testing
        Deployment
      Monitoring
        Logging
        Metrics
        Alerts
```

## Key Conventions

- Start with `root((text))` for the central concept
- Use indentation to show hierarchy
- Keep each node concise (1-4 words)
- Organize related concepts under common parents
- Limit depth to 3-4 levels for readability
- Use consistent terminology
- Order siblings by importance or logical flow
