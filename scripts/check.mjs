import { mkdir, readdir, readFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { resolve, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const suffix = process.platform === 'win32' ? '.exe' : '';
const tool = (group, name) => resolve(root, '.tools', group, name + suffix);
function run(binary, args) {
  console.log(`> ${relative(root, binary)} ${args.join(' ')}`);
  const result = spawnSync(binary, args, { cwd: root, stdio: 'inherit' });
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
const all = [...await files('src'), ...await files('tests')];
run(tool('luau', 'luau-compile'), ['--null', ...all]);
// Roblox engine scripts require Studio's type environment. The portable domain and
// persistence modules are checked here; the runtime scripts are compiled above.
const portable = all.filter(file => file.startsWith('src/shared/') || file.startsWith('tests/') || file === 'src/server/ProfileStore.luau');
run(tool('luau', 'luau-analyze'), portable);
run(tool('luau', 'luau'), ['tests/run.luau']);
await mkdir(resolve(root, 'build'), { recursive: true });
run(tool('rojo', 'rojo'), ['build', 'default.project.json', '-o', 'build/PotionTycoon.rbxlx']);
run(tool('rojo', 'rojo'), ['sourcemap', 'default.project.json', '-o', 'build/sourcemap.json']);
console.log(`Verified ${all.length} Luau sources and built build/PotionTycoon.rbxlx`);
