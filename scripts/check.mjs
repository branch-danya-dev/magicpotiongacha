import { mkdir, readdir, readFile } from 'node:fs/promises';
import { mkdirSync, writeFileSync, appendFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { resolve, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const suffix = process.platform === 'win32' ? '.exe' : '';
const tool = (group, name) => resolve(root, '.tools', group, name + suffix);
mkdirSync(resolve(root, 'build'), { recursive: true });
const log = resolve(root, 'build/verification.log');
const sha = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
writeFileSync(log, `Source SHA: ${sha.stdout?.trim() || 'unavailable'}\nPlatform: ${process.platform}\n`);
function run(binary, args) {
  const command = `> ${relative(root, binary)} ${args.join(' ')}`;
  console.log(command);
  const result = spawnSync(binary, args, { cwd: root, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
  process.stdout.write(result.stdout || '');
  process.stderr.write(result.stderr || '');
  appendFileSync(log, command + '\n' + (result.stdout || '') + (result.stderr || ''));
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status || 1);
}
async function files(directory) {
  const found = [];
  for (const item of await readdir(resolve(root, directory), { withFileTypes: true })) {
    const file = `${directory}/${item.name}`;
    if (item.isDirectory()) found.push(...await files(file));
    else if (file.endsWith('.luau')) found.push(file);
  }
  return found.sort();
}
JSON.parse(await readFile(resolve(root, 'default.project.json'), 'utf8'));
const all = [...await files('src'), ...await files('tests'), ...await files('qa')];
run(process.execPath, ['scripts/check-environment.mjs']);
run(process.execPath, ['scripts/check-task06.mjs']);
run(process.execPath, ['scripts/check-07a.mjs']);
run(process.execPath, ['scripts/check-07b.mjs']);
run(process.execPath, ['scripts/check-07c.mjs']);
run(process.execPath, ['scripts/check-visual-preservation.mjs']);
run(process.execPath, ['scripts/check-ui.mjs']);
run(process.execPath, ['scripts/check-18a-evidence.mjs']);
run(process.execPath, ['scripts/check-19a-evidence.mjs']);
run(process.execPath, ['scripts/check-19b-evidence.mjs']);
run(process.execPath, ['scripts/check-spellbook.mjs']);
run(tool('luau', 'luau-compile'), ['--null', ...all]);
// Roblox engine scripts require Studio's type environment. The portable domain and
// persistence modules are checked here; the runtime scripts are compiled above.
const portable = all.filter(file => file.startsWith('src/shared/') || file.startsWith('tests/') || ['src/server/ProfileStore.luau', 'src/server/TradeJournal.luau', 'src/server/TradeCoordinator.luau', 'src/server/ReceiptJournal.luau', 'src/server/PurchaseCoordinator.luau'].includes(file));
run(tool('luau', 'luau-analyze'), portable);
run(tool('luau', 'luau'), ['tests/run.luau']);
run(tool('luau', 'luau'), ['tests/run_ag01.luau']);
await mkdir(resolve(root, 'build'), { recursive: true });
run(tool('rojo', 'rojo'), ['build', 'default.project.json', '-o', 'build/PotionTycoon.rbxlx']);
run(tool('rojo', 'rojo'), ['sourcemap', 'default.project.json', '-o', 'build/sourcemap.json']);
run(tool('rojo', 'rojo'), ['build', 'qa/environment.project.json', '-o', 'build/M7PilotReview.rbxlx']);
run(tool('rojo', 'rojo'), ['sourcemap', 'qa/environment.project.json', '-o', 'build/environment-sourcemap.json']);
run(process.execPath, ['scripts/check-visual-preservation.mjs', '--built']);
run(process.execPath, ['scripts/check-spellbook.mjs', '--built']);
console.log(`Verified ${all.length} Luau sources and built build/PotionTycoon.rbxlx`);
appendFileSync(log, `PASS: ${all.length} Luau sources; compile, portable analysis, tests, Rojo build and sourcemap.\n`);
