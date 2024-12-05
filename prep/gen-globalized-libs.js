#!/usr/bin/env node
const { hasAnyPathSequence, readSync, writeSync, forEachWalkSync } = require('./common.js');

async function main() {
  const pathSequencesToIgnore = ['g', 'utils/ext/ithaca'];

  forEachWalkSync(['src/utils'], srcPath => {
    if (!srcPath.match(/\.sol$/i)) return;
    if (hasAnyPathSequence(srcPath, pathSequencesToIgnore)) return;

    let src = readSync(srcPath);
    const libraryStartMatch = src.match(/library\s+([A-Za-z0-9]+)\s+\{/);
    if (!libraryStartMatch) return;
    
    let structsSrc = '', usings = [];
    src = src.replace(
      /\s*\/\*\S+?\*\/\s*\/\*\s+STRUCTS?\s+\*\/\s*\/\*\S+?\*\/([\s\S]+?struct\s+[A-Za-z0-9]+\s+\{[\s\S]+?\})+/, 
      m => (structsSrc = m, '')
    );

    for (let m, r = /struct\s+([A-Za-z0-9]+)\s+\{/g; m = r.exec(structsSrc); ) {
      usings.push('using ' + libraryStartMatch[1] + ' for ' + m[1] + ' global;');
    }
    if (usings.length === 0 || structsSrc === '') return;

    const dstPath = srcPath.replace(/([A-Za-z0-9]+\.sol)/, 'g/$1');
    console.log(dstPath);
    writeSync(
      dstPath, 
      src.replace(
        /pragma\s+solidity\s+\^0\.8\.\d+;/, 
        [
          'pragma solidity ^0.8.13;',
          '// This file is auto-generated.',
          structsSrc.replace(/\n    /g, '\n').replace(/^\s*\n+|\n+\s*$/g, ''),
          usings.join('\n').replace(/^\s*\n+|\n+\s*$/g, '')
        ].join('\n\n')
      )
      .replace(/(https\:\/\/\S+?\/solady\/\S+?\/)([A-Za-z0-9]+\.sol)/, '$1g/$2')
      .replace(/(import\s[\s\S]*?["'])\.\/([\s\S]+?["'])/g, '$1../$2')
      .replace(/(library\s+([A-Za-z0-9]+)\s+\{\n)\n*/, '$1')
    );
  });
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
