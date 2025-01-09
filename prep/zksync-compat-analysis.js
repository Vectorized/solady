#!/usr/bin/env node
const { readSync, forEachWalkSync } = require('./common.js');
const { execSync } = require('child_process');

async function main() {
  const getLastModifiedGitTimestamp = (filePath) => {
    try {
      const output = execSync(`git log -1 --format=%ct -- ${filePath}`, { encoding: 'utf-8' });
      return ~~output.trim();
    } catch (error) {
      return null;
    }
  };

  let zkSyncIncompatOpcodes = [
    'codecopy', 'extcodecopy'
  ];

  let specialPatterns = [
    {name: 'precompile4', reStr: 'staticcall\\([^,]*?,\\s*?(0x0*)?4'}
  ]

  let flattenedPathsAndScores = [];

  forEachWalkSync(['src'], srcPath => {
    if (!srcPath.match(/\.sol$/i) || srcPath.match(/\/(g|legacy)\//)) return;

    const src = readSync(srcPath);
    const numMatches = reStr => (src.match(new RegExp(reStr, 'img')) || []).length;
    let totalScore = 0;
    let scores = {};
    let redundantGasCount = 0;
    zkSyncIncompatOpcodes.forEach(opcode => {
      const score = numMatches('[^a-zA-z]' + opcode + '\\(');
      if (opcode.match(/call$/)) {
        redundantGasCount += numMatches('[^a-zA-z]' + opcode + '\\([\\S\\s]*?gas\\s*?\\(');
      }
      totalScore += score;
      scores[opcode] = score;
    });
    specialPatterns.forEach(c => {
      const score = numMatches(c.reStr);
      totalScore += score;
      scores[c.name] = score;
    });
    if (redundantGasCount) scores['gas'] -= redundantGasCount;
    for (const key in scores) if (scores[key] === 0) delete scores[key];
    const lastModifiedGitTimestamp = getLastModifiedGitTimestamp(srcPath);
    flattenedPathsAndScores.push({srcPath, scores, totalScore, lastModifiedGitTimestamp});
  });

  flattenedPathsAndScores.sort((a, b) => a.totalScore - b.totalScore);
  flattenedPathsAndScores.forEach(x => {
    if (x.totalScore === 0) delete x.scores;
    delete x.totalScore;
  });
  console.log(JSON.stringify(flattenedPathsAndScores, null, 4));
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
