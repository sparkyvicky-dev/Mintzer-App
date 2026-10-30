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

function stmtEnd(lines, start) {
  let depth = 0;
  let seen = false;
  for (let i = start; i < Math.min(lines.length, start + 40); i++) {
    for (const ch of lines[i]) {
      if (ch === '(') {
        depth++;
        seen = true;
      } else if (ch === ')') depth--;
    }
    if (seen && depth <= 0) return i;
  }
  return start;
}

let n = 0;
for (const file of walk('app/lib')) {
  const lines = fs.readFileSync(file, 'utf8').split(/\n/);
  let changed = false;
  for (let i = 0; i < lines.length; i++) {
    if (/^\s+m = \[S\.e\(/.test(lines[i])) {
      lines[i] = lines[i].replace('m =', 'final m =');
      changed = true;
      n++;
    }
    if (!/\bconst\b/.test(lines[i])) continue;
    const end = stmtEnd(lines, i);
    const chunk = lines.slice(i, end + 1).join('\n');
    if (!chunk.includes('S.e(')) continue;
    const before = lines[i];
    lines[i] = lines[i].replace(/\bconst\b/, '');
    if (lines[i] !== before) {
      changed = true;
      n++;
    }
  }
  if (changed) fs.writeFileSync(file, lines.join('\n'));
}
console.log('edits', n);
