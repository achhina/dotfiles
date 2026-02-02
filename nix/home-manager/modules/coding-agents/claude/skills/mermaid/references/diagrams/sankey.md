# Sankey Diagram

## When to Use

Use Sankey diagrams for:
- Flow quantities and value relationships
- Resource allocation visualization
- Traffic flow analysis
- Budget or energy distribution

## Example

```mermaid
---
config:
  theme: forest
  themeVariables:
    fontSize: '16px'
---
sankey-beta

Website Traffic,Direct,500
Website Traffic,Search,800
Website Traffic,Social,300
Website Traffic,Referral,200

Direct,Product Page,300
Direct,Blog,200
Search,Product Page,600
Search,Blog,200
Social,Product Page,100
Social,Blog,200
Referral,Product Page,150
Referral,Blog,50

Product Page,Purchase,400
Product Page,Bounce,750
Blog,Subscribe,200
Blog,Bounce,450
```

## Key Conventions

- Each line represents a flow: Source, Target, Value
- Width of flow is proportional to the value
- Organize flows left-to-right showing progression
- Use meaningful labels for sources and targets
- Values should be numeric and represent flow quantity
- Group related flows together in the definition
- Consider using for conversion funnels, resource flows, or traffic analysis
