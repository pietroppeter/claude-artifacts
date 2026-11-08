// Check code blocks the way a phone shows them (390px wide). Needs Playwright with Chromium.
//
//   node tools/phonecheck.js                 # every <slug>/index.html
//   node tools/phonecheck.js a/index.html    # given pages (works outside this repo too)
//
// Fails (exit 1) when, at 390px:
// - the page scrolls sideways (documentElement.scrollWidth > viewport),
// - a code block's font is outside 11-14px (nimib's `pre > code{font-size:1.2em}` wins over a
//   page's `pre code` rule because it comes later: use `body pre > code`),
// - a <pre> whose content is wider than it does not scroll (overflow-x not auto/scroll),
// - a <code> box with its own background/border is narrower than its text, so the text runs
//   past the box (give `pre > code` overflow-x:auto, which tools/codeblocks.py does),
// - a code block (not pre.nb-output / pre.out / pre.plain / code.language-text) has no highlighting.
const {chromium} = require('playwright');
const fs = require('fs'), path = require('path');

const root = path.resolve(__dirname, '..');
let files = process.argv.slice(2);
if (!files.length) files = fs.readdirSync(root).map(d => path.join(root, d, 'index.html')).filter(f => fs.existsSync(f));

(async () => {
  const browser = await chromium.launch();
  let bad = 0;
  for (const f of files) {
    const page = await browser.newPage({viewport: {width: 390, height: 844}});
    await page.goto('file://' + path.resolve(f), {waitUntil: 'load'}).catch(() => {});
    await page.waitForTimeout(300);
    const problems = await page.evaluate(() => {
      const out = [];
      const vw = window.innerWidth, sw = document.documentElement.scrollWidth;
      if (sw > vw) out.push(`page is ${sw}px wide at ${vw}px`);
      const first = el => (el.textContent.trim().split('\n')[0] || '').slice(0, 50);
      for (const pre of document.querySelectorAll('pre')) {
        const code = pre.querySelector(':scope > code') || pre;
        const cs = getComputedStyle(code), ps = getComputedStyle(pre);
        const fs = parseFloat(cs.fontSize);
        if (code.textContent.trim() && (fs > 14 || fs < 11)) out.push(`${fs}px code: ${first(code)}`);
        if (pre.scrollWidth > pre.clientWidth + 1 && !/auto|scroll/.test(ps.overflowX)) out.push(`pre does not scroll: ${first(pre)}`);
        if (code !== pre && cs.display !== 'inline' && code.scrollWidth > code.clientWidth + 1 && cs.overflowX === 'visible')
          out.push(`text runs past its box: ${first(code)}`);
        const output = pre.matches('.nb-output, .out, .plain') || /\blanguage-(text|plaintext|none|output)\b/.test(code.className);
        if (!output && code !== pre && code.textContent.trim() && !code.querySelector('span'))
          out.push(`not highlighted: ${first(code)}`);
      }
      return out;
    });
    const name = path.relative(process.cwd(), f);
    if (problems.length) { bad++; console.log(`✗ ${name}`); problems.slice(0, 8).forEach(p => console.log('    ' + p)); }
    else console.log(`✓ ${name}`);
    await page.close();
  }
  await browser.close();
  process.exit(bad ? 1 : 0);
})();
