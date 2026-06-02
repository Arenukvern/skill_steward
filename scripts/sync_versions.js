import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.join(__dirname, '..');

const pkgPath = path.join(ROOT, 'package.json');
const pubspecPath = path.join(ROOT, 'packages', 'steward_cli', 'pubspec.yaml');

if (!fs.existsSync(pkgPath)) {
  console.error(`package.json not found at ${pkgPath}`);
  process.exit(1);
}

if (!fs.existsSync(pubspecPath)) {
  console.error(`pubspec.yaml not found at ${pubspecPath}`);
  process.exit(1);
}

const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const version = pkg.version;

if (!version) {
  console.error('No version found in package.json');
  process.exit(1);
}

let pubspec = fs.readFileSync(pubspecPath, 'utf8');
const versionRegex = /^version:\s*[^\r\n]+/m;

if (!versionRegex.test(pubspec)) {
  console.error('Could not find version line in pubspec.yaml');
  process.exit(1);
}

pubspec = pubspec.replace(versionRegex, `version: ${version}`);
fs.writeFileSync(pubspecPath, pubspec, 'utf8');

console.log(`Synced version: packages/steward_cli/pubspec.yaml is now at ${version}`);
