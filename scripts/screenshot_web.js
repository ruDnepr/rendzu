const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    executablePath: '/home/z/.cache/ms-playwright/chromium-1200/chrome-linux64/chrome',
    args: ['--no-sandbox', '--disable-gpu', '--force-color-profile=srgb'],
  });
  const ctx = await browser.newContext({
    viewport: { width: 412, height: 915 },
    deviceScaleFactor: 2,
  });
  const page = await ctx.newPage();
  const base = 'http://localhost:8765/';
  const out = '/tmp/render';
  const fs = require('fs');
  fs.mkdirSync(out, { recursive: true });

  await page.goto(base, { waitUntil: 'networkidle' });
  await page.waitForTimeout(700);
  await page.screenshot({ path: out + '/01_splash.png' });

  // ждём перехода в меню (сплеш 2.2с)
  await page.waitForTimeout(2600);
  await page.screenshot({ path: out + '/02_menu.png', fullPage: false });

  // координаты кнопок меню (center x=206). С новой компоновкой:
  // кнопки в нижней половине: ~y = 369, 451, 533, 615, 697
  const cx = 206;

  // Правила — 4-я кнопка (~y 615)
  await page.mouse.click(cx, 615);
  await page.waitForTimeout(700);
  await page.screenshot({ path: out + '/03_rules.png' });
  await page.mouse.click(20, 45); // назад (стрелка в аппбаре)
  await page.waitForTimeout(700);

  // Настройки — 5-я кнопка (~y 697)
  await page.mouse.click(cx, 697);
  await page.waitForTimeout(700);
  await page.screenshot({ path: out + '/04_settings_top.png' });
  await page.mouse.wheel(0, 1500);
  await page.waitForTimeout(400);
  await page.screenshot({ path: out + '/04b_settings_bottom.png' });
  await page.mouse.click(20, 45);
  await page.waitForTimeout(700);

  // Два игрока — 2-я кнопка (~y 451) → игра
  await page.mouse.click(cx, 451);
  await page.waitForTimeout(1200);
  await page.screenshot({ path: out + '/05_game_empty.png' });
  // поставим несколько камней по диагонали от центра доски
  const bx = 206, by = 470;
  for (const [dx, dy] of [[0,0],[38,38],[-38,38],[38,-38],[-76,0]]) {
    await page.mouse.click(bx+dx, by+dy);
    await page.waitForTimeout(350);
  }
  await page.waitForTimeout(500);
  await page.screenshot({ path: out + '/06_game_played.png' });

  await browser.close();
  console.log('done');
})();
