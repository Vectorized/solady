#!/usr/bin/env node
const {
  readSync,
  writeSync,
  forEachWalkSync,
  hasAnyPathSequence,
  readSolWithLineLengthSync,
  normalizeNewlines
} = require('./common.js');
const path = require('path');

async function main() {
  const pathSequencesToIgnore = ['g', 'ext', 'legacy'];

  const cleanForRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  
  const makeTagRegex = tag => new RegExp(
    '(<!--\\s?' + cleanForRegex(tag) + ':start\\s?-->)([\s\S]*?)' + 
    '(<!--\\s?' + cleanForRegex(tag) + ':end\\s?-->)'
  );

  const has = (a, b) => a.toLowerCase().indexOf(b.toLowerCase()) !== -1;

  const strip = s => s.replace(/^\s+|\s+$/g, '');

  const replaceInTag = (s, tag, replacement) =>
    s.replace(
      makeTagRegex(tag),
      (m0, m1, m2, m3) => m1 + '\n' + strip(replacement) + '\n' + m3 
    );

  const getTag = (s, tag) => {
    const m = s.match(makeTagRegex(tag));
    if (m === null) return '<!-- ' + tag + ':start -->' + '<!-- ' + tag + ':end -->';
    return m[0];
  };

  const coalesce = (m, f) => m === null ? '' : f(m);
  
  const toHeaderCase = str =>
    strip(str).toLowerCase()
    .replace(/(eth|sha|lz|uups|(eip|rip|erc|push|create)\-?[0-9]+i?)/g, m => m.toUpperCase())
    .split(/\s+/)
    .map(w => w.replace(/^([a-zA-Z])/, c => c.toUpperCase()))
    .join(' ');

  const deindent = s => s.replace(/^ {4}/gm, '');

  const getFunctionSig = s => coalesce(
    s.match(/(\w+)\s*\(([^)]*)\)/),
    m => m[1] + '(' + m[2].split(',').map(x => strip(x).split(/\s+/)[0]) + ')'
  );

  const cleanNatspecOrNote = s => deindent(strip(
    s.replace(/\s+\/\/\/?/g, '\n')
    .replace(/\s?\n\s?/g, '   \n')
    .replace(/```([\s\S]+?)```/g, '```solidity$1```')
    .replace(/^\/\/\/\s+@[a-z]+\s?/, '')
  ));

  const getSections = s => {
    const sectionHeaderRe = /\/\*\S+?\*\/\s*\/\*([^*]{60})\*\/\s*\/\*\S+?\*\//g;
    let a = [], l = null;
    for (let m = null; (m = sectionHeaderRe.exec(s)) !== null; l = m) {
      if (l !== null) {
        a.push({
          h2: toHeaderCase(l[1]),
          src: s.slice(l.index + l[0].length, m.index)
        });
      }
    }
    if (l !== null) {
      a.push({
        h2: toHeaderCase(l[1]),
        src: s.slice(l.index + l[0].length)
      });
    }
    return a
      .filter(x => !has(x.h2, 'private'))
      .map(item => {
        const m = item.src.match(/^((\s+\/\/\s[^\n]+)+)/);
        if (m) item.note = cleanNatspecOrNote(m[0]);
        return item;
      });
  };

  const getSubSections = (s, r) => {
    let a = [];
    for (let m = null; (m = r.exec(s)) !== null; ) {
      if (!has(m[2], '///') && !/\sprivate\s/.test(m[2])) a.push(m);
    }
    return a;
  }

  const getFunctionsAndModifiers = s =>
    getSubSections(s, /((?:\/\/\/\s[^\n]+\n\s*?)+)((?:function|fallback|receive|modifier)[^{]+)/g)
    .map(m => ({
      natspec: cleanNatspecOrNote(m[1]), 
      def: deindent(strip(m[2])),
      h3: getFunctionSig(deindent(strip(m[2])))
    }));

  const getConstantsAndImmutables = s => 
    getSubSections(s, /((?:\/\/\/\s[^\n]+\n\s*?)+)((?:bytes|uint|address)[0-9]*\s+(?:public|internal)\s+(?:immutable|constant)\s+([A-Za-z0-9_]+)[^;]*)/g)
    .map(m => ({
      natspec: cleanNatspecOrNote(m[1]), 
      def: deindent(strip(m[2])),
      h3: deindent(strip(m[3]))
    }));
    
  const getCustomErrors = s =>
    getSubSections(s, /((?:\/\/\/\s[^\n]+\n\s*?)+)(error\s[^;]+);/g)
    .map(m => ({
      natspec: cleanNatspecOrNote(m[1]), 
      def: deindent(strip(m[2])),
      h3: getFunctionSig(deindent(strip(m[2])))
    }));

  const getStructsAndEnums = s =>
    getSubSections(s, /((?:\/\/\/\s[^\n]+\n\s*?)+)((?:struct|enum)\s([A-Za-z0-9_]+)\s+\{[^}]+})/g)
    .map(m => ({
      natspec: cleanNatspecOrNote(m[1]), 
      def: deindent(strip(m[2])),
      h3: deindent(strip(m[3]))
    }));

  const getNotice = s => coalesce(
    s.match(/\/\/\/\s+@notice\s+([\s\S]+?)\/\/\/\s?@author/), 
    m => m[1].replace(/\n\/\/\//g, '')
  );

  const getImports = (s, srcPath) => {
    const r = /import\s[\s\S]*?(["'][\s\S]+?["'])/g;
    let a = [];
    for (let m = null; (m = r.exec(s)) !== null; ) {
      const p = path.normalize(path.join(path.dirname(srcPath), m[1].slice(1, -1)));
      a.push(p.split(path.sep).slice(-2).join(path.sep));
    }
    return a;
  };

  const getTopIntro = s => coalesce(
    s.match(/\/\/\/\s+@notice\s+[\s\S]+?(?:\/\/\/\s?@author\s+[\s\S]+?\n|\/\/\/\s+\([\s\S]+?\)\n)+([\s\S]*?)(?:library|abstract\s+contract|contract)\s[^.]+\{/), 
    m => normalizeNewlines(strip(
      m[1].replace('\n\n', '\n\n\n').split('\n')
      .map(l => l
        .replace(/(\d\d)\:(\d\d)\:/g, '$1&#58;$2&#58;')
        .replace(/^\/{2,3}\s{2,3}([1-9][0-9]*?)\.\s/, '    $1. ')
        .replace(/^\/{2,3}\s*/, '')
        .replace(/^(-\s+[\s\S]{1,64})\:/, '$1&#58;')
        .replace(/^@dev\s?([\s\S]+?)\:/, '$1:\n\n')
        .replace(/^Note\:/, 'Note:\n\n')
        .replace(/^[\s\S]{1,64}\:/, m => has(m, 'http') ? m : '<b>' + m + '</b>')
      ).join('\n')
      .replace(/\.\n\<b\>([\s\S]+?)\:\<\/b\>/, '. $1:')
      .replace(/@dev\s/g, '')
      .replace(/\-{32,}\s?\+\s*?([\s\S]+)\-{32,}\s?\+/g, (m0, m1) => {
        const lines = strip(m1.replace(/\-+\s*$/g, '')).split('\n');
        const n = Math.max.apply(null, lines.map(l => l.split('|').map(strip).filter(c => c.length).length));
        const h = '|' + Array(n + 1).join(' -- |');
        return '\n\n' + lines.map(l => l.match(/\-{32,}\s?\|/) ? h : '| ' + l).join('\n') + '\n\n';
      })
    ))
  );

  const getInherits = (s, srcPath) => coalesce(
    s.match(/contract\s+[A-Za-z0-9_]+\s+is\s+([^\{]*?)\s*\{/),
    m => '<b>Inherits:</b>  \n\n' +
      m[1].split(',').map(strip).map(p => 
        getImports(s, srcPath).map(q => has(q, p) ? '- `' + q + '`  \n' : '').join('')
      ).join('')
  );

  const getSrcDir = srcPath => srcPath.split(path.sep).slice(-2)[0];
  const getTitle = srcPath => path.parse(srcPath).name;
  const getDocSubPath = srcPath => path.join(getSrcDir(srcPath), getTitle(srcPath).toLowerCase() + '.md');
  const getDocPath = srcPath => path.join('docs', getDocSubPath(srcPath));

  let docSrcPaths = [];

  forEachWalkSync(['src'], srcPath => {
    if (!srcPath.match(/\.sol$/i)) return;
    if (hasAnyPathSequence(srcPath, pathSequencesToIgnore)) return;
    if (has(srcPath, 'Milady.sol')) return;
    console.log(srcPath);

    let src = readSolWithLineLengthSync(srcPath, 80);
    let sections = getSections(src);

    if (sections.length < 1) {
      src = src.replace(
        /(library|contract)\s[\s\S]*?\{/, 
        m => m + 
          '/*============================================================*/\n' + 
          '/*                         FUNCTIONS                          */\n' + 
          '/*============================================================*/\n'
      );
      sections = getSections(src);
    }

    const docHeader = '# ' + getTitle(srcPath) + '\n\n' + getNotice(src);
    let docChunks = [];
    sections.forEach(x => 
      [
        getStructsAndEnums,
        getCustomErrors,
        getFunctionsAndModifiers,
        getConstantsAndImmutables
      ]
      .reduce((acc, f) => acc.length ? acc : f(x.src), [])
      .forEach((y, i) => 
        docChunks.push(
          ...(i ? [] : ['## ' + x.h2, ...(x.note ? [x.note] : [])]),
          '### ' + y.h3, 
          '```solidity\n' + y.def + '\n```', 
          y.natspec
        )
      )
    );

    if (docChunks.length) {
      writeSync(
        getDocPath(srcPath),
        [
          docHeader, 
          getTopIntro(src),
          getInherits(src, srcPath),
          getTag(readSync(getDocPath(srcPath)), 'customintro'), 
          docChunks.join('\n\n')
        ].join('\n\n')
      );
      docSrcPaths.push(srcPath);
    }
  });

  if (docSrcPaths.length) {
    docSrcPaths.forEach(p => {
      writeSync(
        getDocPath(p),
        readSync(getDocPath(p))
        .replace(/((?:See\:)?\s)`([A-Za-z0-9\/]+?\.sol)`/ig, (m0, m1, m2) => {
          if (!m0.match(/^See\:/i) && !m2.match(/\.sol$/i)) return m0;
          let l = docSrcPaths.filter(q => has(q, getTitle(m2)));
          return l.length ? m1 + '[`' + m2 + '`](' + getDocSubPath(l[0]) + ')' : m0;
        })
      );
    });
    const sidebarDocPath = path.join('docs', 'sidebar.md');
    writeSync(
      sidebarDocPath, 
      replaceInTag(
        readSync(sidebarDocPath),
        'gen',
        [...new Set(docSrcPaths.map(getSrcDir))]
        .map(dir => '- ' + dir + '\n' +
          docSrcPaths
          .filter(p => getSrcDir(p) === dir)
          .map(p => '  - [' + getTitle(p) + '](' + getDocSubPath(p) + ')')
          .join('\n')
        ).join('\n')
      )
    );
  }
};

main().catch(e => {
  console.error(e);
  process.exit(1);
});
