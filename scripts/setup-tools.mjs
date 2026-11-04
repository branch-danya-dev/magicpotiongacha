import { createHash } from 'node:crypto';
import { chmod, mkdir, readFile, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(await readFile(resolve(root, 'tools.lock.json'), 'utf8'));
const digest = value => createHash('sha256').update(value).digest('hex');
if (!['linux', 'win32', 'darwin'].includes(process.platform)) throw new Error('Unsupported platform');
if (process.platform !== 'darwin' && process.arch !== 'x64') throw new Error('Use Rokit for non-x64 Linux/Windows');

for (const [name, tool] of Object.entries(manifest)) {
  const variant = tool[`${process.platform}-${process.arch}`] ?? tool[process.platform];
  if (!variant) throw new Error(`No pinned ${name} archive for this platform`);
  const archive = resolve(root, '.tools', `${name}.zip`);
  const directory = resolve(root, '.tools', name);
  await mkdir(directory, { recursive: true });
  let bytes;
  try { bytes = await readFile(archive); } catch { /* First installation. */ }
  if (!bytes || digest(bytes) !== variant.sha256) {
    console.log(`Downloading ${name} ${tool.version}`);
    const response = await fetch(variant.url, { signal: AbortSignal.timeout(120_000) });
    if (!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
    bytes = Buffer.from(await response.arrayBuffer());
    if (digest(bytes) !== variant.sha256) throw new Error(`${name}: SHA-256 mismatch; archive rejected`);
    await writeFile(archive, bytes);
  }
  if (process.platform === 'win32') {
    // Windows 10/11 ship bsdtar with ZIP support. Avoid loading a PowerShell
    // script module, which fails under the default Restricted execution policy.
    execFileSync('tar.exe', ['-xf', archive, '-C', directory], { stdio: 'inherit' });
  } else {
    execFileSync('unzip', ['-oq', archive, '-d', directory], { stdio: 'inherit' });
    const bins = name === 'luau' ? ['luau', 'luau-analyze', 'luau-compile'] : ['rojo'];
    for (const binary of bins) await chmod(resolve(directory, binary), 0o755);
  }
  console.log(`${name} ${tool.version}: SHA-256 verified`);
}
