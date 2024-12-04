#!/usr/bin/env node
const { readSync, writeSync, forEachWalkSync } = require('./common.js');

async function main() {
  forEachWalkSync(['src'], srcPath => {
    if (!srcPath.match(/\.sol$/i)) return;
    const src = readSync(srcPath);
    const cleanedSrc = src.split('\n').map(l => l.replace(/\s+$/, '')).join('\n');
    if (src !== cleanedSrc) writeSync(srcPath, src);
  });
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
