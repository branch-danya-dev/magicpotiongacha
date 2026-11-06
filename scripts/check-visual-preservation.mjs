// Full-game Studio must not silently lose the accepted M7 pilot when gameplay changes.
import assert from 'node:assert/strict';
import { readFileSync, statSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const read = path => readFileSync(resolve(root, path), 'utf8');
const release = JSON.parse(read('default.project.json'));
const review = JSON.parse(read('qa/environment.project.json'));
const main = read('src/server/Main.server.luau');
const settings = read('src/server/ServerSettings.luau');
const world = read('src/server/World.luau');
const environment = read('src/server/EnvironmentArt.luau');
const client = read('src/client/Environment.client.luau');

assert.equal(release.tree.ServerScriptService.PotionTycoon.$path, 'src/server');
assert.equal(release.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon.$path, 'src/client');
assert.equal(release.tree.ServerStorage.M7NatureTemplates.$path,
  'assets/environment/woodland/M7NatureTemplates.rbxmx');
assert.equal(review.tree.ServerStorage.M7NatureTemplates.$path,
  '../assets/environment/woodland/M7NatureTemplates.rbxmx');
assert.equal(review.tree.ServerScriptService.M7Review.VistaArt.$path,
  '../src/server/VistaArt.luau');
assert(statSync(resolve(root, 'assets/environment/woodland/M7NatureTemplates.rbxmx')).size > 1000,
  'M7 woodland models disappeared');

assert.match(settings, /EnvironmentArtEnabled\s*=\s*false/,
  'Unaccepted artwork must remain disabled in published servers');
assert.match(main, /local memoryMode = RunService:IsStudio\(\) and Settings.UseMemoryInStudio/);
assert.match(main, /local studioVisualPreview = memoryMode/,
  'In-memory Studio sessions must preview M7 in the full game');
assert.match(main, /\}, Settings.EnvironmentArtEnabled or studioVisualPreview\)/,
  'World.new must receive Studio visual preview flag');
assert.match(world, /if self.environmentArtEnabled then EnvironmentArt.attach\(self\) end/);
assert.match(world, /if self.environmentArtEnabled then PropArt.attach\(self\) end/);
assert.match(environment, /world.root:SetAttribute\("EnvironmentArtEnabled",true\)/);
assert.match(client, /root:GetAttribute\("EnvironmentArtEnabled"\)==true/,
  'The client environment must activate from the server art attribute');

if (process.argv.includes('--built')) {
  const artifacts = {
    'build/PotionTycoon.rbxlx': [
      'M7NatureTemplates', 'EnvironmentArt', 'PropArt', 'IslandLandscape',
      'ForestArt', 'VistaArt', 'Environment', 'Main',
    ],
    'build/M7PilotReview.rbxlx': [
      'M7NatureTemplates', 'EnvironmentArt', 'PropArt', 'IslandLandscape',
      'ForestArt', 'VistaArt', 'Review', 'EnvironmentView',
    ],
  };
  for (const [path, names] of Object.entries(artifacts)) {
    const xml = read(path);
    assert(xml.includes('<roblox '), path + ': not a Rojo place XML');
    for (const name of names) {
      assert(xml.includes('<string name="Name">' + name + '</string>'),
        path + ': missing built instance ' + name);
    }
  }
  assert(read('build/PotionTycoon.rbxlx').includes('studioVisualPreview'),
    'Full-game place omitted the Studio-only visual override');
}

console.log('M7 preservation PASS: art sources, template, Studio game preview, gated release and Rojo artifacts');
