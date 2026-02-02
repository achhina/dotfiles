# Gantt Chart

## When to Use

Use Gantt charts for:
- Project schedules and timelines
- Task dependencies and sequencing
- Resource planning
- Sprint planning

## Example

```mermaid
---
config:
  theme: dark
---
gantt
    title Web Application Development
    dateFormat YYYY-MM-DD
    section Planning
    Requirements Gathering    :done, req, 2024-01-01, 2024-01-14
    Architecture Design       :done, arch, 2024-01-08, 2024-01-21

    section Backend
    Database Schema          :done, db, 2024-01-15, 2024-01-28
    API Development          :active, api, 2024-01-22, 2024-02-18
    Authentication           :crit, auth, 2024-02-01, 2024-02-15

    section Frontend
    UI Components            :ui, 2024-02-05, 2024-02-25
    Integration              :crit, int, 2024-02-19, 2024-03-10

    section Testing
    Unit Testing             :test, 2024-02-12, 2024-03-03
    Integration Testing      :crit, inttest, 2024-03-04, 2024-03-17

    section Deployment
    Staging Deploy           :deploy, 2024-03-11, 2024-03-15
    Production Deploy        :crit, prod, 2024-03-18, 2024-03-22
```

## Key Conventions

- Set `dateFormat` to match your date strings
- Use sections to group related tasks
- Mark critical path tasks with `:crit`
- Show completed tasks with `:done`
- Show current work with `:active`
- Include task IDs for dependency tracking
- Use clear, action-oriented task names
- Show dependencies between tasks when relevant
