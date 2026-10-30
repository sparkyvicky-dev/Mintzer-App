import fs from 'fs';
import path from 'path';

const en = new Set(JSON.parse(fs.readFileSync('scripts/missing-en.json', 'utf8')));
const skip = new Set(['start', 'pay', 'whatsapp', 'deals', 'order', 'after', 'account', '1', '…']);
const months = new Set(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']);

function walk(d, out = []) {
  for (const n of fs.readdirSync(d)) {
    const p = path.join(d, n);
    if (fs.statSync(p).isDirectory()) walk(p, out);
    else if (p.endsWith('.dart')) out.push(p);
  }
  return out;
}

function dartQuote(s) {
  return "'" + s.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$') + "'";
}

function literals(line) {
  const out = [];
  const re = /'((?:\\'|[^'])*)'/g;
  let m;
  while ((m = re.exec(line))) {
    out.push({ raw: m[0], text: m[1].replace(/\\'/g, "'").replace(/\\\\/g, '\\') });
  }
  return out;
}

let filesChanged = 0;
let replacements = 0;

for (const file of walk('app/lib')) {
  if (file.includes(`${path.sep}l10n${path.sep}`)) continue;
  const lines = fs.readFileSync(file, 'utf8').split(/\n/);
  let changed = false;
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].includes('l10n-missing')) continue;
    const windowEnd = Math.min(lines.length, i + 8);
    const hits = [];
    for (let j = i + 1; j < windowEnd; j++) {
      if (lines[j].includes('l10n-missing')) break;
      for (const lit of literals(lines[j])) {
        if (!en.has(lit.text) || lit.text.includes('$')) continue;
        hits.push({ j, ...lit });
      }
    }
    if (!hits.length) continue;
    const monthHits = hits.filter((h) => months.has(h.text));
    const chosen = monthHits.length ? monthHits : [hits.find((h) => !skip.has(h.text)) || hits[0]];
    const byLine = new Map();
    for (const h of chosen) {
      if (!byLine.has(h.j)) byLine.set(h.j, []);
      byLine.get(h.j).push(h);
    }
    for (const [j, group] of byLine) {
      let line = lines[j];
      for (const h of group) {
        const next = `S.e(${dartQuote(h.text)})`;
        if (!line.includes(h.raw)) continue;
        line = line.replace(h.raw, next);
        replacements++;
      }
      lines[j] = line;
    }
    lines[i] = lines[i].replace(/\s*\/\/ l10n-missing\s*$/, '');
    if (lines[i].trim() === '') lines.splice(i, 1);
    changed = true;
    i--;
  }
  if (!changed) continue;
  let text = lines.join('\n');
  text = text.replace(/const (Text\([\s\S]{0,180}?S\.e\()/g, '$1');
  if (!text.includes("l10n/s.dart") && text.includes('S.e(')) {
    const imp = text.includes("import '../l10n/s.dart'") || text.includes('import "l10n/s.dart"');
    if (!imp) {
      const nl = text.indexOf('\n');
      text = text.slice(0, nl + 1) + "import '../l10n/s.dart';\n" + text.slice(nl + 1);
    }
  }
  fs.writeFileSync(file, text);
  filesChanged++;
}
console.log('files', filesChanged, 'replacements', replacements);
