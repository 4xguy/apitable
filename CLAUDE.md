# APITable Development Guide

## Build Commands
- Build all: `pnpm build` or `make build`
- Backend: `./gradlew build -x test` (Java) or `pnpm build:room-server` (Node)
- Frontend: `pnpm build:datasheet` or `pnpm build:web`

## Test Commands
- Run all tests: `pnpm test` or `make test`
- Run single test: `pnpm jest <test-file-path>` or `./gradlew test --tests <TestClassName>`
- Core tests: `pnpm test:core` (with coverage: `pnpm test:core:cov`)
- E2E tests: `pnpm cy:run` (headless) or `pnpm cy:open` (with UI)

## Lint Commands
- Check all: `pnpm lint` (fix: `pnpm lint:fix`)
- Format: `pnpm prettier:fix` (check: `pnpm prettier:check`)

## Code Style Guidelines
- TypeScript: Use strict typing, avoid `any` types, follow ESLint rules
- Java: Follow Google Java Style Guide with 4-space indentation
- Naming: camelCase for variables/methods, PascalCase for classes/interfaces
- Imports: Group by type (React, 3rd party, internal), sort alphabetically
- Formatting: 2-space indent (TS), 150 char line limit, single quotes
- Error handling: Use appropriate try/catch, avoid throwing in React components