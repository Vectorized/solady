#!/usr/bin/env node
const { readSync, forEachWalkSync, hasAnyPathSequence } = require('./common.js');

async function main() {
  const pathSequencesToIgnore = ['g', 'legacy'];

  const loggedSrcPaths = [];
  forEachWalkSync(['src'], srcPath => {
    if (!srcPath.match(/\.sol$/i)) return;
    if (hasAnyPathSequence(srcPath, pathSequencesToIgnore)) return;

    const src = readSync(srcPath);
    const assemblyTagRe = /(\/\/\/\s*?@solidity\s*?memory-safe-assembly\s+?)?assembly\s*?(\(.*?\))?\{/gm;
    for (let m = null; (m = assemblyTagRe.exec(src)) !== null; ) {
      if ((m[0] + '').indexOf('memory-safe') === -1) {
        if (loggedSrcPaths.indexOf(srcPath) === -1) {
          loggedSrcPaths.push(srcPath);
          console.log(srcPath + ':');
        }
        console.log('  line:', src.slice(0, m.index).split(/\n/).length);
      }
    }
  });
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
