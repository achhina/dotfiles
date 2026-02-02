# Architecture Diagram

## When to Use

Use architecture diagrams for:
- System component relationships
- High-level service topology
- Microservices architecture
- Infrastructure overview

## Example

```mermaid
---
config:
  theme: default
---
architecture-beta
    group cloud(cloud)[Cloud Infrastructure]

    service api(server)[API Gateway] in cloud
    service auth(server)[Auth Service] in cloud
    service user(server)[User Service] in cloud
    service order(server)[Order Service] in cloud

    service db(database)[Database] in cloud
    service cache(disk)[Cache] in cloud
    service queue(disk)[Message Queue] in cloud

    api:R --> L:auth
    api:R --> L:user
    api:R --> L:order

    auth:B --> T:db
    user:B --> T:db
    order:B --> T:db

    api:B --> T:cache
    order:R --> L:queue
```

## Key Conventions

- Use `group` to define logical boundaries (cloud, VPC, subnet)
- Use `service` with type icons: `server`, `database`, `disk`
- Define directional connections: `L` (left), `R` (right), `T` (top), `B` (bottom)
- Group related services within the same boundary
- Show data stores separately from compute services
- Label groups with infrastructure context
- Keep layout clean by minimizing crossing lines
