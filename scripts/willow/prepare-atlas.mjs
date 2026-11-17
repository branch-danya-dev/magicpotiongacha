// Deterministic export normalization only; the approved/generated image is preserved.
import {readFileSync,writeFileSync} from 'node:fs';
import {decode,downscale,encode} from '../lunar-pixels.mjs';
const base=new URL('../../assets/environment/willow/',import.meta.url);
const original=decode(readFileSync(new URL('source/FoliageAtlas-generated.png',base)));
writeFileSync(new URL('textures/FoliageAtlas.png',base),encode(1024,downscale(original,1024)));
