# State Diagram

## When to Use

Use state diagrams for:

- State machines and workflows
- Object lifecycle management
- System mode transitions
- Order/request status tracking

## Example

```mermaid
---
config:
  theme: dark
---
stateDiagram-v2
    [*] --> Draft
    Draft --> Submitted: Submit
    Submitted --> UnderReview: Assign Reviewer
    UnderReview --> Approved: Approve
    UnderReview --> ChangesRequested: Request Changes
    ChangesRequested --> Submitted: Resubmit
    Approved --> Published: Publish
    Published --> Archived: Archive
    Draft --> Cancelled: Cancel
    Submitted --> Cancelled: Cancel
    Archived --> [*]
    Cancelled --> [*]
```

## Key Conventions

- Start with `[*]` to indicate initial state
- End with `[*]` to indicate terminal states
- Label transitions with trigger events or actions
- Group related states visually when possible
- Show all valid state transitions
- Include error/cancellation paths
- Use descriptive state names (not just numbers/codes)
