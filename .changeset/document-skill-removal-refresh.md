---
"skill-steward": patch
---

Document how consumers remove installed skills that upstream deleted: `npx skills update` never prunes removed skills, so the updating-installed-skills guide now covers `npx skills remove`, direct removal from the universal store and symlinked or plain-copy agent directories, dangling-symlink checks, and the current six-skill guild surface.
