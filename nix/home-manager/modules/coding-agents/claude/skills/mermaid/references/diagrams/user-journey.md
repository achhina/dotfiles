# User Journey

## When to Use

Use user journey diagrams for:
- Mapping user experience flows
- Identifying pain points and opportunities
- Documenting user interactions
- Service design documentation

## Example

```mermaid
%%{init: {'theme':'neutral'}}%%
journey
    title Online Shopping User Journey
    section Discovery
      Browse Products: 5: Customer
      View Product Details: 4: Customer
      Read Reviews: 4: Customer
    section Decision
      Add to Cart: 5: Customer
      Compare Options: 3: Customer
      Apply Coupon: 4: Customer
    section Purchase
      Enter Shipping Info: 3: Customer
      Select Payment Method: 4: Customer
      Complete Purchase: 5: Customer
    section Post-Purchase
      Receive Confirmation: 5: Customer, System
      Track Shipment: 4: Customer, System
      Receive Product: 5: Customer
      Leave Review: 3: Customer
```

## Key Conventions

- Use `section` to group journey stages
- Format: `Task Name: Score: Actor1, Actor2`
- Score ranges from 1-5 (1=very negative, 5=very positive)
- List actors involved in each step
- Order steps chronologically
- Include emotional highs and lows through scores
- Consider multiple actors (customer, system, support)
- Focus on key touchpoints in the experience
