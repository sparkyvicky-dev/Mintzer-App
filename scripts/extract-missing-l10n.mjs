import fs from 'fs';
import path from 'path';

function walk(d, out = []) {
  for (const n of fs.readdirSync(d)) {
    const p = path.join(d, n);
    if (fs.statSync(p).isDirectory()) walk(p, out);
    else if (p.endsWith('.dart')) out.push(p);
  }
  return out;
}

function decodeDart(body) {
  return body
    .replace(/\\n/g, '\n')
    .replace(/\\'/g, "'")
    .replace(/\\"/g, '"')
    .replace(/\\\\/g, '\\');
}

const found = [];
for (const f of walk('app/lib')) {
  const text = fs.readFileSync(f, 'utf8');
  const re = /\/\/ l10n-missing\s*\n([\s\S]{0,400})/g;
  let m;
  while ((m = re.exec(text))) {
    const chunk = m[1];
    const lit = chunk.match(/'((?:\\'|[^'])*)'|"((?:\\"|[^"])*)"/);
    if (!lit) {
      found.push({ file: f.replaceAll('\\', '/'), raw: chunk.split('\n')[0].trim(), interpolated: true });
      continue;
    }
    const body = lit[1] ?? lit[2];
    const interpolated = body.includes('$') || chunk.includes('${');
    found.push({
      file: f.replaceAll('\\', '/'),
      text: decodeDart(body),
      interpolated,
    });
  }
}

const plain = [...new Set(found.filter((x) => x.text && !x.interpolated).map((x) => x.text))].sort();
const interp = found.filter((x) => x.interpolated);
fs.writeFileSync('scripts/missing-en.json', JSON.stringify(plain, null, 2));
console.log('plain unique', plain.length, 'interp sites', interp.length);
console.log('---INTERP---');
for (const row of interp) console.log(row.file, '|', (row.text || row.raw || '').slice(0, 160));
