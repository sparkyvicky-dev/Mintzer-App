const fs = require('fs');
const { marked } = require('marked');
const path = require('path');

const root = path.join(__dirname, '..');
const mdPath = path.join(root, 'docs/COMPLETE-DECISIONS-LOG.md');
const outDocs = path.join(root, 'docs/COMPLETE-DECISIONS-LOG.html');
const outMockups = path.join(root, 'assets/mockups/mintzer-decisions-log.html');

const md = fs.readFileSync(mdPath, 'utf8');

const tocItems = [];
let idx = 0;
const mdForToc = md.replace(/^## (.+)$/gm, (_, title) => {
  const id = 's' + ++idx;
  tocItems.push({ id, title: title.replace(/^\d+\.\s*/, '') });
  return `## <span id="${id}"></span>${title}`;
});

const body = marked.parse(mdForToc);
const tocHtml = tocItems.map(i =>
  `<a href="#${i.id}">${i.title}</a>`
).join('\n');

const shell = (extraTopLinks) => `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Mintzer — Everything we discussed</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body {
      font-family: 'Segoe UI', Roboto, system-ui, sans-serif;
      background: #F8F9FA; color: #202124; line-height: 1.55;
    }
    .topbar {
      position: sticky; top: 0; z-index: 100;
      background: #1A73E8; color: #fff; padding: 12px 20px;
      display: flex; flex-wrap: wrap; align-items: center; gap: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,.15);
    }
    .topbar h1 { font-size: 16px; font-weight: 700; flex: 1; min-width: 200px; }
    .topbar a {
      color: #fff; text-decoration: none; font-size: 12px; font-weight: 600;
      background: rgba(255,255,255,.2); padding: 6px 12px; border-radius: 20px;
    }
    .topbar a:hover { background: rgba(255,255,255,.35); }
    .layout { display: flex; max-width: 1200px; margin: 0 auto; min-height: calc(100vh - 52px); }
    .sidebar {
      width: 260px; flex-shrink: 0; background: #fff; border-right: 1px solid #E8EAED;
      padding: 16px 12px; position: sticky; top: 52px; height: calc(100vh - 52px);
      overflow-y: auto; display: none;
    }
    .sidebar h2 { font-size: 11px; text-transform: uppercase; color: #5F6368; margin-bottom: 10px; letter-spacing: .5px; }
    .sidebar a {
      display: block; font-size: 12px; color: #1A73E8; text-decoration: none;
      padding: 6px 8px; border-radius: 6px; margin-bottom: 2px;
    }
    .sidebar a:hover { background: #E8F0FE; }
    .main {
      flex: 1; min-width: 0; padding: 24px 20px 60px;
      background: #fff; margin: 16px; border-radius: 12px;
      border: 1px solid #E8EAED; box-shadow: 0 1px 4px rgba(0,0,0,.06);
    }
    .main :first-child { margin-top: 0; }
    .main h1 { font-size: 26px; color: #1A73E8; margin-bottom: 12px; }
    .main h2 {
      font-size: 18px; color: #1A73E8; margin: 28px 0 12px; padding-bottom: 6px;
      border-bottom: 2px solid #E8F0FE; scroll-margin-top: 70px;
    }
    .main h3 { font-size: 14px; margin: 16px 0 8px; color: #202124; }
    .main p { margin: 8px 0; font-size: 14px; }
    .main ul, .main ol { margin: 8px 0 12px 20px; font-size: 14px; }
    .main li { margin: 4px 0; }
    .main table {
      width: 100%; border-collapse: collapse; margin: 12px 0; font-size: 13px;
    }
    .main th, .main td {
      border: 1px solid #E8EAED; padding: 8px 10px; text-align: left; vertical-align: top;
    }
    .main th { background: #F8F9FA; font-weight: 600; }
    .main tr:nth-child(even) td { background: #FAFBFC; }
    .main code {
      background: #F1F3F4; padding: 1px 5px; border-radius: 4px; font-size: 12px;
    }
    .main pre {
      background: #F8F9FA; border: 1px solid #E8EAED; border-radius: 8px;
      padding: 14px; overflow-x: auto; font-size: 12px; margin: 12px 0;
    }
    .main pre code { background: none; padding: 0; }
    .main a { color: #1A73E8; }
    .main hr { border: none; border-top: 1px solid #E8EAED; margin: 24px 0; }
    .main strong { font-weight: 600; }
    .banner {
      background: #E8F0FE; border: 1px solid #D2E3FC; border-radius: 10px;
      padding: 14px 16px; margin-bottom: 20px; font-size: 13px;
    }
    .banner b { color: #1A73E8; }
    @media (min-width: 900px) { .sidebar { display: block; } .main { margin: 16px 16px 16px 0; } }
    @media print {
      .topbar, .sidebar { display: none; }
      .main { margin: 0; box-shadow: none; border: none; }
    }
  </style>
</head>
<body>
  <header class="topbar">
    <h1>Mintzer — Everything we discussed</h1>
    ${extraTopLinks}
  </header>
  <div class="layout">
    <nav class="sidebar">
      <h2>Jump to section</h2>
      ${tocHtml}
    </nav>
    <article class="main">
      <div class="banner">
        <b>Master checklist</b> — all screens, rules, overlays, and locked decisions.
        Use sidebar (desktop) to jump. <b>Ctrl+P</b> to save as PDF.
      </div>
      ${body}
    </article>
  </div>
</body>
</html>`;

const topLinks = `
    <a href="../assets/mockups/mintzer-app-demo.html">▶ Try app demo</a>
    <a href="../assets/mockups/home-samples.html">Home mockup</a>
    <a href="design/FOR-DESIGNER.md">Designer MD</a>`;

const topLinksMockups = `
    <a href="mintzer-app-demo.html">▶ Try app demo</a>
    <a href="home-samples.html">Home mockup</a>`;

fs.writeFileSync(outDocs, shell(topLinks), 'utf8');
fs.writeFileSync(outMockups, shell(topLinksMockups), 'utf8');
console.log('Written:', outDocs);
console.log('Written:', outMockups);
console.log('Open either file in Chrome — double-click to view.');
