#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

async function main() {
  const walkSync = (dir, callback) => {
    fs.readdirSync(dir).forEach(file => {
      const srcPath = path.join(dir, file);
      const stats = fs.statSync(srcPath);
      stats.isDirectory() ? walkSync(srcPath, callback) : stats.isFile() && callback(srcPath, stats);
    });
  };
  
  const getLastModifiedGitTimestamp = (filePath) => {
    try {
      const output = execSync(`git log -1 --format=%ct -- ${filePath}`, { encoding: 'utf-8' });
      return ~~output.trim();
    } catch (error) {
      return null;
    }
  };

  let eofBannedOpcodes = [
    'codesize', 'codecopy',
    'extcodesize', 'extcodecopy', 'extcodehash',
    'jump', 'pc',
    'gas', 'gaslimit', 'gasprice',
    'create', 'create2',
    'call', 'staticcall', 'delegatecall',
    'selfdestruct', 'callcode'
  ];

  let flattenedPathsAndScores = [];

  ['src'].forEach(dir => {
    walkSync(dir, srcPath => {
      if (!srcPath.match(/\.sol$/i) || srcPath.match(/\/(g|legacy)\//)) return;

      const src = fs.readFileSync(srcPath, { encoding: 'utf8', flag: 'r' });
      const numMatches = reStr => (src.match(new RegExp(reStr, 'g')) || []).length;
      let totalScore = 0;
      let scores = {};
      let redundantGasCount = 0;
      eofBannedOpcodes.forEach(opcode => {
        const score = numMatches('[^a-zA-z]' + opcode + '\\(');
        if (opcode.match(/call$/)) {
          redundantGasCount += numMatches('[^a-zA-z]' + opcode + '\\([\\S\\s]*?gas\\s*?\\(');
        }
        totalScore += score;
        scores[opcode] = score;
      });
      if (redundantGasCount) scores['gas'] -= redundantGasCount;
      for (const key in scores) if (scores[key] === 0) delete scores[key];
      const lastModifiedGitTimestamp = getLastModifiedGitTimestamp(srcPath);
      flattenedPathsAndScores.push({srcPath, scores, totalScore, lastModifiedGitTimestamp});
    });
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
