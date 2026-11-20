const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const segmentedDir = path.resolve(__dirname, '..', 'research_working_dir', 'segmented_samples');

async function inspectUncertain() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const browser = await puppeteer.launch({
    executablePath: chromePath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  for (const sId of ['SAMPLE_009', 'SAMPLE_019']) {
    const imgPath = path.join(segmentedDir, `${sId}.jpg`);
    const base64 = fs.readFileSync(imgPath).toString('base64');

    const analysis = await page.evaluate(async (b64) => {
      return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => {
          const w = img.width;
          const h = img.height;
          const canvas = document.createElement('canvas');
          canvas.width = w;
          canvas.height = h;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0);

          const imgData = ctx.getImageData(0, 0, w, h);
          const data = imgData.data;

          // Compute horizontal profile
          const rowInk = new Float32Array(h);
          for (let y = 0; y < h; y++) {
            let count = 0;
            const offset = y * w * 4;
            for (let x = 0; x < w; x++) {
              const idx = offset + x * 4;
              const lum = 0.299 * data[idx] + 0.587 * data[idx + 1] + 0.114 * data[idx + 2];
              if (lum < 175) count++;
            }
            rowInk[y] = count / w;
          }

          // Search for local minima inside the middle 50%
          const midStart = Math.floor(h * 0.35);
          const midEnd = Math.floor(h * 0.65);
          let minVal = 1.0;
          let minIdx = -1;

          for (let y = midStart; y < midEnd; y++) {
            if (rowInk[y] < minVal) {
              minVal = rowInk[y];
              minIdx = y;
            }
          }

          resolve({ w, h, midMinVal: minVal, midMinIdx: minIdx });
        };
        img.src = `data:image/jpeg;base64,${b64}`;
      });
    }, base64);

    console.log(`[${sId}] (${analysis.w} x ${analysis.h}): Middle Valley at Y=${analysis.midMinIdx} (Ink=${(analysis.midMinVal * 100).toFixed(2)}%)`);
  }

  await browser.close();
}

inspectUncertain().catch(console.error);
