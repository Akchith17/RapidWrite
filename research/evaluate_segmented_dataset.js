const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');
const CvPipeline = require('./cv_pipeline');
const AestheticEngine = require('./aesthetic_engine');

const researchWorkDir = path.resolve(__dirname, '..', 'research_working_dir');
const manifestPath = path.join(researchWorkDir, 'dataset_segmentation_manifest.json');
const samplesDir = path.join(researchWorkDir, 'segmented_samples');

async function evaluateAllSegmentedSamples() {
  console.log('================================================================');
  console.log('  RAPID WRITE – 5-STAGE AESTHETIC EVALUATION ON 84 SAMPLES');
  console.log('================================================================');

  if (!fs.existsSync(manifestPath)) {
    throw new Error(`Manifest not found at: ${manifestPath}`);
  }

  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const samples = manifest.samples;
  console.log(`Loaded manifest: ${samples.length} segmented student samples detected across ${manifest.metadata.totalPagesInspected} pages.`);

  const chromePaths = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Users\\akchi\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe'
  ];
  const execPath = chromePaths.find(p => fs.existsSync(p));
  if (!execPath) {
    throw new Error('Chrome executable not found on host.');
  }

  const browser = await puppeteer.launch({
    executablePath: execPath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  const evaluationResults = [];

  for (let i = 0; i < samples.length; i++) {
    const s = samples[i];
    const imgFilename = `${s.sampleId}.jpg`;
    const imgPath = path.join(samplesDir, imgFilename);

    if (!fs.existsSync(imgPath)) {
      console.warn(`[WARN] Sample image not found: ${imgFilename}`);
      continue;
    }

    const imgBase64 = fs.readFileSync(imgPath).toString('base64');

    // Extract pixel buffer via headless Chrome canvas
    const imgDataObj = await page.evaluate(async (b64) => {
      return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => {
          // Scale to max width 1200 for fast high-fidelity CV processing
          const scale = Math.min(1.0, 1200 / img.width);
          const w = Math.round(img.width * scale);
          const h = Math.round(img.height * scale);

          const canvas = document.createElement('canvas');
          canvas.width = w;
          canvas.height = h;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, w, h);

          const rawData = ctx.getImageData(0, 0, w, h);
          resolve({
            width: w,
            height: h,
            data: Array.from(rawData.data)
          });
        };
        img.src = `data:image/jpeg;base64,${b64}`;
      });
    }, imgBase64);

    const rawPixelObj = {
      width: imgDataObj.width,
      height: imgDataObj.height,
      data: new Uint8ClampedArray(imgDataObj.data)
    };

    // 1. Computer Vision Preprocessing
    const gray = CvPipeline.toGrayscale(rawPixelObj);
    const norm = CvPipeline.normalizeIllumination(gray, 32);
    const bin = CvPipeline.otsuBinarize(norm);
    const lines = CvPipeline.segmentLines(bin);
    const components = CvPipeline.extractConnectedComponents(bin);

    // 2. Five Mandatory Algorithm Stages
    // Stage 1: Identify repeated letters & stroke patterns
    const repeated = AestheticEngine.stage1IdentifyRepeatedLetters(components, s.targetSentence);

    // Stage 2: Geometric & Spatial feature extraction
    const features = AestheticEngine.stage2ExtractGeometricFeatures(components, lines, imgDataObj.width, imgDataObj.height);

    // Stage 3: Construct personal reference profile (Median + MAD)
    const profile = AestheticEngine.stage3ConstructReferenceProfile(features, {
      userId: s.sampleId,
      cohort: s.ageGroupCohort
    });

    // Stage 4: Measure deviations from student's own reference profile
    const deviations = AestheticEngine.stage4MeasureDeviations(features, profile);

    // Stage 5: Multi-dimensional aesthetic scoring with age-cohort adaptiveness
    const scores = AestheticEngine.stage5EvaluateAesthetic(features, repeated, deviations, s.ageGroupCohort);

    const record = {
      sampleId: s.sampleId,
      sourcePdf: s.sourcePdf,
      originalPageNumber: s.originalPageNumber,
      entryIndexOnPage: s.entryIndexOnPage,
      ageGroupCohort: s.ageGroupCohort,
      targetSentence: s.targetSentence,
      boundingBox: s.boundingBox,
      glyphCount: components.length,
      lineCount: lines.length,
      features: features,
      referenceProfile: profile,
      deviations: deviations,
      scores: scores
    };

    evaluationResults.push(record);

    console.log(`[${s.sampleId}] (${s.ageGroupCohort.includes('School') ? 'School' : 'C1'}) Glyphs: ${components.length.toString().padStart(3)} | Lines: ${lines.length} | Score: ${scores.overallAestheticScore.toFixed(1)} (${scores.grade}) | Readability: ${scores.readabilityScore.toFixed(1)} | Alignment: ${scores.alignmentScore.toFixed(1)} | Slant: ${features ? features.local.medianSlantDeg.toFixed(1) : 0}°`);
  }

  await browser.close();

  // Compute Cohort and Aggregate Statistics
  function computeStats(arr, keyPath) {
    const vals = arr.map(item => {
      const parts = keyPath.split('.');
      let cur = item;
      for (const p of parts) cur = cur ? cur[p] : undefined;
      return typeof cur === 'number' ? cur : null;
    }).filter(v => v !== null);

    if (vals.length === 0) return { mean: 0, median: 0, min: 0, max: 0 };
    vals.sort((a, b) => a - b);
    const mean = vals.reduce((a, b) => a + b, 0) / vals.length;
    const mid = Math.floor(vals.length / 2);
    const median = vals.length % 2 !== 0 ? vals[mid] : (vals[mid - 1] + vals[mid]) / 2;
    return {
      mean: parseFloat(mean.toFixed(2)),
      median: parseFloat(median.toFixed(2)),
      min: parseFloat(vals[0].toFixed(2)),
      max: parseFloat(vals[vals.length - 1].toFixed(2))
    };
  }

  const c1Samples = evaluationResults.filter(r => r.ageGroupCohort.includes('C1'));
  const schoolSamples = evaluationResults.filter(r => r.ageGroupCohort.includes('School'));

  const dimensions = [
    'scores.overallAestheticScore',
    'scores.readabilityScore',
    'scores.letterFormationScore',
    'scores.spacingScore',
    'scores.alignmentScore',
    'scores.consistencyScore',
    'scores.visualOrganizationScore',
    'features.local.medianSlantDeg',
    'features.local.medianHeight',
    'features.global.baselineDriftPx'
  ];

  const stats = {
    c1Cohort: {
      count: c1Samples.length,
      gradeDistribution: {},
      metrics: {}
    },
    schoolCohort: {
      count: schoolSamples.length,
      gradeDistribution: {},
      metrics: {}
    },
    overall: {
      count: evaluationResults.length,
      gradeDistribution: {},
      metrics: {}
    }
  };

  ['c1Cohort', 'schoolCohort', 'overall'].forEach(cKey => {
    const subset = cKey === 'c1Cohort' ? c1Samples : (cKey === 'schoolCohort' ? schoolSamples : evaluationResults);
    subset.forEach(s => {
      const g = s.scores.grade;
      stats[cKey].gradeDistribution[g] = (stats[cKey].gradeDistribution[g] || 0) + 1;
    });
    dimensions.forEach(dim => {
      const shortKey = dim.replace('scores.', '').replace('features.local.', '').replace('features.global.', '');
      stats[cKey].metrics[shortKey] = computeStats(subset, dim);
    });
  });

  const outputPayload = {
    generatedAt: new Date().toISOString(),
    totalSamplesEvaluated: evaluationResults.length,
    statistics: stats,
    samples: evaluationResults
  };

  // Write full JSON
  const outJsonPath = path.join(researchWorkDir, 'segmented_aesthetic_results.json');
  fs.writeFileSync(outJsonPath, JSON.stringify(outputPayload, null, 2), 'utf8');
  console.log(`\nSuccessfully saved full evaluation results to: ${outJsonPath}`);

  // Write summary CSV
  const csvRows = [
    'SampleId,SourcePdf,Page,EntryOnPage,Cohort,Glyphs,Lines,OverallScore,Grade,Readability,Formation,Spacing,Alignment,Consistency,VisualOrg,SlantDeg,MedianHeightPx,BaselineDriftPx'
  ];

  evaluationResults.forEach(r => {
    const fLoc = r.features ? r.features.local : {};
    const fGlob = r.features ? r.features.global : {};
    csvRows.push([
      r.sampleId,
      `"${r.sourcePdf}"`,
      r.originalPageNumber,
      r.entryIndexOnPage,
      `"${r.ageGroupCohort}"`,
      r.glyphCount,
      r.lineCount,
      r.scores.overallAestheticScore,
      r.scores.grade,
      r.scores.readabilityScore,
      r.scores.letterFormationScore,
      r.scores.spacingScore,
      r.scores.alignmentScore,
      r.scores.consistencyScore,
      r.scores.visualOrganizationScore,
      fLoc.medianSlantDeg || 0,
      fLoc.medianHeight || 0,
      fGlob.baselineDriftPx || 0
    ].join(','));
  });

  const outCsvPath = path.join(researchWorkDir, 'segmented_aesthetic_summary.csv');
  fs.writeFileSync(outCsvPath, csvRows.join('\n'), 'utf8');
  console.log(`Successfully saved CSV summary to: ${outCsvPath}`);

  // Print Summary
  console.log('\n================================================================');
  console.log('  EVALUATION SUMMARY BY COHORT');
  console.log('================================================================');
  console.log(`C1 Cohort (Senior / College): ${c1Samples.length} samples`);
  console.log(`  Overall Aesthetic Mean: ${stats.c1Cohort.metrics.overallAestheticScore.mean} (Median: ${stats.c1Cohort.metrics.overallAestheticScore.median})`);
  console.log(`  Readability Mean:       ${stats.c1Cohort.metrics.readabilityScore.mean}`);
  console.log(`  Alignment Mean:         ${stats.c1Cohort.metrics.alignmentScore.mean}`);
  console.log(`  Grades:`, stats.c1Cohort.gradeDistribution);

  console.log(`\nSchool Students Cohort (Elementary / Middle): ${schoolSamples.length} samples`);
  console.log(`  Overall Aesthetic Mean: ${stats.schoolCohort.metrics.overallAestheticScore.mean} (Median: ${stats.schoolCohort.metrics.overallAestheticScore.median})`);
  console.log(`  Readability Mean:       ${stats.schoolCohort.metrics.readabilityScore.mean}`);
  console.log(`  Alignment Mean:         ${stats.schoolCohort.metrics.alignmentScore.mean}`);
  console.log(`  Grades:`, stats.schoolCohort.gradeDistribution);

  console.log(`\nAggregate (All 84 Samples):`);
  console.log(`  Overall Aesthetic Mean: ${stats.overall.metrics.overallAestheticScore.mean} (Median: ${stats.overall.metrics.overallAestheticScore.median})`);
  console.log(`  Total Grades:`, stats.overall.gradeDistribution);
}

evaluateAllSegmentedSamples().catch(err => {
  console.error('Batch evaluation error:', err);
  process.exit(1);
});
