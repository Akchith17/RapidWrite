/**
 * RAPID WRITE Computer Vision & Preprocessing Pipeline
 * Core computer vision routines for handwriting sample analysis:
 * - Grayscale conversion & background illumination normalization
 * - Otsu bimodal adaptive thresholding
 * - Horizontal & vertical projection profiling for line/word segmentation
 * - 8-connected component analysis for character bounding box extraction
 * - Central image moments (mu20, mu02, mu11) for stroke slant angle computation
 */

class CvPipeline {
  /**
   * Converts RGBA ImageData to grayscale float array [0..255]
   */
  static toGrayscale(imgData) {
    const { width, height, data } = imgData;
    const gray = new Float32Array(width * height);
    for (let i = 0, j = 0; i < data.length; i += 4, j++) {
      // Standard Rec. 601 luma
      gray[j] = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
    }
    return { width, height, gray };
  }

  /**
   * Estimates background illumination via block-based morphological opening,
   * then normalizes the grayscale image to remove shadows and paper creases.
   */
  static normalizeIllumination(grayObj, blockSize = 32) {
    const { width, height, gray } = grayObj;
    const norm = new Float32Array(width * height);
    const blocksX = Math.ceil(width / blockSize);
    const blocksY = Math.ceil(height / blockSize);
    const bgGrid = new Float32Array(blocksX * blocksY);

    // Compute 90th percentile (paper background) in each block
    for (let by = 0; by < blocksY; by++) {
      for (let bx = 0; bx < blocksX; bx++) {
        const xStart = bx * blockSize;
        const yStart = by * blockSize;
        const xEnd = Math.min(width, xStart + blockSize);
        const yEnd = Math.min(height, yStart + blockSize);
        const vals = [];

        for (let y = yStart; y < yEnd; y++) {
          for (let x = xStart; x < xEnd; x++) {
            vals.push(gray[y * width + x]);
          }
        }
        vals.sort((a, b) => a - b);
        // 90th percentile represents paper white
        const p90 = vals[Math.floor(vals.length * 0.9)] || 255;
        bgGrid[by * blocksX + bx] = p90;
      }
    }

    // Bilinear interpolation of background and illumination division
    for (let y = 0; y < height; y++) {
      const gy = (y / blockSize) - 0.5;
      const by0 = Math.max(0, Math.min(blocksY - 1, Math.floor(gy)));
      const by1 = Math.max(0, Math.min(blocksY - 1, by0 + 1));
      const fy = Math.max(0, Math.min(1, gy - by0));

      for (let x = 0; x < width; x++) {
        const gx = (x / blockSize) - 0.5;
        const bx0 = Math.max(0, Math.min(blocksX - 1, Math.floor(gx)));
        const bx1 = Math.max(0, Math.min(blocksX - 1, bx0 + 1));
        const fx = Math.max(0, Math.min(1, gx - bx0));

        const bgTop = bgGrid[by0 * blocksX + bx0] * (1 - fx) + bgGrid[by0 * blocksX + bx1] * fx;
        const bgBot = bgGrid[by1 * blocksX + bx0] * (1 - fx) + bgGrid[by1 * blocksX + bx1] * fx;
        const bg = bgTop * (1 - fy) + bgBot * fy || 255;

        // Normalized: (pixel / bg) * 255
        norm[y * width + x] = Math.min(255, Math.max(0, (gray[y * width + x] / bg) * 255));
      }
    }

    return { width, height, gray: norm };
  }

  /**
   * Otsu's optimal thresholding algorithm for bimodal ink/paper separation.
   * Returns threshold T and binary Uint8Array (1 = ink, 0 = paper background).
   */
  static otsuBinarize(grayObj) {
    const { width, height, gray } = grayObj;
    const totalPixels = width * height;
    const hist = new Uint32Array(256);

    for (let i = 0; i < totalPixels; i++) {
      const v = Math.round(gray[i]);
      hist[v]++;
    }

    let sum = 0;
    for (let i = 0; i < 256; i++) sum += i * hist[i];

    let sumB = 0;
    let wB = 0;
    let wF = 0;
    let maxVariance = 0;
    let threshold = 128;

    for (let t = 0; t < 256; t++) {
      wB += hist[t];
      if (wB === 0) continue;
      wF = totalPixels - wB;
      if (wF === 0) break;

      sumB += t * hist[t];
      const mB = sumB / wB;
      const mF = (sum - sumB) / wF;
      const betweenVariance = wB * wF * (mB - mF) * (mB - mF);

      if (betweenVariance > maxVariance) {
        maxVariance = betweenVariance;
        threshold = t;
      }
    }

    // Apply safety margin to capture light pen strokes without paper noise
    const safeThreshold = Math.min(185, Math.max(80, threshold - 5));
    const binary = new Uint8Array(totalPixels);
    let inkCount = 0;

    for (let i = 0; i < totalPixels; i++) {
      if (gray[i] < safeThreshold) {
        binary[i] = 1; // ink
        inkCount++;
      } else {
        binary[i] = 0; // paper
      }
    }

    return { width, height, binary, threshold: safeThreshold, inkRatio: inkCount / totalPixels };
  }

  /**
   * Horizontal projection histogram: sum of ink pixels along each row.
   * Identifies line bounds and inter-line baseline contacts.
   */
  static horizontalProjection(binObj, yStart = 0, yEnd = null) {
    const { width, height, binary } = binObj;
    const end = yEnd || height;
    const proj = new Float32Array(end - yStart);

    for (let y = yStart; y < end; y++) {
      let sum = 0;
      const rowOffset = y * width;
      for (let x = 0; x < width; x++) {
        sum += binary[rowOffset + x];
      }
      proj[y - yStart] = sum;
    }
    return proj;
  }

  /**
   * Segment text lines using smoothed horizontal projection profile peaks and valleys.
   */
  static segmentLines(binObj, minLineHeight = 24, valleyThresholdRatio = 0.08) {
    const { width, height } = binObj;
    const proj = this.horizontalProjection(binObj);

    // 1D Gaussian-like smoothing (window size 9)
    const smoothed = new Float32Array(proj.length);
    const radius = 4;
    for (let i = 0; i < proj.length; i++) {
      let sum = 0, count = 0;
      for (let d = -radius; d <= radius; d++) {
        const idx = i + d;
        if (idx >= 0 && idx < proj.length) {
          sum += proj[idx];
          count++;
        }
      }
      smoothed[i] = sum / count;
    }

    const maxVal = Math.max(...smoothed);
    const threshold = maxVal * valleyThresholdRatio;
    const lines = [];
    let inLine = false;
    let lineTop = 0;

    for (let y = 0; y < height; y++) {
      if (smoothed[y] > threshold && !inLine) {
        inLine = true;
        lineTop = y;
      } else if (smoothed[y] <= threshold && inLine) {
        inLine = false;
        const lineBottom = y;
        if ((lineBottom - lineTop) >= minLineHeight) {
          lines.push({
            top: Math.max(0, lineTop - 2),
            bottom: Math.min(height, lineBottom + 2),
            height: lineBottom - lineTop
          });
        }
      }
    }

    if (inLine && (height - lineTop) >= minLineHeight) {
      lines.push({ top: lineTop, bottom: height, height: height - lineTop });
    }

    return lines;
  }

  /**
   * Connected Component Analysis (8-way connected)
   * Groups contiguous ink pixels into discrete glyph/character bounding boxes.
   */
  static extractConnectedComponents(binObj, roi = null) {
    const { width, height, binary } = binObj;
    const x0 = roi ? Math.max(0, roi.x) : 0;
    const y0 = roi ? Math.max(0, roi.y) : 0;
    const x1 = roi ? Math.min(width, roi.x + roi.width) : width;
    const y1 = roi ? Math.min(height, roi.y + roi.height) : height;

    const visited = new Uint8Array(width * height);
    const components = [];

    // Queue for BFS
    const qx = new Int32Array(width * height);
    const qy = new Int32Array(width * height);

    for (let y = y0; y < y1; y++) {
      const rowOffset = y * width;
      for (let x = x0; x < x1; x++) {
        const idx = rowOffset + x;
        if (binary[idx] === 1 && visited[idx] === 0) {
          let head = 0, tail = 0;
          qx[tail] = x;
          qy[tail] = y;
          tail++;
          visited[idx] = 1;

          let minX = x, maxX = x, minY = y, maxY = y;
          let pixelCount = 0;
          let m10 = 0, m01 = 0;
          let m20 = 0, m02 = 0, m11 = 0;

          while (head < tail) {
            const cx = qx[head];
            const cy = qy[head];
            head++;
            pixelCount++;

            if (cx < minX) minX = cx;
            if (cx > maxX) maxX = cx;
            if (cy < minY) minY = cy;
            if (cy > maxY) maxY = cy;

            m10 += cx;
            m01 += cy;
            m20 += cx * cx;
            m02 += cy * cy;
            m11 += cx * cy;

            // 8 neighbors
            for (let dy = -1; dy <= 1; dy++) {
              const ny = cy + dy;
              if (ny < y0 || ny >= y1) continue;
              const nRow = ny * width;
              for (let dx = -1; dx <= 1; dx++) {
                if (dx === 0 && dy === 0) continue;
                const nx = cx + dx;
                if (nx < x0 || nx >= x1) continue;
                const nIdx = nRow + nx;
                if (binary[nIdx] === 1 && visited[nIdx] === 0) {
                  visited[nIdx] = 1;
                  qx[tail] = nx;
                  qy[tail] = ny;
                  tail++;
                }
              }
            }
          }

          // Filter out tiny dust specks (< 12 pixels)
          if (pixelCount >= 12 && (maxX - minX >= 3) && (maxY - minY >= 4)) {
            const xc = m10 / pixelCount;
            const yc = m01 / pixelCount;

            // Central second-order moments for slant angle computation
            const u20 = m20 - pixelCount * xc * xc;
            const u02 = m02 - pixelCount * yc * yc;
            const u11 = m11 - pixelCount * xc * yc;

            // Slant orientation in degrees from vertical
            // Vertical upright stroke has slant = 0 deg
            let slantDeg = 0;
            if (Math.abs(u20 - u02) > 1e-5 || Math.abs(u11) > 1e-5) {
              const thetaRad = 0.5 * Math.atan2(2 * u11, u20 - u02);
              slantDeg = (thetaRad * 180 / Math.PI) - 90;
              // Normalize to [-45, +45]
              while (slantDeg < -90) slantDeg += 180;
              while (slantDeg > 90) slantDeg -= 180;
            }

            components.push({
              x: minX,
              y: minY,
              width: maxX - minX + 1,
              height: maxY - minY + 1,
              area: pixelCount,
              centroidX: xc,
              centroidY: yc,
              slantAngleDeg: slantDeg,
              aspectRatio: (maxX - minX + 1) / (maxY - minY + 1)
            });
          }
        }
      }
    }

    // Sort components horizontally by x-coordinate
    components.sort((a, b) => a.x - b.x);
    return components;
  }
}

module.exports = CvPipeline;

