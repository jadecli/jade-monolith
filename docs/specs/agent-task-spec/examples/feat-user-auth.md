---
id: feat-user-auth
type: feat
subject: Add user authentication with OAuth2 and JWT
status: in_progress
owner: implementer
scope: auth
breaking: false
branch: feat/user-auth
assignableTo:
  - implementer
  - auth-dev
testFirst: true
criteria:
  - All tests pass
  - ruff check clean
  - OAuth2 flow works end-to-end
relatedIssues:
  - 12
  - 15
metadata:
  priority: high
  sprintId: 3
---

## Context

Implement user authentication using OAuth2 authorization code flow with JWT
access tokens and refresh tokens. The auth module should support multiple
identity providers (Google, GitHub) and maintain a local user profile.

## Acceptance Criteria

- [ ] OAuth2 authorization code flow with PKCE
- [ ] JWT access token generation and validation
- [ ] Refresh token rotation
- [ ] User profile creation on first login
- [ ] Session management with secure httpOnly cookies

## Implementation Notes

Use the existing `auth-dev` agent for OAuth integration and `implementer`
for the core JWT logic. The `test-writer` should create integration tests
before implementation begins (testFirst: true).
