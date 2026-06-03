const fs = require('fs');
const { marked } = require('marked');
const path = require('path');

const mdPath = path.join(__dirname, '../docs/design/MINTZER-UI-DESIGN-BRIEF.md');
const htmlPath = path.join(__dirname, '../docs/design/MINTZER-UI-DESIGN-BRIEF.html');

const md = fs.readFileSync(mdPath, 'utf8');
const body = marked.parse(md);

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Mintzer UI Design Brief</title>
  <style>
    @page { margin: 18mm 16mm; size: A4; }
    * { box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      font-size: 10.5pt;
      line-height: 1.45;
      color: #202124;
      max-width: 210mm;
      margin: 0 auto;
      padding: 12mm;
    }
    h1 { font-size: 22pt; color: #1A73E8; page-break-before: always; margin-top: 0; }
    h1:first-of-type { page-break-before: avoid; }
    h2 { font-size: 14pt; color: #1A73E8; margin-top: 1.2em; border-bottom: 1px solid #E8EAED; padding-bottom: 4px; page-break-after: avoid; }
    h3 { font-size: 11.5pt; margin-top: 1em; page-break-after: avoid; }
    table { width: 100%; border-collapse: collapse; margin: 8px 0 12px; font-size: 9.5pt; page-break-inside: avoid; }
    th, td { border: 1px solid #E8EAED; padding: 6px 8px; text-align: left; vertical-align: top; }
    th { background: #F8F9FA; font-weight: 600; }
    code, pre { background: #F8F9FA; font-size: 9pt; }
    pre { padding: 10px; overflow-x: auto; border: 1px solid #E8EAED; page-break-inside: avoid; }
    blockquote { border-left: 3px solid #1A73E8; margin: 8px 0; padding: 4px 12px; color: #5F6368; }
    hr { border: none; border-top: 1px solid #E8EAED; margin: 16px 0; }
    ul, ol { padding-left: 1.4em; }
    li { margin: 4px 0; }
    .cover { text-align: center; padding: 40mm 0 20mm; page-break-after: always; }
    .cover h1 { page-break-before: avoid; font-size: 28pt; border: none; }
    .cover p { color: #5F6368; font-size: 12pt; }
    @media print {
      body { padding: 0; }
      a { color: inherit; text-decoration: none; }
    }
  </style>
</head>
<body>
<div class="cover">
  <h1>Mintzer Mobile App</h1>
  <p><strong>UI Design Brief</strong> · Version 1.0 · June 2026</p>
  <p>Mintzer Technologies Pvt Ltd</p>
  <p style="margin-top:24px;font-size:10pt;">Print this document: Ctrl+P → Save as PDF</p>
</div>
${body}
</body>
</html>`;

fs.writeFileSync(htmlPath, html, 'utf8');
console.log('Written:', htmlPath);
