# Repo-local copy/init pattern

Use this reference when a product repo needs a local script that reproduces the
same install shape across Codex, Cursor, Claude Code, and skills-only channels.
The product repo owns the script and generated payloads; Skill Steward only
teaches the pattern.

## Inputs to inspect

| Input | Purpose |
|-------|---------|
| `skills/*/SKILL.md` | Canonical skill bodies to copy into plugin payloads |
| `plugin/` or `plugins/{id}/` | Existing product-owned plugin payload |
| `package.json`, `pubspec.yaml`, release config | Product id, version, repository, license |
| `.mcp.json`, `mcp.json`, `.app.json` | Optional runtime config referenced by host manifests |
| `hooks/`, `.cursor/hooks.json`, commands/rules | Optional wiring that skills alone cannot install |
| `assets/` | Icons, logos, screenshots, or store assets referenced by manifests |

## Generated layout

```text
repo/
├── .agents/plugins/marketplace.json        # Codex repo/team catalog
├── .claude-plugin/marketplace.json         # Claude marketplace catalog
├── .cursor-plugin/marketplace.json         # Cursor team catalog when needed
└── plugin/                                 # Product-owned plugin payload
    ├── .plugin/plugin.json                 # Optional Open Plugin baseline
    ├── .codex-plugin/plugin.json
    ├── .claude-plugin/plugin.json
    ├── .cursor-plugin/plugin.json
    ├── skills/{skill-id}/SKILL.md
    ├── hooks/
    ├── assets/
    └── mcp.json
```

Use only the files that the target host actually needs. Do not include
`skills`, `mcpServers`, `hooks`, `commands`, or asset paths in a manifest unless
the referenced file or directory exists in the plugin payload.

## Local script contract

A repo-local copy/init script should:

- accept `codex`, `cursor`, `claude-code`, `agents-skills`, or `all`
- support project/user scope when the host has both
- create directories before writes
- copy skills recursively without dotfile surprises
- overwrite only owned generated paths, or require `--force`
- print changed paths and skipped optional payloads
- document rollback by deleting the generated plugin/cache/catalog entry

## Dart skeleton

```dart
import 'dart:io';

const productId = '<product-id>';
const skillIds = ['<skill-id>'];

void main(List<String> args) {
  final target = args.isEmpty ? 'all' : args.first;
  final root = Directory.current.path;
  if (target == 'all' || target == 'cursor') writeCursor(root);
  if (target == 'all' || target == 'codex') writeCodex(root);
  if (target == 'all' || target == 'claude-code') writeClaude(root);
  if (target == 'all' || target == 'agents-skills') writeAgentsSkills(root);
}

void writeCursor(String root) {
  final base = Directory('$root/.cursor/plugins/local/$productId');
  copyDirectory(Directory('$root/plugin'), base);
}

void writeCodex(String root) {
  final base = Directory('$root/.codex/plugins/cache/local/$productId/local');
  copyDirectory(Directory('$root/plugin'), base);
  writeFile(
    '$root/.agents/plugins/marketplace.json',
    '{"name":"local-$productId","plugins":[{"name":"$productId","source":{"source":"local","path":"$base"},"policy":{"installation":"AVAILABLE","authentication":"ON_INSTALL"},"category":"Developer Tools"}]}\n',
  );
}

void writeClaude(String root) {
  for (final id in skillIds) {
    copyDirectory(
      Directory('$root/skills/$id'),
      Directory('$root/.claude/skills/$productId/$id'),
    );
  }
}

void writeAgentsSkills(String root) {
  for (final id in skillIds) {
    copyDirectory(Directory('$root/skills/$id'), Directory('$root/.agents/skills/$id'));
  }
}

void copyDirectory(Directory source, Directory destination) {
  if (!source.existsSync()) return;
  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.last;
    if (name.startsWith('.')) {
      continue;
    }
    final target = '${destination.path}/$name';
    if (entity is Directory) {
      copyDirectory(entity, Directory(target));
    } else if (entity is File) {
      File(target)
        ..createSync(recursive: true)
        ..writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

void writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}
```

Treat this as a starting point, not a universal implementation. Product repos
should add JSON encoding, conflict policy, tests, version injection, and host
manifest validation according to their native stack.

## Validation notes

| Channel | Check |
|---------|-------|
| Skills-only | `npx skills add <owner>/<repo> --copy` installs expected skills |
| Cursor local | `.cursor/plugins/local/<id>/.cursor-plugin/plugin.json` exists and references existing files only |
| Claude marketplace | `.claude-plugin/marketplace.json` points to the plugin payload |
| Codex marketplace | `.agents/plugins/marketplace.json` has supported root shape and source path stays inside the catalog root or points to the local generated payload |
| Cache refresh | Reinstall or delete generated cache entries before claiming new manifest behavior |
| Rollback | Delete generated plugin payload/cache/catalog entries and re-run native install |

## Non-claims

- A generated local copy script is not public marketplace approval.
- A host manifest is not proof that the MCP server, hooks, or app integration
  work at runtime.
- A skills-only install is not plugin wiring.
- A green static eval is not fresh-agent install proof.
