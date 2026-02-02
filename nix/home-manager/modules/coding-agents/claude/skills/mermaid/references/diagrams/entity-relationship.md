# Entity Relationship Diagram

## When to Use

Use entity relationship diagrams for:

- Database schema design
- Data model documentation
- Table relationships
- Cardinality mapping

## Example

```mermaid
---
config:
  theme: neutral
---
erDiagram
    USER ||--o{ ORDER : places
    USER {
        int id PK
        string email UK
        string name
        datetime created_at
    }

    ORDER ||--|{ ORDER_ITEM : contains
    ORDER {
        int id PK
        int user_id FK
        string status
        decimal total
        datetime created_at
    }

    PRODUCT ||--o{ ORDER_ITEM : "ordered in"
    PRODUCT {
        int id PK
        string name
        string sku UK
        decimal price
        int stock
    }

    ORDER_ITEM {
        int id PK
        int order_id FK
        int product_id FK
        int quantity
        decimal price
    }
```

## Key Conventions

- Use `||--o{` notation for relationship cardinality:
  - `||--||` one to one
  - `||--o{` one to zero or more
  - `||--|{` one to one or more
- Mark primary keys with `PK`
- Mark foreign keys with `FK`
- Mark unique constraints with `UK`
- Include data types for each field
- List important constraints and indexes
- Show relationship names on the connecting lines
