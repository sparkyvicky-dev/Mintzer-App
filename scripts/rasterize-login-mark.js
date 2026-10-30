const fs = require('fs');
const { createCanvas, loadImage } = (() => {
  try { return require('canvas'); } catch { return {}; }
})();

const svgPath = 'D:/dev/mintzer-app/assets/logos/mintzer-mark-circle.svg';
const outPng = 'D:/dev/mintzer-app/app/assets/logos/mintzer-mark-circle.png';
const outGlyph = 'D:/dev/mintzer-app/app/assets/logos/mintzer-mark-glyph.png';

const s = fs.readFileSync(svgPath, 'utf8');
const m = s.match(/xlink:href="data:image\/png;base64,([^"]+)"/);
if (!m) throw new Error('no embedded png');
const buf = Buffer.from(m[1], 'base64');
fs.writeFileSync(outGlyph, buf);
console.log('glyph bytes', buf.length);

// Pattern attrs from SVG (website mark crop into circle)
const patternMatch = s.match(/<pattern[^>]*id="pattern0[^"]*"[^>]*>/);
console.log('pattern tag', patternMatch && patternMatch[0]);
const imageMatch = s.match(/<image[^>]*\/>|<image[^>]*>[\s\S]*?<\/image>/);
console.log('image tag snippet', imageMatch && imageMatch[0].slice(0, 300).replace(/xlink:href="data:[^"]+"/, 'xlink:href="..."'));

const widthMatch = s.match(/width="([\d.]+)".*height="([\d.]+)".*xlink:href=/);
// Parse image placement inside pattern
const im = s.match(/<image[^>]*width="([\d.]+)"[^>]*height="([\d.]+)"[^>]*xlink:href=/)
  || s.match(/<image[^>]*height="([\d.]+)"[^>]*width="([\d.]+)"/);
console.log('image dims match', im && im.slice(1));

const useCanvas = !!createCanvas;
if (!useCanvas) {
  console.log('no node-canvas — will use pure sharp/fallback next');
  process.exit(0);
}
