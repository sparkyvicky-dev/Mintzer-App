const fs = require('fs');
const path = require('path');

const svgPath = 'D:/dev/mintzer-app/assets/logos/mintzer-mark-circle.svg';
const s = fs.readFileSync(svgPath, 'utf8');
const stripped = s.replace(/data:image\/png;base64,[A-Za-z0-9+/=]+/g, '...');
console.log(stripped);

const m = s.match(/xlink:href="data:image\/png;base64,([^"]+)"/);
if (!m) throw new Error('no png');
const buf = Buffer.from(m[1], 'base64');
fs.writeFileSync('D:/dev/mintzer-app/app/assets/logos/mintzer-mark-glyph.png', buf);
console.log('glyph', buf.length);
