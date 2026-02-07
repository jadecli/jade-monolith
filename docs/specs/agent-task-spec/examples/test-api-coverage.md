---
id: test-api-coverage
type: test
subject: Add API integration test coverage
status: pending
blockedBy:
  - feat-user-auth
assignableTo:
  - test-writer
  - integration-tester
criteria:
  - Coverage above 80%
  - All edge cases documented
---

## Context

The API endpoints for user authentication lack integration test coverage.
This task adds tests for the OAuth2 flow, token refresh, and error cases.

## Test Plan

- [ ] Test OAuth2 authorization code exchange
- [ ] Test JWT validation with expired tokens
- [ ] Test refresh token rotation
- [ ] Test concurrent session handling
- [ ] Test invalid provider rejection
