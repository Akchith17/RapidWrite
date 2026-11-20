const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const researchWorkDir = path.resolve(__dirname, '..', 'research_working_dir');
const segmentedDir = path.join(researchWorkDir, 'segmented_samples');

if (!fs.existsSync(segmentedDir)) {
  fs.mkdirSync(segmentedDir, { recursive: true });
}

// Target sentences for the two cohorts
const TARGET_C1 = "Students attend classes every day to gain knowledge and develop new skills. Regular practice helps them understand difficult concepts and perform better in exams.";
const TARGET_SCHOOL = "The quick brown fox jumps over the lazy dog while five boxing wizards quickly pack my black box.";

async function runSegmentation() {
  console.log('========================================================');
  console.log('  RAPID WRITE – Comprehensive Dataset Segmentation');
  console.log('========================================================\n');

  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const browser = await puppeteer.launch({
    executablePath: chromePath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();

  let globalSampleIndex = 1;
  const manifest = [];
  let totalPagesInspected = 0;
  let totalSamplesDetected = 0;
  let confidentSamplesCount = 0;
  let uncertainSamplesCount = 0;

  // 1. Process dataset c1 (12 pages)
  console.log('--- Inspecting & Segmenting: dataset c1.pdf (12 pages) ---');
  for (let p = 1; p <= 12; p++) {
    totalPagesInspected++;
    const imgName = `dataset_c1_page_${String(p).padStart(2, '0')}.jpg`;
    const imgPath = path.join(researchWorkDir, imgName);

    if (!fs.existsSync(imgPath)) {
      console.warn(`File not found: ${imgName}`);
      continue;
    }

    const base64 = fs.readFileSync(imgPath).toString('base64');

    const pageResult = await page.evaluate(async (b64, pageNum) => {
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

          // Compute horizontal projection profile
          const rowInk = new Float32Array(h);
          const leftMarginW = Math.floor(w * 0.12);
          const leftMarginInk = new Float32Array(h);

          for (let y = 0; y < h; y++) {
            let rowCount = 0;
            let leftCount = 0;
            const offset = y * w * 4;
            for (let x = 0; x < w; x++) {
              const idx = offset + x * 4;
              const r = data[idx];
              const g = data[idx + 1];
              const b = data[idx + 2];
              const lum = 0.299 * r + 0.587 * g + 0.114 * b;
              if (lum < 175) {
                rowCount++;
                if (x < leftMarginW) leftCount++;
              }
            }
            rowInk[y] = rowCount / w;
            leftMarginInk[y] = leftCount / leftMarginW;
          }

          // Smooth profile with 25px moving average
          const smooth = new Float32Array(h);
          const win = 25;
          for (let y = 0; y < h; y++) {
            let sum = 0, count = 0;
            for (let dy = -win; dy <= win; dy++) {
              const ny = y + dy;
              if (ny >= 0 && ny < h) {
                sum += rowInk[ny];
                count++;
              }
            }
            smooth[y] = sum / count;
          }

          // Segment continuous handwriting blocks
          const blocks = [];
          let inBlock = false;
          let startY = 0;
          let lowCount = 0;
          const inkThreshold = 0.012; // threshold for writing activity
          const valleyGap = Math.floor(h * 0.018); // ~50px whitespace gap between student entries

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
                  const blockH = endY - startY;
                  // Filter out tiny header artifacts (< 120px)
                  if (blockH > 140) {
                    blocks.push({ startY, endY, height: blockH });
                  }
                  inBlock = false;
                  lowCount = 0;
                }
              }
            }
          }
          if (inBlock && (h - 1 - startY) > 140) {
            blocks.push({ startY, endY: h - 1, height: h - 1 - startY });
          }

          // Refine blocks: If a block is unusually tall (> 900px), check for an internal whitespace valley (<0.005 ink)
          const refinedBlocks = [];
          for (const b of blocks) {
            if (b.height > 900) {
              // Search for minimum ink row in the middle 30% - 70% range
              const searchStart = b.startY + Math.floor(b.height * 0.30);
              const searchEnd = b.startY + Math.floor(b.height * 0.70);
              let minInk = 1.0;
              let splitY = -1;

              for (let y = searchStart; y <= searchEnd; y++) {
                if (smooth[y] < minInk) {
                  minInk = smooth[y];
                  splitY = y;
                }
              }

              if (splitY !== -1 && minInk < 0.008) {
                // Split cleanly into two separate student entries
                refinedBlocks.push({ startY: b.startY, endY: splitY - 5, height: (splitY - 5) - b.startY });
                refinedBlocks.push({ startY: splitY + 5, endY: b.endY, height: b.endY - (splitY + 5) });
                continue;
              }
            }
            refinedBlocks.push(b);
          }

          // Extract cropped images
          const crops = [];
          for (let i = 0; i < refinedBlocks.length; i++) {
            const b = refinedBlocks[i];
            const cCanvas = document.createElement('canvas');
            cCanvas.width = w;
            cCanvas.height = b.height;
            const cCtx = cCanvas.getContext('2d');
            cCtx.drawImage(canvas, 0, b.startY, w, b.height, 0, 0, w, b.height);

            // Compute ink pixel statistics within the crop
            const cropImgData = cCtx.getImageData(0, 0, w, b.height);
            let cropInk = 0;
            for (let p = 0; p < cropImgData.data.length; p += 4) {
              const lum = 0.299 * cropImgData.data[p] + 0.587 * cropImgData.data[p + 1] + 0.114 * cropImgData.data[p + 2];
              if (lum < 175) cropInk++;
            }

            crops.push({
              index: i + 1,
              startY: b.startY,
              endY: b.endY,
              height: b.height,
              width: w,
              inkDensity: cropInk / (w * b.height),
              dataUrl: cCanvas.toDataURL('image/jpeg', 0.85)
            });
          }

          resolve({ w, h, blocks: crops });
        };
        img.src = `data:image/jpeg;base64,${b64}`;
      });
    }, base64, p);

    console.log(`Page ${p}/12: Detected ${pageResult.blocks.length} student entries (Width: ${pageResult.w}px, Height: ${pageResult.h}px)`);

    for (const crop of pageResult.blocks) {
      totalSamplesDetected++;
      const sampleId = `SAMPLE_${String(globalSampleIndex).padStart(3, '0')}`;
      globalSampleIndex++;

      // Confidence assessment
      // If height is between 200px and 900px and ink density is reasonable -> CONFIDENT
      const isConfident = crop.height >= 180 && crop.height <= 950 && crop.inkDensity > 0.015;
      const status = isConfident ? 'CONFIDENT' : 'UNCERTAIN';

      if (isConfident) confidentSamplesCount++;
      else uncertainSamplesCount++;

      // Save crop image
      const base64Data = crop.dataUrl.replace(/^data:image\/jpeg;base64,/, '');
      const outPath = path.join(segmentedDir, `${sampleId}.jpg`);
      fs.writeFileSync(outPath, Buffer.from(base64Data, 'base64'));

      manifest.push({
        sampleId,
        sourcePdf: 'dataset c1.pdf',
        originalPageNumber: p,
        entryIndexOnPage: crop.index,
        targetSentence: TARGET_C1,
        ageGroupCohort: 'C1 Cohort (College / Senior)',
        boundingBox: {
          x: 0,
          y: crop.startY,
          width: crop.width,
          height: crop.height
        },
        inkDensity: crop.inkDensity,
        segmentationConfidence: status,
        notes: isConfident ? 'Clean visual boundary separation' : 'Unusual height or ink density, flagged for review'
      });
    }
  }

  // 2. Process dataset of school students (21 pages)
  console.log('\n--- Inspecting & Segmenting: dataset of school students.pdf (21 pages) ---');
  for (let p = 1; p <= 21; p++) {
    totalPagesInspected++;
    const imgName = `school_students_page_${String(p).padStart(2, '0')}.jpg`;
    const imgPath = path.join(researchWorkDir, imgName);

    if (!fs.existsSync(imgPath)) {
      console.warn(`File not found: ${imgName}`);
      continue;
    }

    const base64 = fs.readFileSync(imgPath).toString('base64');

    const pageResult = await page.evaluate(async (b64, pageNum) => {
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

          // Compute horizontal projection profile
          const rowInk = new Float32Array(h);
          for (let y = 0; y < h; y++) {
            let rowCount = 0;
            const offset = y * w * 4;
            for (let x = 0; x < w; x++) {
              const idx = offset + x * 4;
              const r = data[idx];
              const g = data[idx + 1];
              const b = data[idx + 2];
              const lum = 0.299 * r + 0.587 * g + 0.114 * b;
              if (lum < 175) rowCount++;
            }
            rowInk[y] = rowCount / w;
          }

          // Smooth profile with 30px moving average
          const smooth = new Float32Array(h);
          const win = 30;
          for (let y = 0; y < h; y++) {
            let sum = 0, count = 0;
            for (let dy = -win; dy <= win; dy++) {
              const ny = y + dy;
              if (ny >= 0 && ny < h) {
                sum += rowInk[ny];
                count++;
              }
            }
            smooth[y] = sum / count;
          }

          // Segment continuous handwriting blocks
          const blocks = [];
          let inBlock = false;
          let startY = 0;
          let lowCount = 0;
          const inkThreshold = 0.010;
          const valleyGap = Math.floor(h * 0.022); // gap between students

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
                  const blockH = endY - startY;
                  if (blockH > 130) {
                    blocks.push({ startY, endY, height: blockH });
                  }
                  inBlock = false;
                  lowCount = 0;
                }
              }
            }
          }
          if (inBlock && (h - 1 - startY) > 130) {
            blocks.push({ startY, endY: h - 1, height: h - 1 - startY });
          }

          const refinedBlocks = [];
          for (const b of blocks) {
            if (b.height > 850) {
              const searchStart = b.startY + Math.floor(b.height * 0.30);
              const searchEnd = b.startY + Math.floor(b.height * 0.70);
              let minInk = 1.0;
              let splitY = -1;

              for (let y = searchStart; y <= searchEnd; y++) {
                if (smooth[y] < minInk) {
                  minInk = smooth[y];
                  splitY = y;
                }
              }

              if (splitY !== -1 && minInk < 0.008) {
                refinedBlocks.push({ startY: b.startY, endY: splitY - 5, height: (splitY - 5) - b.startY });
                refinedBlocks.push({ startY: splitY + 5, endY: b.endY, height: b.endY - (splitY + 5) });
                continue;
              }
            }
            refinedBlocks.push(b);
          }

          const crops = [];
          for (let i = 0; i < refinedBlocks.length; i++) {
            const b = refinedBlocks[i];
            const cCanvas = document.createElement('canvas');
            cCanvas.width = w;
            cCanvas.height = b.height;
            const cCtx = cCanvas.getContext('2d');
            cCtx.drawImage(canvas, 0, b.startY, w, b.height, 0, 0, w, b.height);

            const cropImgData = cCtx.getImageData(0, 0, w, b.height);
            let cropInk = 0;
            for (let p = 0; p < cropImgData.data.length; p += 4) {
              const lum = 0.299 * cropImgData.data[p] + 0.587 * cropImgData.data[p + 1] + 0.114 * cropImgData.data[p + 2];
              if (lum < 175) cropInk++;
            }

            crops.push({
              index: i + 1,
              startY: b.startY,
              endY: b.endY,
              height: b.height,
              width: w,
              inkDensity: cropInk / (w * b.height),
              dataUrl: cCanvas.toDataURL('image/jpeg', 0.85)
            });
          }

          resolve({ w, h, blocks: crops });
        };
        img.src = `data:image/jpeg;base64,${b64}`;
      });
    }, base64, p);

    console.log(`Page ${p}/21: Detected ${pageResult.blocks.length} student entries (Width: ${pageResult.w}px, Height: ${pageResult.h}px)`);

    for (const crop of pageResult.blocks) {
      totalSamplesDetected++;
      const sampleId = `SAMPLE_${String(globalSampleIndex).padStart(3, '0')}`;
      globalSampleIndex++;

      const isConfident = crop.height >= 160 && crop.height <= 900 && crop.inkDensity > 0.012;
      const status = isConfident ? 'CONFIDENT' : 'UNCERTAIN';

      if (isConfident) confidentSamplesCount++;
      else uncertainSamplesCount++;

      const base64Data = crop.dataUrl.replace(/^data:image\/jpeg;base64,/, '');
      const outPath = path.join(segmentedDir, `${sampleId}.jpg`);
      fs.writeFileSync(outPath, Buffer.from(base64Data, 'base64'));

      manifest.push({
        sampleId,
        sourcePdf: 'dataset of school students.pdf',
        originalPageNumber: p,
        entryIndexOnPage: crop.index,
        targetSentence: TARGET_SCHOOL,
        ageGroupCohort: 'School Students Cohort (Elementary / Middle School)',
        boundingBox: {
          x: 0,
          y: crop.startY,
          width: crop.width,
          height: crop.height
        },
        inkDensity: crop.inkDensity,
        segmentationConfidence: status,
        notes: isConfident ? 'Clean visual boundary separation' : 'Unusual height or ink density, flagged for review'
      });
    }
  }

  await browser.close();

  // Save the complete segmentation manifest
  const manifestPath = path.join(researchWorkDir, 'dataset_segmentation_manifest.json');
  fs.writeFileSync(manifestPath, JSON.stringify({
    metadata: {
      generatedAt: new Date().toISOString(),
      totalPagesInspected,
      totalSamplesDetected,
      confidentSamplesCount,
      uncertainSamplesCount
    },
    samples: manifest
  }, null, 2));

  console.log('\n======================================================');
  console.log('  DATASET SEGMENTATION SUMMARY');
  console.log('======================================================');
  console.log(`Total Pages Inspected:          ${totalPagesInspected}`);
  console.log(`Total Student Samples Detected: ${totalSamplesDetected}`);
  console.log(`Successfully Segmented:         ${confidentSamplesCount} (${((confidentSamplesCount/totalSamplesDetected)*100).toFixed(1)}%)`);
  console.log(`Uncertain / Flagged for Review: ${uncertainSamplesCount} (${((uncertainSamplesCount/totalSamplesDetected)*100).toFixed(1)}%)`);
  console.log(`Manifest written to:            ${manifestPath}`);
  console.log(`Segmented image files stored in: ${segmentedDir}`);
}

runSegmentation().catch(console.error);
