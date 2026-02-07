---
id: fix-null-deref
type: fix
subject: Fix null pointer dereference in parser
status: completed
owner: debugger
scope: parser
---

## Context

The YAML parser crashes with a null pointer dereference when processing
empty frontmatter blocks. The root cause is that `yaml.safe_load` returns
`None` for empty YAML, which is not handled.

## Resolution

Added a type check after `yaml.safe_load` to raise `ParseError` when the
result is not a dict. Added regression test in `test_parser.py`.
