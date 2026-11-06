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
  const out = 'download/screens';
  const fs = require('fs');
  fs.mkdirSync(out, { recursive: true });

  await page.goto(base, { waitUntil: 'networkidle' });
  await page.waitForTimeout(700);
  await page.screenshot({ path: out + '/01_splash.png' });

  // ждём перехода в меню (сплеш 2.2с)
  await page.waitForTimeout(2600);
  await page.screenshot({ path: out + '/02_menu.png', fullPage: false });

  // координаты кнопок меню (новая themed-компоновка):
  // BigButton: С компьютером ~y364, Два игрока ~y446, Сетевая игра ~y528
  // SmallMenu row: Правила (x140) / Настройки (x272) ~y612
  const cx = 206;

  // Правила — SmallMenu слева (~y 612, x 140)
  await page.mouse.click(140, 612);
  await page.waitForTimeout(700);
  await page.screenshot({ path: out + '/03_rules.png' });
  await page.mouse.click(20, 45);
  await page.waitForTimeout(700);

  // Настройки — SmallMenu справа (~y 612, x 272)
  await page.mouse.click(272, 612);
  await page.waitForTimeout(700);
  await page.screenshot({ path: out + '/04_settings_top.png' });
  await page.mouse.wheel(0, 1500);
  await page.waitForTimeout(400);
  await page.screenshot({ path: out + '/04b_settings_bottom.png' });
  await page.mouse.click(20, 45);
  await page.waitForTimeout(700);

  // Два игрока — BigButton (~y 446)
  await page.mouse.click(cx, 446);
  await page.waitForTimeout(1200);
  await page.screenshot({ path: out + '/05_game_empty.png' });
  // поставим несколько камней по диагонали от центра доски
  const bx = 206, by = 470;
  for (const [dx, dy] of [[0,0],[40,40],[-40,40],[40,-40],[-80,0],[0,80]]) {
    await page.mouse.click(bx+dx, by+dy);
    await page.waitForTimeout(350);
  }
  await page.waitForTimeout(500);
  await page.screenshot({ path: out + '/06_game_played.png' });

  await browser.close();
  console.log('done');
})();
