/**
 * RAPID WRITE Aesthetic Evaluation Engine
 * Implements the Five Mandatory Algorithm Stages:
 *
 * STAGE 1: Repeated Letters & Common Stroke Pattern Identification
 * STAGE 2: Geometric & Spatial Feature Extraction
 * STAGE 3: Personal Handwriting Reference Profile Construction (Median + MAD)
 * STAGE 4: Deviation Analysis from Personal Reference Profile
 * STAGE 5: Consistency & Multi-dimensional Aesthetic Scoring (7 Dimensions)
 */

class AestheticEngine {
  /**
   * Helper: calculates median of numeric array
   */
  static median(arr) {
    if (!arr || arr.length === 0) return 0;
    const sorted = [...arr].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 !== 0 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /**
   * Helper: calculates Median Absolute Deviation (MAD)
   */
  static mad(arr, med = null) {
    if (!arr || arr.length < 2) return 1.0;
    const m = med !== null ? med : this.median(arr);
    const deviations = arr.map(x => Math.abs(x - m));
    return this.median(deviations) || 1.0;
  }

  /**
   * Helper: robust standard deviation proxy via MAD (1.4826 * MAD)
   */
  static robustStdDev(arr) {
    return 1.4826 * this.mad(arr);
  }

  // =========================================================================
  // STAGE 1: Identify Repeated Letters & Common Stroke Patterns
  // =========================================================================
  static stage1IdentifyRepeatedLetters(components, targetText) {
    if (!components || components.length === 0) {
      return { letterOccurrences: {}, commonStrokePatterns: [], letterCount: 0 };
    }

    const cleanTarget = targetText.toLowerCase().replace(/[^a-z0-9]/g, '');
    const charList = cleanTarget.split('');
    const letterOccurrences = {};

    // Group target letters by character
    const targetGroups = {};
    charList.forEach((ch, idx) => {
      if (!targetGroups[ch]) targetGroups[ch] = [];
      targetGroups[ch].push(idx);
    });

    // Approximate component-to-target character alignment
    // Components are horizontally ordered per line
    const totalComponents = components.length;
    const totalTargetChars = charList.length;

    components.forEach((comp, cIdx) => {
      // Map component index to expected target character position
      const expectedCharIdx = Math.min(totalTargetChars - 1, Math.floor((cIdx / totalComponents) * totalTargetChars));
      const expectedChar = charList[expectedCharIdx] || '?';

      if (!letterOccurrences[expectedChar]) {
        letterOccurrences[expectedChar] = [];
      }

      letterOccurrences[expectedChar].push({
        char: expectedChar,
        componentIndex: cIdx,
        x: comp.x,
        y: comp.y,
        width: comp.width,
        height: comp.height,
        aspectRatio: comp.aspectRatio,
        slantAngleDeg: comp.slantAngleDeg,
        area: comp.area,
        confidence: Math.max(0.4, 1.0 - Math.abs(cIdx / totalComponents - expectedCharIdx / totalTargetChars))
      });
    });

    // Identify common stroke patterns (ascenders, descenders, loops, body vowels)
    const patterns = [];
    ['e', 't', 's', 'a', 'd', 'o', 'l', 'r'].forEach(ch => {
      if (letterOccurrences[ch] && letterOccurrences[ch].length >= 2) {
        patterns.push({
          pattern: `Repeated '${ch}'`,
          occurrences: letterOccurrences[ch].length,
          avgHeight: this.median(letterOccurrences[ch].map(o => o.height)),
          avgSlant: this.median(letterOccurrences[ch].map(o => o.slantAngleDeg)),
          heightVariance: this.mad(letterOccurrences[ch].map(o => o.height)),
          slantVariance: this.mad(letterOccurrences[ch].map(o => o.slantAngleDeg))
        });
      }
    });

    return {
      letterOccurrences,
      repeatedLetterPatterns: patterns,
      totalGlyphsDetected: components.length
    };
  }

  // =========================================================================
  // STAGE 2: Extract Geometric Features (Local & Global)
  // =========================================================================
  static stage2ExtractGeometricFeatures(components, lines, paperWidth, paperHeight) {
    if (!components || components.length === 0) {
      return null;
    }

    // 1. Local Features: Height, Width, Aspect Ratio, Slant
    const heights = components.map(c => c.height);
    const widths = components.map(c => c.width);
    const aspectRatios = components.map(c => c.aspectRatio);
    const slants = components.map(c => c.slantAngleDeg);

    const medianHeight = this.median(heights);
    const medianWidth = this.median(widths);
    const medianSlant = this.median(slants);
    const heightMad = this.mad(heights, medianHeight);
    const slantMad = this.mad(slants, medianSlant);

    // 2. Inter-glyph and Inter-word Spacing
    const horizontalGaps = [];
    for (let i = 1; i < components.length; i++) {
      const gap = components[i].x - (components[i - 1].x + components[i - 1].width);
      // Filter out line breaks (large negative gaps)
      if (gap >= -5 && gap < medianHeight * 3.0) {
        horizontalGaps.push(Math.max(0, gap));
      }
    }

    const medianSpacing = horizontalGaps.length > 0 ? this.median(horizontalGaps) : medianHeight * 0.25;
    const spacingMad = horizontalGaps.length > 0 ? this.mad(horizontalGaps, medianSpacing) : 1.0;

    // 3. Baseline Drift & Alignment
    // Extract bottom-most contact point (y + height) for each component
    const baselines = components.map(c => c.y + c.height);
    const lineDeviations = [];

    if (lines && lines.length > 0) {
      lines.forEach(line => {
        const lineComps = components.filter(c => (c.y + c.height >= line.top && c.y <= line.bottom));
        if (lineComps.length >= 3) {
          // Linear regression of bottom points along the line
          const xs = lineComps.map(c => c.x);
          const ys = lineComps.map(c => c.y + c.height);
          const xMean = xs.reduce((a, b) => a + b) / xs.length;
          const yMean = ys.reduce((a, b) => a + b) / ys.length;

          let num = 0, den = 0;
          for (let i = 0; i < xs.length; i++) {
            num += (xs[i] - xMean) * (ys[i] - yMean);
            den += (xs[i] - xMean) * (xs[i] - xMean);
          }
          const slope = den !== 0 ? num / den : 0;
          const intercept = yMean - slope * xMean;

          // Compute residual deviations from fitted baseline
          ys.forEach((y, idx) => {
            const expectedY = slope * xs[idx] + intercept;
            lineDeviations.push(Math.abs(y - expectedY));
          });
        }
      });
    }

    const baselineDriftStd = lineDeviations.length > 0 ? this.robustStdDev(lineDeviations) : this.robustStdDev(baselines);

    // 4. Line Spacing Uniformity (Global)
    const lineGaps = [];
    if (lines && lines.length > 1) {
      for (let i = 1; i < lines.length; i++) {
        lineGaps.push(lines[i].top - lines[i - 1].bottom);
      }
    }
    const medianLineSpacing = lineGaps.length > 0 ? this.median(lineGaps) : 0;
    const lineSpacingMad = lineGaps.length > 0 ? this.mad(lineGaps, medianLineSpacing) : 0;

    return {
      local: {
        medianHeight: parseFloat(medianHeight.toFixed(2)),
        heightMad: parseFloat(heightMad.toFixed(2)),
        medianWidth: parseFloat(medianWidth.toFixed(2)),
        medianSlantDeg: parseFloat(medianSlant.toFixed(2)),
        slantMadDeg: parseFloat(slantMad.toFixed(2)),
        aspectRatio: parseFloat(this.median(aspectRatios).toFixed(2))
      },
      global: {
        medianSpacing: parseFloat(medianSpacing.toFixed(2)),
        spacingMad: parseFloat(spacingMad.toFixed(2)),
        baselineDriftPx: parseFloat(baselineDriftStd.toFixed(2)),
        lineCount: lines ? lines.length : 1,
        medianLineSpacing: parseFloat(medianLineSpacing.toFixed(2)),
        lineSpacingMad: parseFloat(lineSpacingMad.toFixed(2)),
        totalGlyphCount: components.length
      }
    };
  }

  // =========================================================================
  // STAGE 3: Construct Personal Reference Profile
  // =========================================================================
  static stage3ConstructReferenceProfile(extractedFeatures, userMetadata = {}) {
    if (!extractedFeatures) return null;
    const { local, global } = extractedFeatures;

    return {
      userId: userMetadata.userId || 'user_default',
      profileCreatedAt: new Date().toISOString(),
      sampleCount: 1,
      // Personal Reference Characteristics
      referenceMetrics: {
        letterHeight: {
          median: local.medianHeight,
          mad: local.heightMad,
          // Natural tolerance interval [median - 2*MAD, median + 2*MAD]
          naturalRange: [
            Math.max(4, local.medianHeight - 2.0 * local.heightMad),
            local.medianHeight + 2.0 * local.heightMad
          ]
        },
        slantAngle: {
          median: local.medianSlantDeg,
          mad: local.slantMadDeg,
          naturalRange: [
            local.medianSlantDeg - 2.0 * local.slantMadDeg,
            local.medianSlantDeg + 2.0 * local.slantMadDeg
          ]
        },
        letterSpacing: {
          median: global.medianSpacing,
          mad: global.spacingMad,
          naturalRange: [
            Math.max(1, global.medianSpacing - 2.0 * global.spacingMad),
            global.medianSpacing + 2.0 * global.spacingMad
          ]
        },
        baselineStability: {
          medianDrift: global.baselineDriftPx,
          toleranceThreshold: Math.max(6.0, global.baselineDriftPx * 1.5)
        },
        aspectRatio: local.aspectRatio
      },
      personalStyleTags: [
        local.medianSlantDeg > 10 ? 'Forward Slant (Italic)' : (local.medianSlantDeg < -10 ? 'Reverse Slant' : 'Upright Print'),
        local.aspectRatio > 0.85 ? 'Spacious / Wide' : 'Compact / Compressed',
        global.baselineDriftPx < 8.0 ? 'Steady Baseline' : 'Dynamic Baseline'
      ]
    };
  }

  // =========================================================================
  // STAGE 4: Measure Deviation from Personal Reference Profile
  // =========================================================================
  static stage4MeasureDeviations(currentFeatures, referenceProfile) {
    if (!currentFeatures) return null;
    if (!referenceProfile || !referenceProfile.referenceMetrics) {
      // No reference profile yet - return zero-deviation baseline
      return { hasProfile: false, deviations: {}, normalizedScores: {} };
    }

    const { local, global } = currentFeatures;
    const ref = referenceProfile.referenceMetrics;

    // Robust Z-scores: Z = |current - refMedian| / (1.4826 * refMAD)
    const heightZ = Math.abs(local.medianHeight - ref.letterHeight.median) / (1.4826 * ref.letterHeight.mad);
    const slantZ = Math.abs(local.medianSlantDeg - ref.slantAngle.median) / (1.4826 * ref.slantAngle.mad);
    const spacingZ = Math.abs(global.medianSpacing - ref.letterSpacing.median) / (1.4826 * ref.letterSpacing.mad);
    const baselineRatio = global.baselineDriftPx / ref.baselineStability.toleranceThreshold;

    // Tolerant evaluation:
    // |Z| <= 1.5 is natural personal style variation (0 penalty)
    // 1.5 < |Z| <= 2.5 is moderate deviation
    // |Z| > 2.5 is noticeable distortion affecting readability
    return {
      hasProfile: true,
      deviations: {
        heightZ: parseFloat(heightZ.toFixed(2)),
        slantZ: parseFloat(slantZ.toFixed(2)),
        spacingZ: parseFloat(spacingZ.toFixed(2)),
        baselineRatio: parseFloat(baselineRatio.toFixed(2))
      },
      styleShiftObservations: [
        heightZ > 2.0 ? (local.medianHeight > ref.letterHeight.median ? 'Letters written larger than baseline' : 'Letters written smaller than baseline') : null,
        slantZ > 2.0 ? 'Notable shift in writing slant compared to personal baseline' : null,
        spacingZ > 2.0 ? 'Inter-letter spacing expanded or compressed unusually' : null,
        baselineRatio > 1.8 ? 'Increased baseline waviness compared to reference sample' : null
      ].filter(Boolean)
    };
  }

  // =========================================================================
  // STAGE 5: Evaluate Consistency & Multi-dimensional Aesthetic Scoring
  // =========================================================================
  static stage5EvaluateAesthetic(currentFeatures, repeatedAnalysis, deviationAnalysis, cohort = 'Senior / College') {
    if (!currentFeatures) {
      return {
        overallAestheticScore: 0,
        readabilityScore: 0,
        letterFormationScore: 0,
        spacingScore: 0,
        alignmentScore: 0,
        consistencyScore: 0,
        visualOrganizationScore: 0,
        grade: 'N/A',
        critiqueTitle: 'No sample analyzed',
        coachingTips: []
      };
    }

    const { local, global } = currentFeatures;
    const isSchoolCohort = typeof cohort === 'string' && 
      (cohort.toLowerCase().includes('school') || cohort.toLowerCase().includes('junior') || cohort.toLowerCase().includes('elementary'));

    // 1. Alignment Score: Baseline straightness & drift control
    // Younger students on unlined sheets have higher natural baseline variation without ruling lines.
    const effectiveDrift = isSchoolCohort ? (global.baselineDriftPx / 1.55) : global.baselineDriftPx;
    const alignmentScore = Math.max(30, Math.min(99, 100 - effectiveDrift * 2.8));

    // 2. Slant Consistency Score: Low slant MAD across glyphs
    const slantScale = isSchoolCohort ? 2.5 : 3.2;
    const slantConsistencyScore = Math.max(30, Math.min(99, 100 - local.slantMadDeg * slantScale));

    // 3. Spacing Score: Regularity of horizontal gaps between characters & words
    const spacingScale = isSchoolCohort ? 2.8 : 3.5;
    const spacingScore = Math.max(30, Math.min(98, 100 - global.spacingMad * spacingScale));

    // 4. Letter Formation Score: Aspect ratio stability and stroke repetition
    let formationBonus = 0;
    if (repeatedAnalysis && repeatedAnalysis.repeatedLetterPatterns) {
      const avgRepeatedHeightVar = repeatedAnalysis.repeatedLetterPatterns.reduce((acc, p) => acc + p.heightVariance, 0) / (repeatedAnalysis.repeatedLetterPatterns.length || 1);
      formationBonus = Math.max(-15, Math.min(10, 10 - avgRepeatedHeightVar * (isSchoolCohort ? 1.0 : 1.5)));
    }
    const heightPenalty = local.heightMad * (isSchoolCohort ? Math.min(3.0, (28.0 / Math.max(25.0, local.medianHeight)) * 3.0) : 3.0);
    const letterFormationScore = Math.max(30, Math.min(98, (100 - heightPenalty) + formationBonus));

    // 5. Readability Score: Glyph open contours, distinguishability & scale adequacy
    const minHeightThreshold = isSchoolCohort ? 20.0 : 14.0;
    const heightAdequacy = Math.min(1.0, Math.max(0.65, local.medianHeight / minHeightThreshold));
    const readabilityScore = Math.max(35, Math.min(99, (alignmentScore * 0.35 + letterFormationScore * 0.40 + spacingScore * 0.25) * heightAdequacy));

    // 6. Consistency Score: Combined within-sample regularity & personal profile deviation
    let consistencyPenalty = 0;
    if (deviationAnalysis && deviationAnalysis.hasProfile) {
      const z = deviationAnalysis.deviations;
      // Only penalize if deviation exceeds natural 1.5 MAD threshold
      if (z.heightZ > 1.5) consistencyPenalty += (z.heightZ - 1.5) * (isSchoolCohort ? 3.0 : 4.0);
      if (z.slantZ > 1.5) consistencyPenalty += (z.slantZ - 1.5) * (isSchoolCohort ? 3.0 : 4.0);
      if (z.spacingZ > 1.5) consistencyPenalty += (z.spacingZ - 1.5) * (isSchoolCohort ? 2.5 : 3.5);
    }
    const withinSampleConsistency = (slantConsistencyScore * 0.5 + (100 - heightPenalty) * 0.5);
    const consistencyScore = Math.max(30, Math.min(98, withinSampleConsistency - consistencyPenalty));

    // 7. Visual Organisation Score: Page balance, line count balance & layout
    const visualOrganizationScore = Math.max(35, Math.min(98, (alignmentScore * 0.5 + spacingScore * 0.3 + consistencyScore * 0.2)));

    // 8. Overall Composite Aesthetic Score (Harmonic, scientifically balanced weights)
    const overallAestheticScore = Math.max(30, Math.min(99,
      readabilityScore * 0.22 +
      letterFormationScore * 0.18 +
      alignmentScore * 0.18 +
      consistencyScore * 0.16 +
      spacingScore * 0.14 +
      visualOrganizationScore * 0.12
    ));

    // Determine Letter Grade
    let grade = 'B';
    if (overallAestheticScore >= 92) grade = 'A+';
    else if (overallAestheticScore >= 85) grade = 'A';
    else if (overallAestheticScore >= 78) grade = 'B+';
    else if (overallAestheticScore >= 70) grade = 'B';
    else if (overallAestheticScore >= 60) grade = 'C+';
    else grade = 'C';

    // Constructive, student-friendly coaching tips
    const coachingTips = [];
    if (alignmentScore < 75) {
      coachingTips.push('Focus on maintaining a uniform baseline so your words do not drift up or down.');
    }
    if (slantConsistencyScore < 75) {
      coachingTips.push('Try to keep your letter slant at a steady angle across the entire sentence.');
    }
    if (spacingScore < 75) {
      coachingTips.push('Leave consistent spacing between your words so the sentence is easy to read at a glance.');
    }
    if (letterFormationScore < 75) {
      coachingTips.push('Pay attention to repeated letters like "e", "t", and "s" to make their loops and stems uniform.');
    }
    if (coachingTips.length === 0) {
      coachingTips.push('Excellent handwriting rhythm and letter harmony! Keep practicing to build muscle memory.');
    }

    return {
      overallAestheticScore: parseFloat(overallAestheticScore.toFixed(1)),
      readabilityScore: parseFloat(readabilityScore.toFixed(1)),
      letterFormationScore: parseFloat(letterFormationScore.toFixed(1)),
      spacingScore: parseFloat(spacingScore.toFixed(1)),
      alignmentScore: parseFloat(alignmentScore.toFixed(1)),
      consistencyScore: parseFloat(consistencyScore.toFixed(1)),
      visualOrganizationScore: parseFloat(visualOrganizationScore.toFixed(1)),
      grade,
      critiqueTitle: grade === 'A+' || grade === 'A' ? 'Harmonious & Fluid Penmanship' : (grade === 'B+' || grade === 'B' ? 'Consistent Handwriting Cadence' : 'Developing Penmanship Form'),
      coachingTips
    };
  }
}

module.exports = AestheticEngine;

