const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');
const CvPipeline = require('./cv_pipeline');
const AestheticEngine = require('./aesthetic_engine');

const researchWorkDir = path.resolve(__dirname, '..', 'research_working_dir');

async function runBatch() {
  console.log('========================================================');
  console.log('  RAPID WRITE – Batch Research Dataset Processing');
  console.log('========================================================');

  const chromePaths = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Users\\akchi\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe'
  ];
  const execPath = chromePaths.find(p => fs.existsSync(p));

  if (!execPath) {
    throw new Error('Chrome binary not found');
  }

  const browser = await puppeteer.launch({
    executablePath: execPath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  const allResults = [];

  // 1. Process dataset_c1 (12 pages, 62 student samples)
  console.log('\n--- Processing dataset c1 (Lined paper, multiple samples/page) ---');
  const targetC1 = "Students attend classes every day to gain knowledge and develop new skills. Regular practice helps them understand difficult concepts and perform better in exams.";

  // Sample counts per page for dataset_c1
  const c1SampleCounts = [5, 6, 6, 6, 6, 3, 5, 5, 5, 5, 5, 5];

  for (let pageNum = 1; pageNum <= 12; pageNum++) {
    const imgName = `dataset_c1_page_${String(pageNum).padStart(2, '0')}.jpg`;
    const imgPath = path.join(researchWorkDir, imgName);

    if (!fs.existsSync(imgPath)) {
      console.warn(`File not found: ${imgName}`);
      continue;
    }

    const imgBase64 = fs.readFileSync(imgPath).toString('base64');
    const sampleCount = c1SampleCounts[pageNum - 1] || 5;

    // Load image into canvas in headless Chrome
    const pageData = await page.evaluate(async (b64, sCount) => {
      return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => {
          // Scale down slightly for ultra-fast processing while preserving high resolution (max 1200px width)
          const scale = Math.min(1.0, 1200 / img.width);
          const w = Math.round(img.width * scale);
          const h = Math.round(img.height * scale);

          const canvas = document.createElement('canvas');
          canvas.width = w;
          canvas.height = h;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, w, h);

          // Divide page into vertical bands for each sample
          const bandHeight = Math.floor(h / sCount);
          const sampleBands = [];

          for (let s = 0; s < sCount; s++) {
            const yStart = s * bandHeight;
            const subImgData = ctx.getImageData(0, yStart, w, bandHeight);
            sampleBands.push({
              sampleIndex: s + 1,
              width: w,
              height: bandHeight,
              yOffset: yStart,
              data: Array.from(subImgData.data)
            });
          }
          resolve(sampleBands);
        };
        img.src = `data:image/jpeg;base64,${b64}`;
      });
    }, imgBase64, sampleCount);

    // Process each student sample band
    for (const band of pageData) {
      const sampleId = `c1_p${String(pageNum).padStart(2, '0')}_s${band.sampleIndex}`;
      const imgDataObj = { width: band.width, height: band.height, data: new Uint8ClampedArray(band.data) };

      // Preprocessing
      const grayObj = CvPipeline.toGrayscale(imgDataObj);
      const normObj = CvPipeline.normalizeIllumination(grayObj, 32);
      const binObj = CvPipeline.otsuBinarize(normObj);
      const lines = CvPipeline.segmentLines(binObj);
      const components = CvPipeline.extractConnectedComponents(binObj);

      // Five-Stage Aesthetic Analysis
      const repeatedAnalysis = AestheticEngine.stage1IdentifyRepeatedLetters(components, targetC1);
      const features = AestheticEngine.stage2ExtractGeometricFeatures(components, lines, band.width, band.height);
      const profile = AestheticEngine.stage3ConstructReferenceProfile(features, { userId: sampleId });
      const deviations = AestheticEngine.stage4MeasureDeviations(features, profile);
      const evaluation = AestheticEngine.stage5EvaluateAesthetic(features, repeatedAnalysis, deviations);

      allResults.push({
        sampleId,
        dataset: 'dataset_c1',
        page: pageNum,
        sampleOnPage: band.sampleIndex,
        glyphCount: components.length,
        lineCount: lines.length,
        features: features ? features.local : null,
        scores: evaluation
      });

      console.log(`  [Sample ${sampleId}] Glyphs: ${components.length.toString().padStart(3)}, Score: ${evaluation.overallAestheticScore} (Grade: ${evaluation.grade}), Readability: ${evaluation.readabilityScore}, Slant: ${features ? features.local.medianSlantDeg : 'N/A'}°`);
    }
  }

  // 2. Process dataset of school students (21 pages, 21 student samples)
  console.log('\n--- Processing dataset of school students (Unlined paper, 1 sample/page) ---');
  const targetSchool = "The quick brown fox jumps over the lazy dog while five boxing wizards quickly pack my black box.";

  for (let pageNum = 1; pageNum <= 21; pageNum++) {
    const imgName = `school_students_page_${String(pageNum).padStart(2, '0')}.jpg`;
    const imgPath = path.join(researchWorkDir, imgName);

    if (!fs.existsSync(imgPath)) {
      console.warn(`File not found: ${imgName}`);
      continue;
    }

    const imgBase64 = fs.readFileSync(imgPath).toString('base64');
    const sampleId = `school_p${String(pageNum).padStart(2, '0')}`;

    const band = await page.evaluate(async (b64) => {
      return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => {
          const scale = Math.min(1.0, 1200 / img.width);
          const w = Math.round(img.width * scale);
          const h = Math.round(img.height * scale);

          const canvas = document.createElement('canvas');
          canvas.width = w;
          canvas.height = h;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, w, h);

          // Only take top 65% of page where writing occurs on unlined sheets
          const cropH = Math.floor(h * 0.65);
          const subImgData = ctx.getImageData(0, 0, w, cropH);

          resolve({
            width: w,
            height: cropH,
            data: Array.from(subImgData.data)
          });
        };
        img.src = `data:image/jpeg;base64,${b64}`;
      });
    }, imgBase64);

    const imgDataObj = { width: band.width, height: band.height, data: new Uint8ClampedArray(band.data) };

    const grayObj = CvPipeline.toGrayscale(imgDataObj);
    const normObj = CvPipeline.normalizeIllumination(grayObj, 32);
    const binObj = CvPipeline.otsuBinarize(normObj);
    const lines = CvPipeline.segmentLines(binObj);
    const components = CvPipeline.extractConnectedComponents(binObj);

    const repeatedAnalysis = AestheticEngine.stage1IdentifyRepeatedLetters(components, targetSchool);
    const features = AestheticEngine.stage2ExtractGeometricFeatures(components, lines, band.width, band.height);
    const profile = AestheticEngine.stage3ConstructReferenceProfile(features, { userId: sampleId });
    const deviations = AestheticEngine.stage4MeasureDeviations(features, profile);
    const evaluation = AestheticEngine.stage5EvaluateAesthetic(features, repeatedAnalysis, deviations);

    allResults.push({
      sampleId,
      dataset: 'school_students',
      page: pageNum,
      sampleOnPage: 1,
      glyphCount: components.length,
      lineCount: lines.length,
      features: features ? features.local : null,
      scores: evaluation
    });

    console.log(`  [Sample ${sampleId}] Glyphs: ${components.length.toString().padStart(3)}, Score: ${evaluation.overallAestheticScore} (Grade: ${evaluation.grade}), Readability: ${evaluation.readabilityScore}, Slant: ${features ? features.local.medianSlantDeg : 'N/A'}°`);
  }

  await browser.close();

  // Save all results
  const outJson = path.join(researchWorkDir, 'research_dataset_results.json');
  fs.writeFileSync(outJson, JSON.stringify(allResults, null, 2), 'utf8');

  // Compute dataset summary statistics
  const scores = allResults.map(r => r.scores.overallAestheticScore);
  const readabilities = allResults.map(r => r.scores.readabilityScore);
  const alignments = allResults.map(r => r.scores.alignmentScore);
  const formations = allResults.map(r => r.scores.letterFormationScore);
  const spacs = allResults.map(r => r.scores.spacingScore);

  const avg = arr => (arr.reduce((a, b) => a + b, 0) / arr.length).toFixed(1);

  console.log('\n========================================================');
  console.log(`TOTAL RESEARCH SAMPLES ANALYZED: ${allResults.length}`);
  console.log(`Average Overall Aesthetic Score: ${avg(scores)} / 100`);
  console.log(`Average Readability Score:        ${avg(readabilities)} / 100`);
  console.log(`Average Baseline Alignment:       ${avg(alignments)} / 100`);
  console.log(`Average Letter Formation:         ${avg(formations)} / 100`);
  console.log(`Average Spacing Score:            ${avg(spacs)} / 100`);
  console.log(`Score Range:                      ${Math.min(...scores)} - ${Math.max(...scores)}`);
  console.log(`Results saved to: research_working_dir/research_dataset_results.json`);
  console.log('========================================================');
}

runBatch().catch(console.error);

