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

const simple = [];
const other = [];
for (const f of walk('app/lib')) {
  const lines = fs.readFileSync(f, 'utf8').split(/\n/);
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].includes('l10n-missing')) continue;
    let j = i + 1;
    while (j < lines.length && lines[j].trim() === '') j++;
    const s = (lines[j] || '').trim();
    const rel = f.replaceAll('\\', '/');
    if (s.includes('$') || s.includes('S.t(') || !/['"]/.test(s)) other.push(`${rel}:${j + 1} ${s.slice(0, 180)}`);
    else simple.push(s.slice(0, 200));
  }
}
console.log('simple', simple.length, 'other', other.length);
console.log('unique simple', new Set(simple).size);
console.log('---OTHER---');
for (const line of other) console.log(line);
