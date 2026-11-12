// AG-00: verify actual ancestry and repeatable ordinary-place construction.
// This proves build provenance, never native gameplay/asset permission acceptance.
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trim();
const manifest = JSON.parse(readFileSync(resolve(root, 'docs/AG00_BASELINE.json'), 'utf8'));
const sha256 = file => createHash('sha256').update(readFileSync(resolve(root, file))).digest('hex');
const sourceSha = git('rev-parse', 'HEAD');
for (const [name, sha] of Object.entries(manifest.ancestors)) {
  try { git('merge-base', '--is-ancestor', sha, sourceSha); }
  catch { throw new Error(`${name} (${sha}) is not a verified ancestor; fetch full history before checking.`); }
}
const trackedChanges = git('status', '--porcelain', '--untracked-files=no');
if (trackedChanges) throw new Error('Commit tracked changes before recording exact-HEAD build evidence.');
const verification = readFileSync(resolve(root, 'build/verification.log'), 'utf8');
if (!verification.startsWith(`Source SHA: ${sourceSha}\n`) || !/\nPASS: \d+ Luau sources; compile, portable analysis, tests, Rojo build and sourcemap\.\n$/.test(verification)) {
  throw new Error('Run npm test on this exact HEAD before recording the AG-00 baseline.');
}
const place = 'build/PotionTycoon.rbxlx';
const repeat = 'build/AG00-repeat.rbxlx';
execFileSync(resolve(root, '.tools/rojo', process.platform === 'win32' ? 'rojo.exe' : 'rojo'),
  ['build', 'default.project.json', '-o', repeat], { cwd: root, stdio: 'inherit' });
if (sha256(place) !== sha256(repeat)) throw new Error('Repeated ordinary-place build differs byte for byte.');
const receipt = {
  task: manifest.task, sourceSha, platform: process.platform, node: process.version,
  ancestors: manifest.ancestors, trackedChanges: false,
  ordinaryPlaceRepeatIdentical: true,
  artifacts: Object.fromEntries([place, repeat, 'build/M7PilotReview.rbxlx', 'build/verification.log']
    .map(file => [file, sha256(file)])),
  nativeAcceptance: 'See docs/AG00_INTEGRATION_BASE.md; CLI cannot certify Studio, permissions, mobile or backend.',
};
writeFileSync(resolve(root, 'build/ag00-integration.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log(`AG-00 ancestry and repeat-build PASS at ${sourceSha}; build/ag00-integration.json`);
