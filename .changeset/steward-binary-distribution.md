---
"skill-steward": minor
---

feat: distribute steward CLI as precompiled native binary with curl-friendly install.sh

- Update `release-changelog-harness` skill to document zero-dependency AOT compiling, path override resolution, and install.sh mechanics.
- Add ADR 0014 documenting the architectural decision to distribute the steward CLI.
- Create `scripts/build_release_artifacts.sh` to compile native steward binaries for darwin-arm64 and linux-x64.
- Create `install.sh` at repository root for downloading, verifying checksums, and installing the binary.
- Create GitHub Actions workflow `.github/workflows/publish-binaries.yml` to attach binary release assets on tag pushes.
- Document binary installation and validation options in README and DX_FAQ.
