// Let historical guards inspect their exact inherited owner, not skip it.
// check-ag68 independently pins the stripped owner to PR37 and audits additions.
import {beforeAG69} from './ag69-preservation.mjs';
export function beforeAG68(path, source) {
  source=beforeAG69(path,source);
  if (path !== 'src/client/EnvironmentView.luau') return source;
  return source.replace(/^[\t ]*-- AG68_BEGIN_(\w+)\n[\s\S]*?^[\t ]*-- AG68_END_\1\n/gm, '');
}
