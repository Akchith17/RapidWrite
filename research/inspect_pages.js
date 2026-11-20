const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const researchWorkDir = path.join(__dirname, '..', 'research_working_dir');

async function inspectPages() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const os = require('os');
  const tempUserDir = path.join(os.tmpdir(), `pup_cv_${Date.now()}`);

  const browser = await puppeteer.launch({
    executablePath: chromePath,
    headless: 'new',
    userDataDir: tempUserDir,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  // Test inspecting a few pages from both datasets
  const testImages = [
    'dataset_c1_page_01.jpg',
    'dataset_c1_page_02.jpg',
    'school_students_page_01.jpg',
    'school_students_page_02.jpg',
    'school_students_page_05.jpg',
  ];

  for (const imgName of testImages) {
    const imgPath = path.join(researchWorkDir, imgName);
    if (!fs.existsSync(imgPath)) continue;

    const base64 = fs.readFileSync(imgPath).toString('base64');
    const dataUri = `data:image/jpeg;base64,${base64}`;

    const info = await page.evaluate(async (src, name) => {
      return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          canvas.width = img.width;
          canvas.height = img.height;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0);

          const imgData = ctx.getImageData(0, 0, img.width, img.height);
          const data = imgData.data;

          // Grayscale and horizontal projection profile (row ink density)
          const rowInk = new Float32Array(img.height);
          for (let y = 0; y < img.height; y++) {
            let inkCount = 0;
            const rowOffset = y * img.width * 4;
            for (let x = 0; x < img.width; x++) {
              const idx = rowOffset + x * 4;
              const r = data[idx];
              const g = data[idx + 1];
              const b = data[idx + 2];
              const lum = 0.299 * r + 0.587 * g + 0.114 * b;
              if (lum < 180) { // threshold for ink
                inkCount++;
              }
            }
            rowInk[y] = inkCount / img.width;
          }

          // Sample vertical projection profile in left 15% (where entry numbers 1, 2, 3.. usually are)
          const leftMarginWidth = Math.floor(img.width * 0.15);
          const leftRowInk = new Float32Array(img.height);
          for (let y = 0; y < img.height; y++) {
            let inkCount = 0;
            const rowOffset = y * img.width * 4;
            for (let x = 0; x < leftMarginWidth; x++) {
              const idx = rowOffset + x * 4;
              const r = data[idx];
              const g = data[idx + 1];
              const b = data[idx + 2];
              const lum = 0.299 * r + 0.587 * g + 0.114 * b;
              if (lum < 180) inkCount++;
            }
            leftRowInk[y] = inkCount / leftMarginWidth;
          }

          // Find distinct horizontal bands of high density separated by whitespace gaps (>15px)
          const bands = [];
          let inBand = false;
          let bandStart = 0;
          let gapCount = 0;
          const threshold = 0.015; // >1.5% ink

          for (let y = 0; y < img.height; y++) {
            if (rowInk[y] > threshold) {
              if (!inBand) {
                inBand = true;
                bandStart = y;
              }
              gapCount = 0;
            } else {
              if (inBand) {
                gapCount++;
                if (gapCount > Math.floor(img.height * 0.015)) { // whitespace gap
                  bands.push({ start: bandStart, end: y - gapCount, height: (y - gapCount) - bandStart });
                  inBand = false;
                  gapCount = 0;
                }
              }
            }
          }
          if (inBand) {
            bands.push({ start: bandStart, end: img.height - 1, height: (img.height - 1) - bandStart });
          }

          resolve({
            name,
            width: img.width,
            height: img.height,
            bandCount: bands.length,
            bands: bands.slice(0, 15)
          });
        };
        img.src = src;
      });
    }, dataUri, imgName);

    console.log(`\n--- Page: ${info.name} (${info.width} x ${info.height}) ---`);
    console.log(`Detected ink bands: ${info.bandCount}`);
    info.bands.forEach((b, i) => {
      console.log(`  Band ${i + 1}: Y=${b.start} to Y=${b.end} (height: ${b.height}px)`);
    });
  }

  await browser.close();
}

inspectPages().catch(console.error);
