# AI App UI Guidelines

## Direction

Coffee-Plus-App should feel like a modern premium cafe ordering app.

## Priorities

1. Clear product browsing
2. Fast add-to-cart
3. Strong cart visibility
4. Clear checkout summary
5. Clear wallet/Tangki balance display
6. Clean order status feedback
7. Good loading/error/empty states
8. Smooth micro-interactions
9. Reusable design tokens and components

## Rules

- Start with shared theme/tokens/components.
- Keep business logic out of widgets.
- Keep API behavior unchanged unless explicitly requested.
- Keep animations purposeful.

## Cafe Design Language

- Use the semantic palette as roles, not decoration:
  - ink `#18201d` for serious readable text.
  - brand `#136f54` for actions, active state, and confirmed interactive state.
  - accent `#b87e2d` for prices, money, and key numeric amounts.
  - bg `#f6f7f3`, surface `#fffffc`, and border `#dadfd8` for page depth.
- Cards and controls use 8px radius, thin borders, and no stacked decorative shadows.
- Do not use gradients, glassmorphism, large brown fills, floating decorative blobs, or oversized rounded cards.
- Titles/brand/recipe headers use the serif role.
- Prices, order numbers, ticket rows, and ledger values use the monospace role with tabular figures when possible.
- Customer UI maps to cafe objects:
  - Home/product browsing: menu board.
  - Product detail: recipe card.
  - Cart: receipt summary.
  - Order detail: pickup ticket.
  - Tangki: stored-value card and ledger.
  - Auth: restrained security entrance.
- Payment, Tangki, refund, and auth screens must not visually imply success before backend confirmation.
- The pickup-ticket perforation is the only allowed visual flourish; do not reuse it elsewhere.
