---
"skill-steward": patch
---

Tighten install/update trust boundaries by validating skill sources more strictly, requiring explicit local-source allow-listing, tightening path handling, and updating installer docs/runbook defaults and release checks.

This includes:

- adding a shared source classifier for install/update with explicit local/file source opt-in
- requiring successful copy before updating `skills.json` commit pins
- making `install.sh` path update behavior opt-in and documented around pinned installer usage
- extending release verification to validate release assets against `checksums.txt` and to detect stale install/doc pins
