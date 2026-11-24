const { chromium } = require('playwright');
(async () => {
  const out = { exp: [], hero: [] };
  const browser = await chromium.launch();
  const page = await browser.newPage({ userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' });
  await page.goto('https://mapleidleindex.com/growth/#exp', { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForFunction(() => !document.getElementById('exp-sweep-stage')?.disabled, null, { timeout: 30000 });
  for (const st of [1, 50, 100, 140, 150]) {
    await page.evaluate(v => { const i = document.getElementById('exp-sweep-stage'); i.value = v; i.dispatchEvent(new Event('input', { bubbles: true })); }, String(st));
    await page.waitForTimeout(150);
    out.exp.push({ stage: st, exact: await page.textContent('#exp-sweep-exact') });
  }
  await page.goto('https://maplestoryidle.info/hero-token-calculator.html', { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForTimeout(1500);
  const opts = await page.$$eval('[data-training-stage] option', os => os.map(o => o.value)).catch(() => []);
  out.heroStageOptions = opts.length;
  for (const st of ['1', '10', '100', '140']) {
    try {
      const tag = await page.$eval('[data-training-stage]', e => e.tagName);
      if (tag === 'SELECT') await page.selectOption('[data-training-stage]', st);
      else { await page.fill('[data-training-stage]', st); await page.dispatchEvent('[data-training-stage]', 'input'); await page.dispatchEvent('[data-training-stage]', 'change'); }
      const sync = await page.$('[data-sync-run]'); if (sync) { const t = await sync.getAttribute('type'); if (t === 'checkbox') { if (!(await sync.isChecked())) await sync.check(); } else { await sync.click(); } }
      await page.waitForTimeout(300);
      out.hero.push({ stage: st, tokensPerRun: await page.$eval('[data-tokens-per-run]', e => e.value ?? e.textContent), note: (await page.textContent('[data-training-note]').catch(()=>null))?.trim() });
    } catch (e) { out.hero.push({ stage: st, error: String(e).slice(0, 200) }); }
  }
  await browser.close();
  console.log(JSON.stringify(out, null, 1));
})().catch(e => { console.error(e); process.exit(1); });
