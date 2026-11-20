const puppeteer = require('puppeteer-core');
const fs = require('fs');

async function test() {
  const chromePaths = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Users\\akchi\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe'
  ];

  let execPath = chromePaths.find(p => fs.existsSync(p));
  console.log('Chrome path:', execPath);

  if (!execPath) {
    console.log('Chrome not found in standard paths.');
    return;
  }

  const browser = await puppeteer.launch({
    executablePath: execPath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  const res = await page.evaluate(() => 2 + 2);
  console.log('Evaluation succeeded:', res);
  await browser.close();
}

test().catch(console.error);

