const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const researchWorkDir = path.resolve(__dirname, '..', 'research_working_dir');
const inspectOutDir = path.resolve(__dirname, '..', 'research_working_dir', 'inspection_previews');

if (!fs.existsSync(inspectOutDir)) {
  fs.mkdirSync(inspectOutDir, { recursive: true });
}

async function run() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const browser = await puppeteer.launch({
    executablePath: chromePath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  // Test one page from dataset c1 and one from school students
  const pagesToInspect = [
    { name: 'dataset_c1_page_01.jpg', label: 'dataset_c1_p01' },
    { name: 'dataset_c1_page_02.jpg', label: 'dataset_c1_p02' },
    { name: 'school_students_page_01.jpg', label: 'school_p01' },
    { name: 'school_students_page_02.jpg', label: 'school_p02' }
  ];

  for (const item of pagesToInspect) {
    const imgPath = path.join(researchWorkDir, item.name);
    if (!fs.existsSync(imgPath)) continue;

    const base64 = fs.readFileSync(imgPath).toString('base64');

    const result = await page.evaluate(async (b64, label) => {
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

          // 1. Calculate row ink density
          const rowDensities = new Float32Array(h);
          const leftMarginDensities = new Float32Array(h);
          const leftMarginW = Math.floor(w * 0.12); // left 12% for entry numbering like "1.", "2."

          for (let y = 0; y < h; y++) {
            let rowInk = 0;
            let leftInk = 0;
            const offset = y * w * 4;
            for (let x = 0; x < w; x++) {
              const idx = offset + x * 4;
              const r = data[idx];
              const g = data[idx + 1];
              const b = data[idx + 2];
              const lum = 0.299 * r + 0.587 * g + 0.114 * b;
              if (lum < 175) {
                rowInk++;
                if (x < leftMarginW) leftInk++;
              }
            }
            rowDensities[y] = rowInk / w;
            leftMarginDensities[y] = leftInk / leftMarginW;
          }

          // 2. Smooth density with moving average window (25px)
          const smooth = new Float32Array(h);
          const win = 25;
          for (let y = 0; y < h; y++) {
            let sum = 0;
            let count = 0;
            for (let dy = -win; dy <= win; dy++) {
              const ny = y + dy;
              if (ny >= 0 && ny < h) {
                sum += rowDensities[ny];
                count++;
              }
            }
            smooth[y] = sum / count;
          }

          // 3. Find distinct handwriting blocks (entry candidates)
          // A student's sample is a continuous block of writing spanning multiple lines
          // Separated by wide valleys (> 60px of low ink density < 0.012)
          const blocks = [];
          let inBlock = false;
          let startY = 0;
          let lowCount = 0;
          const inkThreshold = 0.015;
          const valleyGap = Math.floor(h * 0.02); // ~50-70px gap between students

          for (let y = 0; y < h; y++) {
            if (smooth[y] > inkThreshold) {
              if (!inBlock) {
                inBlock = true;
                startY = y;
              }
              lowCount = 0;
            } else {
              if (inBlock) {
                lowCount++;
                if (lowCount > valleyGap) {
                  const endY = y - lowCount;
                  if (endY - startY > Math.floor(h * 0.03)) { // at least 3% page height
                    blocks.push({ startY, endY, height: endY - startY });
                  }
                  inBlock = false;
                  lowCount = 0;
                }
              }
            }
          }
          if (inBlock && (h - 1 - startY) > Math.floor(h * 0.03)) {
            blocks.push({ startY, endY: h - 1, height: h - 1 - startY });
          }

          // Crop and export thumbnails of each block as base64
          const crops = [];
          for (let i = 0; i < blocks.length; i++) {
            const b = blocks[i];
            const cropH = b.height;
            const cCanvas = document.createElement('canvas');
            cCanvas.width = Math.min(800, w);
            const scale = cCanvas.width / w;
            cCanvas.height = Math.round(cropH * scale);
            const cCtx = cCanvas.getContext('2d');
            cCtx.drawImage(canvas, 0, b.startY, w, cropH, 0, 0, cCanvas.width, cCanvas.height);
            crops.push({
              index: i + 1,
              startY: b.startY,
              endY: b.endY,
              height: b.height,
              dataUrl: cCanvas.toDataURL('image/jpeg', 0.7)
            });
          }

          resolve({
            w,
            h,
            blockCount: blocks.length,
            blocks,
            crops
          });
        };
        img.src = `data:image/jpeg;base64,${b64}`;
      });
    }, base64, item.label);

    console.log(`\n======================================================`);
    console.log(`PAGE: ${item.name} (${result.w} x ${result.h})`);
    console.log(`Detected Student Entries: ${result.blockCount}`);
    console.log(`======================================================`);

    result.crops.forEach(c => {
      console.log(`  Entry #${c.index}: Y=${c.startY} to Y=${c.endY} (height=${c.height}px)`);
      const base64Data = c.dataUrl.replace(/^data:image\/jpeg;base64,/, '');
      const outPath = path.join(inspectOutDir, `${item.label}_entry_${c.index}.jpg`);
      fs.writeFileSync(outPath, Buffer.from(base64Data, 'base64'));
    });
  }

  await browser.close();
  console.log(`\nInspection previews saved to: ${inspectOutDir}`);
}

run().catch(console.error);
