const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer-core');

const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>RAPID WRITE – The Human Guide to Stylus Handwriting & Penmanship Evaluation</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap');

  :root {
    --orange-primary: #FF6B00;
    --orange-dark: #EA580C;
    --orange-light: #FF8A3D;
    --orange-soft: #FFF7ED;
    --orange-border: #FFD8BF;
    --dark-bg: #0F172A;
    --dark-surface: #1E293B;
    --slate-text: #334155;
    --slate-muted: #64748B;
    --slate-light: #F8FAFC;
    --emerald: #059669;
    --emerald-bg: #ECFDF5;
    --blue-accent: #2563EB;
    --blue-bg: #EFF6FF;
    --purple-accent: #7C3AED;
    --purple-bg: #F5F3FF;
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    color: var(--slate-text);
    background: #ffffff;
    font-size: 9.2pt;
    line-height: 1.5;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  @page {
    size: A4 portrait;
    margin: 0;
  }

  .page {
    width: 210mm;
    height: 297mm;
    max-height: 297mm;
    padding: 13mm 15mm 12mm 15mm;
    page-break-after: always;
    position: relative;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    overflow: hidden;
    background: #ffffff;
  }

  .page:last-child {
    page-break-after: avoid;
  }

  /* Running Header & Footer */
  .page-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1.5px solid #F1F5F9;
    padding-bottom: 6px;
    margin-bottom: 12px;
    font-size: 7.5pt;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--slate-muted);
    font-weight: 600;
  }

  .page-header .brand {
    color: var(--orange-primary);
    font-weight: 800;
    display: flex;
    align-items: center;
    gap: 5px;
  }

  .page-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top: 1px solid #E2E8F0;
    padding-top: 6px;
    font-size: 7.5pt;
    color: var(--slate-muted);
    margin-top: 8px;
  }

  .page-body {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
  }

  /* Typography */
  h1, h2, h3, h4 {
    color: var(--dark-bg);
    font-weight: 700;
    line-height: 1.25;
  }

  h1 { font-size: 21pt; font-weight: 800; }
  h2 { font-size: 14pt; margin-bottom: 6px; color: var(--dark-bg); display: flex; align-items: center; gap: 8px; }
  h3 { font-size: 10.5pt; margin-bottom: 4px; color: var(--orange-dark); font-weight: 700; }
  p { margin-bottom: 7px; }

  /* Pills & Badges */
  .badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 2.5px 7.5px;
    border-radius: 999px;
    font-size: 7.2pt;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  .badge-orange { background: var(--orange-soft); color: var(--orange-dark); border: 1px solid var(--orange-border); }
  .badge-emerald { background: var(--emerald-bg); color: var(--emerald); border: 1px solid #A7F3D0; }
  .badge-blue { background: var(--blue-bg); color: var(--blue-accent); border: 1px solid #BFDBFE; }
  .badge-purple { background: var(--purple-bg); color: var(--purple-accent); border: 1px solid #DDD6FE; }

  /* Callout Boxes */
  .callout {
    border-radius: 8px;
    padding: 8px 12px;
    margin: 8px 0;
    font-size: 8.7pt;
    line-height: 1.48;
  }
  .callout-plain {
    background: #FFFBEB;
    border-left: 4px solid #F59E0B;
    color: #92400E;
  }
  .callout-plain strong { color: #78350F; font-weight: 700; }

  .callout-tip {
    background: var(--orange-soft);
    border-left: 4px solid var(--orange-primary);
    color: #9A3412;
  }
  .callout-tip strong { color: var(--orange-dark); }

  .callout-tech {
    background: var(--blue-bg);
    border-left: 4px solid var(--blue-accent);
    color: #1E40AF;
  }

  /* Grid Layouts */
  .grid-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    margin-bottom: 8px;
  }
  .grid-3 {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 8px;
    margin-bottom: 8px;
  }

  /* Cards */
  .card {
    background: #ffffff;
    border: 1px solid #E2E8F0;
    border-radius: 9px;
    padding: 9px 12px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.02);
  }
  .card-highlight {
    border-color: var(--orange-border);
    background: linear-gradient(180deg, #FFFFFF 0%, #FFFDFB 100%);
  }

  /* Workflow Steps */
  .step-container {
    display: flex;
    gap: 11px;
    margin-bottom: 9px;
    background: #ffffff;
    border: 1px solid #E2E8F0;
    border-radius: 9px;
    padding: 8px 11px;
  }
  .step-number {
    flex-shrink: 0;
    width: 28px;
    height: 28px;
    border-radius: 7px;
    background: linear-gradient(135deg, var(--orange-primary), var(--orange-dark));
    color: #ffffff;
    font-weight: 800;
    font-size: 10.5pt;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 5px rgba(255, 107, 0, 0.25);
  }
  .step-content {
    flex: 1;
  }
  .step-title {
    font-size: 9.8pt;
    font-weight: 700;
    color: var(--dark-bg);
    margin-bottom: 2px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  /* Tables */
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 6px 0 9px 0;
    font-size: 8.5pt;
  }
  th {
    background: #F8FAFC;
    color: var(--dark-bg);
    font-weight: 700;
    text-align: left;
    padding: 6px 9px;
    border-bottom: 2px solid #E2E8F0;
    font-size: 7.8pt;
    text-transform: uppercase;
    letter-spacing: 0.04em;
  }
  td {
    padding: 6px 9px;
    border-bottom: 1px solid #F1F5F9;
    vertical-align: top;
  }
  tr:nth-child(even) td {
    background: #FAFCFE;
  }

  /* Hero Mockup Card */
  .mockup-bar {
    background: var(--dark-bg);
    border-radius: 11px;
    padding: 11px 14px;
    color: #ffffff;
    display: flex;
    justify-content: space-around;
    text-align: center;
    margin: 12px 0 10px 0;
  }
  .mockup-item .val {
    font-size: 17pt;
    font-weight: 800;
    color: var(--orange-light);
    line-height: 1.1;
  }
  .mockup-item .label {
    font-size: 7.2pt;
    text-transform: uppercase;
    color: #94A3B8;
    letter-spacing: 0.06em;
    margin-top: 2px;
  }

  /* Cover Page Styling */
  .cover-container {
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: 8mm 4mm 4mm 4mm;
  }
  .cover-pill {
    display: inline-flex;
    align-items: center;
    gap: 7px;
    background: var(--orange-soft);
    border: 1.5px solid var(--orange-border);
    color: var(--orange-dark);
    padding: 4px 13px;
    border-radius: 999px;
    font-size: 8.8pt;
    font-weight: 700;
    margin-bottom: 14px;
  }
  .cover-title {
    font-size: 30pt;
    line-height: 1.12;
    font-weight: 800;
    color: var(--dark-bg);
    letter-spacing: -0.02em;
    margin-bottom: 10px;
  }
  .cover-title span {
    background: linear-gradient(135deg, var(--orange-primary) 0%, #EA580C 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  .cover-subtitle {
    font-size: 11.2pt;
    color: var(--slate-muted);
    font-weight: 500;
    max-width: 600px;
    line-height: 1.48;
    margin-bottom: 16px;
  }

  .cover-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 11px;
    margin: 12px 0;
  }
  .cover-card {
    background: #ffffff;
    border: 1.5px solid #E2E8F0;
    border-radius: 10px;
    padding: 12px 14px;
  }
  .cover-card h4 {
    font-size: 9.8pt;
    color: var(--dark-bg);
    margin-bottom: 4px;
    display: flex;
    align-items: center;
    gap: 7px;
  }
  .cover-card p {
    font-size: 8.4pt;
    color: var(--slate-muted);
    margin: 0;
    line-height: 1.44;
  }

  .cover-meta {
    background: #F8FAFC;
    border: 1px solid #E2E8F0;
    border-radius: 9px;
    padding: 10px 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 7.8pt;
    color: var(--slate-muted);
  }
</style>
</head>
<body>

<!-- ========================================================================= -->
<!-- PAGE 1: COVER & EXECUTIVE OVERVIEW                                        -->
<!-- ========================================================================= -->
<div class="page">
  <div class="cover-container">
    <div>
      <div class="cover-pill">
        <span>✨</span> User Guide & Functional Architecture
      </div>
      <h1 class="cover-title">RAPID <span>WRITE</span></h1>
      <h2 style="font-size: 16pt; font-weight: 700; color: #1E293B; margin-bottom: 8px;">The Human-Friendly Guide to Stylus Penmanship & Speed Evaluation</h2>
      <p class="cover-subtitle">
        Everything you need to know about the web app: how it measures your writing speed, how it reads your handwriting, how it grades your neatness, and how to practice like a pro.
      </p>

      <div class="callout callout-plain" style="margin-bottom: 14px;">
        <strong>💡 In Plain English:</strong> While typing test apps like <em>Monkeytype</em> exist for keyboards, there was no smart, elegant tool for tablets, digital pens, Apple Pencils, and Samsung S-Pens. <strong>RAPID WRITE</strong> bridges that gap. It lets you write on a digital notebook and gives you instant, friendly feedback on your speed, spelling accuracy, and handwriting beauty.
      </div>

      <div class="cover-grid">
        <div class="cover-card">
          <h4><span class="badge badge-orange">01</span> Physical Writing Speed</h4>
          <p>Measures how fast your hand physically moves across the glass (Words Per Minute & Characters Per Minute), separating pen-down writing from thinking pauses.</p>
        </div>
        <div class="cover-card">
          <h4><span class="badge badge-emerald">02</span> Neural Text Recognition</h4>
          <p>Transcribes cursive or print ink using neural digital ink AI. It compares what you wrote against the prompt to give you an exact Accuracy score.</p>
        </div>
        <div class="cover-card">
          <h4><span class="badge badge-blue">03</span> Handwriting Aesthetics</h4>
          <p>Assesses neatness, baseline alignment (staying straight), uniform slant angles, and smooth stroke curvature—awarding a clear letter grade (A+, A, B, C).</p>
        </div>
        <div class="cover-card">
          <h4><span class="badge badge-purple">04</span> Intelligent Coaching</h4>
          <p>Provides human-readable coaching tips to help you build fluid muscle memory, relax your grip, and write faster without sacrificing legibility.</p>
        </div>
      </div>
    </div>

    <div>
      <div class="mockup-bar">
        <div class="mockup-item">
          <div class="val">32.4</div>
          <div class="label">Net Speed (WPM)</div>
        </div>
        <div class="mockup-item">
          <div class="val">98.2%</div>
          <div class="label">OCR Accuracy</div>
        </div>
        <div class="mockup-item">
          <div class="val">92 / 100</div>
          <div class="label">Neatness Score</div>
        </div>
        <div class="mockup-item">
          <div class="val">Grade A</div>
          <div class="label">Aesthetic Tier</div>
        </div>
      </div>

      <div class="cover-meta">
        <div><strong>Document Version:</strong> 2.0 (Executive Edition)</div>
        <div><strong>App Target:</strong> Web, iPad, Android Tablets, Touch Laptops</div>
        <div><strong>Audience:</strong> Students, Educators, Note-Takers, Calligraphers</div>
      </div>
    </div>
  </div>
</div>

<!-- ========================================================================= -->
<!-- PAGE 2: THE 5-STEP CORE WORKFLOW                                          -->
<!-- ========================================================================= -->
<div class="page">
  <div class="page-header">
    <div class="brand">✦ RAPID WRITE</div>
    <div>CHAPTER 1: THE CORE APP WORKFLOW</div>
  </div>

  <div class="page-body">
    <h2>How the App Works: Step-by-Step</h2>
    <p style="color: var(--slate-muted); margin-bottom: 10px;">
      RAPID WRITE was designed to feel frictionless. You don't need a user account or complicated calibration. Here is what happens from the moment you open the app to your final evaluation:
    </p>

    <!-- Step 1 -->
    <div class="step-container">
      <div class="step-number">1</div>
      <div class="step-content">
        <div class="step-title">
          <span>Choose Your Practice Prompt</span>
          <span class="badge badge-orange">Header Bar</span>
        </div>
        <p>At the top of the screen sits the <strong>Interactive Prompt Card</strong>. Choose a sentence from classic pangrams (sentences testing every letter from A to Z like <em>"The quick brown fox jumps over the lazy dog"</em>), inspiring quotes, or specialized vocabulary decks.</p>
        <div style="font-size: 8.2pt; color: var(--slate-muted); background: #F8FAFC; padding: 5px 8px; border-radius: 6px;">
          ✔ <em>Quick Action:</em> Tap the <strong>Shuffle button</strong> (dice icon) to cycle through prompts, or switch to <strong>Zen Mode</strong> to write freely.
        </div>
      </div>
    </div>

    <!-- Step 2 -->
    <div class="step-container">
      <div class="step-number">2</div>
      <div class="step-content">
        <div class="step-title">
          <span>Set Up Your Canvas & Stationery</span>
          <span class="badge badge-blue">Canvas Toolbar</span>
        </div>
        <p>Just below the prompt is your floating digital stationery kit. Customize how your notebook feels:</p>
        <div class="grid-3" style="margin: 4px 0;">
          <div style="font-size: 8.2pt; background: #FFF7ED; padding: 5px 7px; border-radius: 5px; border: 1px solid #FFEDD5;">
            <strong>Paper Texture:</strong> Ruled lines, Isometric grid, or Blank paper.
          </div>
          <div style="font-size: 8.2pt; background: #EFF6FF; padding: 5px 7px; border-radius: 5px; border: 1px solid #DBEAFE;">
            <strong>Ink Palette:</strong> Midnight, Vibrant Blue, Emerald, Plum, Coral.
          </div>
          <div style="font-size: 8.2pt; background: #F5F3FF; padding: 5px 7px; border-radius: 5px; border: 1px solid #EDE9FE;">
            <strong>Nib Width:</strong> Fine (1.5px) for detail to Broad (5.0px) for markers.
          </div>
        </div>
        <div style="font-size: 8.2pt; color: #1E40AF; background: #EFF6FF; padding: 4px 7px; border-radius: 5px; margin-top: 3px;">
          🛡️ <strong>Hardware Palm Rejection:</strong> Resting your wrist on the glass while writing will not leave accidental ink marks or scroll!
        </div>
      </div>
    </div>

    <!-- Step 3 -->
    <div class="step-container">
      <div class="step-number">3</div>
      <div class="step-content">
        <div class="step-title">
          <span>Write Naturally on the Canvas</span>
          <span class="badge badge-emerald">Live Kinematics</span>
        </div>
        <p>The moment your stylus touches the paper, the app's <strong>silent stopwatch</strong> activates automatically. No start button needed! As you write:</p>
        <ul style="margin-left: 16px; font-size: 8.5pt; color: var(--slate-text);">
          <li>Captures exact millisecond timestamps and coordinates of every stroke.</li>
          <li>Separates <strong>Active Drawing Time</strong> (pen on glass) from <strong>Thinking Pauses</strong> (hovering or checking the next word).</li>
          <li>Tap <strong>Undo</strong> or use the <strong>Eraser</strong> if you make an accidental stroke.</li>
        </ul>
      </div>
    </div>

    <!-- Step 4 -->
    <div class="step-container">
      <div class="step-number">4</div>
      <div class="step-content">
        <div class="step-title">
          <span>Tap "Evaluate Writing"</span>
          <span class="badge badge-orange">Tri-Engine Analysis</span>
        </div>
        <p>When you finish your sentence, tap the radiant orange <strong>"Evaluate Writing"</strong> button. In under two seconds, the app computes Speed Math, OCR Recognition, and Aesthetic Geometry simultaneously.</p>
      </div>
    </div>

    <!-- Step 5 -->
    <div class="step-container" style="margin-bottom: 0;">
      <div class="step-number">5</div>
      <div class="step-content">
        <div class="step-title">
          <span>Review the Radiant Results Dashboard</span>
          <span class="badge badge-purple">Insight Sheet</span>
        </div>
        <p>A crisp sheet slides up showing your Net Speed (WPM), Accuracy %, Neatness grade, side-by-side text comparison, and tailored coaching tips. Tap <strong>Practice Next</strong> to challenge yourself again!</p>
      </div>
    </div>
  </div>

  <div class="page-footer">
    <div>RAPID WRITE • Official Application Guide</div>
    <div>Page 2 of 6</div>
  </div>
</div>

<!-- ========================================================================= -->
<!-- PAGE 3: THE 3 PILLARS OF EVALUATION                                       -->
<!-- ========================================================================= -->
<div class="page">
  <div class="page-header">
    <div class="brand">✦ RAPID WRITE</div>
    <div>CHAPTER 2: METRICS & EVALUATION DEMYSTIFIED</div>
  </div>

  <div class="page-body">
    <h2>The 3 Pillars of Handwriting Evaluation</h2>
    <p style="color: var(--slate-muted); margin-bottom: 10px;">
      Most apps only look at one thing—either speed or legibility. RAPID WRITE evaluates all three dimensions to give you a true, balanced reflection of your penmanship skill.
    </p>

    <!-- Pillar 1: Speed -->
    <div class="card card-highlight" style="margin-bottom: 10px;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
        <h3 style="margin: 0; color: var(--orange-dark);">🏃 Pillar 1: Speed & Physical Movement</h3>
        <span class="badge badge-orange">Kinematics</span>
      </div>
      <p style="font-size: 8.6pt;">How quickly you produce handwritten words. We calculate both raw speed and true speed:</p>
      
      <table>
        <thead>
          <tr>
            <th style="width: 24%;">Metric</th>
            <th style="width: 38%;">What it Means</th>
            <th style="width: 38%;">Why it Matters in Real Life</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Gross WPM</strong><br><span style="font-size: 7.2pt; color: var(--slate-muted);">Raw Words/Min</span></td>
            <td>Pure physical output speed: how many 5-character word chunks you finished in a minute, regardless of errors.</td>
            <td>Shows your pure motor ability and physical hand agility when moving the stylus.</td>
          </tr>
          <tr>
            <td><strong>Net WPM</strong><br><span style="font-size: 7.2pt; color: var(--emerald); font-weight: 700;">Your True Score</span></td>
            <td><strong>Gross WPM scaled by accuracy.</strong> If you wrote fast but missed half the letters, your Net WPM drops accordingly.</td>
            <td>The gold standard. Writing quickly is only useful if someone (or a computer) can actually read what you wrote!</td>
          </tr>
          <tr>
            <td><strong>Physical Velocity</strong><br><span style="font-size: 7.2pt; color: var(--slate-muted);">px / sec</span></td>
            <td>The actual distance the stylus tip traveled across your screen divided by active pen-down seconds.</td>
            <td>Helps calligraphers see if their hand is moving too hurriedly or too rigidly.</td>
          </tr>
          <tr>
            <td><strong>Active vs Pause Time</strong></td>
            <td>Separates the seconds your pen touched the glass from the moments you hovered or looked at the prompt.</td>
            <td>Reveals whether slow writing is caused by hesitant thinking or slow hand movement.</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pillar 2: Accuracy -->
    <div class="card" style="margin-bottom: 10px; border-color: #A7F3D0;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
        <h3 style="margin: 0; color: var(--emerald);">🎯 Pillar 2: Legibility & OCR Accuracy</h3>
        <span class="badge badge-emerald">Neural Recognition</span>
      </div>
      <p style="font-size: 8.6pt;">
        The app feeds your strokes into an optimized <strong>Google Digital Ink Neural Network</strong>. It checks how faithfully your handwriting represents the intended words:
      </p>
      <div class="grid-2">
        <div style="background: #F0FDF4; padding: 7px 9px; border-radius: 7px; border: 1px solid #BBF7D0; font-size: 8.2pt;">
          <strong style="color: #166534;">Character Accuracy (%):</strong><br>
          Compares letter-by-letter. Missing a letter, adding extra squiggles, or misforming a letter like writing 'u' instead of 'v' counts as an error.
        </div>
        <div style="background: #F0FDF4; padding: 7px 9px; border-radius: 7px; border: 1px solid #BBF7D0; font-size: 8.2pt;">
          <strong style="color: #166534;">Punctuation & Dot Preservation:</strong><br>
          Preserves all dots on <em>'i'</em> and <em>'j'</em>, commas, periods, and hyphens so your score is never penalized unfairly.
        </div>
      </div>
    </div>

    <!-- Pillar 3: Aesthetics -->
    <div class="card" style="border-color: #BFDBFE;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
        <h3 style="margin: 0; color: var(--blue-accent);">✍️ Pillar 3: Handwriting Aesthetics & Geometry</h3>
        <span class="badge badge-blue">Computer Vision</span>
      </div>
      <p style="font-size: 8.6pt;">
        Even if a sentence is readable, is it pleasant and tidy? The built-in computer vision engine checks 4 geometric qualities:
      </p>
      <div class="grid-2">
        <div style="font-size: 8.2pt; background: #F8FAFC; padding: 6px 8px; border-radius: 6px; border: 1px solid #E2E8F0;">
          <strong>1. Baseline Alignment:</strong> Do your words rest cleanly along an invisible horizontal line, or do they drift upwards like climbing a hill?
        </div>
        <div style="font-size: 8.2pt; background: #F8FAFC; padding: 6px 8px; border-radius: 6px; border: 1px solid #E2E8F0;">
          <strong>2. Slant Consistency:</strong> Whether your letters tilt forward (italic) or stand upright, are all tall letters tilted at the exact same angle?
        </div>
        <div style="font-size: 8.2pt; background: #F8FAFC; padding: 6px 8px; border-radius: 6px; border: 1px solid #E2E8F0;">
          <strong>3. Stroke Smoothness:</strong> Detects jitter or hand tremor. Confident, flowing curves score significantly higher than jagged strokes.
        </div>
        <div style="font-size: 8.2pt; background: #F8FAFC; padding: 6px 8px; border-radius: 6px; border: 1px solid #E2E8F0;">
          <strong>4. Pressure & Spacing:</strong> Checks for even space between adjacent words and letters so text doesn't look cramped or disconnected.
        </div>
      </div>
    </div>
  </div>

  <div class="page-footer">
    <div>RAPID WRITE • Official Application Guide</div>
    <div>Page 3 of 6</div>
  </div>
</div>

<!-- ========================================================================= -->
<!-- PAGE 4: PRACTICE MODES & VOCABULARY DECKS                                 -->
<!-- ========================================================================= -->
<div class="page">
  <div class="page-header">
    <div class="brand">✦ RAPID WRITE</div>
    <div>CHAPTER 3: PRACTICE MODES & VOCABULARY DECKS</div>
  </div>

  <div class="page-body">
    <h2>Tailor Your Practice: Modes & Decks</h2>
    <p style="color: var(--slate-muted); margin-bottom: 10px;">
      Different people write for different reasons. A medical student needs to write clinical terms fast; a calligrapher wants elegant rhythm; a school student wants neat handwriting on exams. RAPID WRITE offers tailored practice configurations to fit every goal.
    </p>

    <div class="grid-2" style="margin-bottom: 10px;">
      <div class="card">
        <h3 style="color: var(--dark-bg); font-size: 9.5pt; margin-bottom: 5px;">🧑‍🏫 Practice Modes</h3>
        <table style="margin: 0; font-size: 8pt;">
          <tr>
            <td><strong>Words Mode</strong></td>
            <td>Set a fixed word count (10, 25, 50, or 100 words). Perfect for daily drills with a consistent benchmark.</td>
          </tr>
          <tr>
            <td><strong>Timed Sprint</strong></td>
            <td>Write as much as you can in 15, 30, 60, or 120 seconds. Great for building stamina and test speed.</td>
          </tr>
          <tr>
            <td><strong>Quotes Mode</strong></td>
            <td>Practice inspiring quotes from literature and philosophy. Choose short, medium, or long passages.</td>
          </tr>
          <tr>
            <td><strong>Zen Flow</strong></td>
            <td>No prompt constraints! Free-form canvas where you can write journal thoughts, signatures, or poetry.</td>
          </tr>
          <tr>
            <td><strong>Custom Text</strong></td>
            <td>Paste your own study notes, textbook definitions, or vocabulary lists to practice whatever matters to you.</td>
          </tr>
        </table>
      </div>

      <div class="card">
        <h3 style="color: var(--dark-bg); font-size: 9.5pt; margin-bottom: 5px;">🎨 Specialized Vocabulary Decks</h3>
        <table style="margin: 0; font-size: 8pt;">
          <tr>
            <td><strong>Pangrams (A-Z)</strong></td>
            <td>Sentences featuring every alphabet letter (e.g. <em>Sphinx of black quartz</em>). Best for warm-ups.</td>
          </tr>
          <tr>
            <td><strong>Core English 1k</strong></td>
            <td>The most frequent words in English. Builds fast automatic muscle memory for everyday note-taking.</td>
          </tr>
          <tr>
            <td><strong>Tricky Misspelled</strong></td>
            <td>Words with silent letters (<em>accommodate, rhythm, bureaucracy</em>) to test hand-mind coordination.</td>
          </tr>
          <tr>
            <td><strong>Double-Letter</strong></td>
            <td>Focuses on double consonants (<em>assessment, parallel</em>) to train smooth cursive loops.</td>
          </tr>
          <tr>
            <td><strong>Medical</strong></td>
            <td>Clinical anatomical terms (<em>cerebellum, capillary</em>) for healthcare students and clinicians.</td>
          </tr>
          <tr>
            <td><strong>Tech & Code</strong></td>
            <td>Digital terminology (<em>algorithm, asynchronous</em>) for software engineers and STEM learners.</td>
          </tr>
        </table>
      </div>
    </div>

    <div class="callout callout-tip">
      <strong>🎯 Pro-Tip for Daily Practice:</strong> Start your session with <strong>Pangrams</strong> to warm up fingers on all 26 letters. Then switch to <strong>Core English 1k</strong> for speed sprints, and finish with a <strong>Quote</strong> to focus on neatness and straight baseline.
    </div>

    <div class="card" style="margin-top: 10px; background: #FAF5FF; border-color: #E9D5FF;">
      <h3 style="color: #6B21A8; font-size: 9.8pt; margin-bottom: 5px;">🔢 Challenge Modifiers: Punctuation & Numbers</h3>
      <p style="font-size: 8.5pt; color: #581C87; margin-bottom: 5px;">
        In real life, we don't just write lowercase letters. You can toggle two smart modifiers in the Prompt Bar:
      </p>
      <div class="grid-2">
        <div style="background: #ffffff; padding: 6px 9px; border-radius: 6px; border: 1px solid #D8B4FE; font-size: 8pt;">
          <strong>Punctuation Mode (+@):</strong> Injects quotation marks, commas, hyphens, and exclamation marks into prompts to test your rhythm when breaking between words.
        </div>
        <div style="background: #ffffff; padding: 6px 9px; border-radius: 6px; border: 1px solid #D8B4FE; font-size: 8pt;">
          <strong>Numbers Mode (+123):</strong> Injects numeric digits, percentages, and dates (e.g. <em>2026, 99%, #7, 24/7</em>) to train clean digit legibility.
        </div>
      </div>
    </div>
  </div>

  <div class="page-footer">
    <div>RAPID WRITE • Official Application Guide</div>
    <div>Page 4 of 6</div>
  </div>
</div>

<!-- ========================================================================= -->
<!-- PAGE 5: PRO-TIPS FOR BETTER PENMANSHIP & UNDER THE HOOD                   -->
<!-- ========================================================================= -->
<div class="page">
  <div class="page-header">
    <div class="brand">✦ RAPID WRITE</div>
    <div>CHAPTER 4: COACHING & TECHNICAL ARCHITECTURE</div>
  </div>

  <div class="page-body">
    <h2>Pro-Tips for Better Scores & Cleaner Handwriting</h2>
    <p style="color: var(--slate-muted); margin-bottom: 10px;">
      Whether your goal is to pass high-stakes handwritten exams or create gorgeous journal pages, these proven physical principles will instantly improve your RAPID WRITE scores:
    </p>

    <div class="grid-2" style="margin-bottom: 12px;">
      <div class="card" style="border-left: 4px solid var(--orange-primary);">
        <h3 style="font-size: 9.2pt; color: var(--dark-bg); margin-bottom: 3px;">1. Relax the Death-Grip</h3>
        <p style="font-size: 8.3pt; color: var(--slate-text); margin: 0;">
          Squeezing your stylus tightly causes early hand fatigue, jerky stroke curves, and reduced speed. Hold the pen lightly between thumb and index finger, resting on the middle finger. Let your forearm move the pen, not just your wrist.
        </p>
      </div>
      <div class="card" style="border-left: 4px solid var(--emerald);">
        <h3 style="font-size: 9.2pt; color: var(--dark-bg); margin-bottom: 3px;">2. Keep the Pen on Ruled Lines</h3>
        <p style="font-size: 8.3pt; color: var(--slate-text); margin: 0;">
          If you struggle with <em>Baseline Alignment</em>, switch the canvas paper style to <strong>Ruled</strong>. Let the baseline of your letters touch the printed line softly without bouncing above or below it.
        </p>
      </div>
      <div class="card" style="border-left: 4px solid var(--blue-accent);">
        <h3 style="font-size: 9.2pt; color: var(--dark-bg); margin-bottom: 3px;">3. Commit to One Slant Angle</h3>
        <p style="font-size: 8.3pt; color: var(--slate-text); margin: 0;">
          You don't have to write in italic cursive; straight vertical print is fine! What matters to the aesthetic engine is <strong>consistency</strong>. Don't tilt your 'd' forward while keeping your 't' straight.
        </p>
      </div>
      <div class="card" style="border-left: 4px solid var(--purple-accent);">
        <h3 style="font-size: 9.2pt; color: var(--dark-bg); margin-bottom: 3px;">4. Don't Sacrifice Clarity for Rush</h3>
        <p style="font-size: 8.3pt; color: var(--slate-text); margin: 0;">
          Remember that <strong>Net WPM</strong> penalizes mistakes. Writing at 30 WPM with 100% accuracy yields a higher Net score than writing at 45 WPM with 20% OCR recognition errors!
        </p>
      </div>
    </div>

    <h2 style="margin-top: 14px;">Under the Hood: How the Web App Works</h2>
    <p style="color: var(--slate-muted); margin-bottom: 8px;">
      Here is a quick look at the modern software engineering powering the application, explained simply:
    </p>

    <div class="card card-highlight">
      <div class="grid-3">
        <div>
          <strong style="color: var(--orange-dark); font-size: 8.8pt;">1. Interactive Frontend</strong>
          <p style="font-size: 8pt; color: var(--slate-text); margin-top: 3px;">
            Built with <strong>Flutter Web</strong> using custom canvas painters. Strokes are captured with 60 FPS precision, recording pressure, angle, and timing on iPads and Android tablets.
          </p>
        </div>
        <div>
          <strong style="color: var(--blue-accent); font-size: 8.8pt;">2. Smart Local Server</strong>
          <p style="font-size: 8pt; color: var(--slate-text); margin-top: 3px;">
            A lightweight Node.js server (<code>server.js</code>) serves web assets and acts as a dedicated <strong>CORS proxy</strong> for the Google Digital Ink API, allowing fast cloud recognition without browser blocks.
          </p>
        </div>
        <div>
          <strong style="color: var(--emerald); font-size: 8.8pt;">3. Hybrid AI Engine</strong>
          <p style="font-size: 8pt; color: var(--slate-text); margin-top: 3px;">
            Runs 100% offline-ready heuristic computer vision. Users can also enter an optional <strong>Google Gemini API Key</strong> in settings for multimodal calligraphic art critique!
          </p>
        </div>
      </div>
    </div>

    <div class="callout callout-tech" style="margin-top: 10px;">
      <strong>🔒 Privacy First:</strong> Your handwriting strokes are evaluated directly in your browser and on your local proxy server. Your personal handwritten notes are never permanently stored, indexed, or sold.
    </div>
  </div>

  <div class="page-footer">
    <div>RAPID WRITE • Official Application Guide</div>
    <div>Page 5 of 6</div>
  </div>
</div>

<!-- ========================================================================= -->
<!-- PAGE 6: QUICK REFERENCE, TROUBLESHOOTING & FAQ                            -->
<!-- ========================================================================= -->
<div class="page">
  <div class="page-header">
    <div class="brand">✦ RAPID WRITE</div>
    <div>CHAPTER 5: FREQUENTLY ASKED QUESTIONS & CHEAT SHEET</div>
  </div>

  <div class="page-body">
    <h2>Frequently Asked Questions (FAQ)</h2>
    <p style="color: var(--slate-muted); margin-bottom: 8px;">
      Clear, plain-English answers to the most common questions from users:
    </p>

    <div class="grid-2" style="margin-bottom: 10px;">
      <div class="card">
        <strong style="font-size: 8.8pt; color: var(--dark-bg);">Q: Why did my Net WPM come out lower than my Gross WPM?</strong>
        <p style="font-size: 8.2pt; color: var(--slate-text); margin-top: 3px;">
          Gross WPM is pure mechanical speed. If the OCR engine misread two of your words because of missing letters or untidy strokes, the system applies an error penalty. Focus on closing your 'o's and crossing your 't's to bring your Net WPM right up to your Gross WPM!
        </p>
      </div>
      <div class="card">
        <strong style="font-size: 8.8pt; color: var(--dark-bg);">Q: Does the app work with fingers or only with a stylus?</strong>
        <p style="font-size: 8.2pt; color: var(--slate-text); margin-top: 3px;">
          It works with both! However, for genuine handwriting evaluation, an active digital pen (Apple Pencil, Samsung S-Pen, Surface Pen) is recommended. If using a finger, turn off "Strict Stylus Mode" in the toolbar.
        </p>
      </div>
      <div class="card">
        <strong style="font-size: 8.8pt; color: var(--dark-bg);">Q: Can I practice cursive or only print script?</strong>
        <p style="font-size: 8.2pt; color: var(--slate-text); margin-top: 3px;">
          You can practice both! The Google Digital Ink model is trained on millions of cursive, print, and mixed samples. In fact, cursive writers often score higher on <em>Stroke Smoothness</em> and <em>Velocity</em>.
        </p>
      </div>
      <div class="card">
        <strong style="font-size: 8.8pt; color: var(--dark-bg);">Q: How do I share or save my evaluation report?</strong>
        <p style="font-size: 8.2pt; color: var(--slate-text); margin-top: 3px;">
          At the bottom of the Results Dashboard, tap the <strong>Share / Export</strong> button. On tablets, this triggers your native share sheet (AirDrop, Email). On web browsers, it copies a clean summary to your clipboard.
        </p>
      </div>
    </div>

    <h2>Quick Reference Score Card</h2>
    <table>
      <thead>
        <tr>
          <th>Grade</th>
          <th>Aesthetic Score</th>
          <th>Accuracy</th>
          <th>Visual Characteristics</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong style="color: #059669; font-size: 10.5pt;">A+</strong></td>
          <td>92 – 100</td>
          <td>98% – 100%</td>
          <td>Flawless calligraphic balance, laser-straight baseline, silky smooth curves, zero recognition errors.</td>
        </tr>
        <tr>
          <td><strong style="color: #059669; font-size: 10.5pt;">A</strong></td>
          <td>85 – 91</td>
          <td>92% – 97%</td>
          <td>Highly legible, graceful letterform rhythm, minor slant variations, pleasant uniform spacing.</td>
        </tr>
        <tr>
          <td><strong style="color: #D97706; font-size: 10.5pt;">B+</strong></td>
          <td>78 – 84</td>
          <td>85% – 91%</td>
          <td>Solid everyday handwriting, clear letterforms, occasional baseline drift or hurried connectors.</td>
        </tr>
        <tr>
          <td><strong style="color: #D97706; font-size: 10.5pt;">B</strong></td>
          <td>70 – 77</td>
          <td>75% – 84%</td>
          <td>Moderate neatness, recognizable words, noticeable slant inconsistencies or uneven word spacing.</td>
        </tr>
        <tr>
          <td><strong style="color: #DC2626; font-size: 10.5pt;">C</strong></td>
          <td>Below 70</td>
          <td>Below 75%</td>
          <td>Heavy hand jitter, frequent letter misrecognitions, wandering baseline. Recommended: practice with ruled lines.</td>
        </tr>
      </tbody>
    </table>

    <div style="background: linear-gradient(135deg, var(--orange-soft), #FFF); border: 1.5px solid var(--orange-border); border-radius: 10px; padding: 11px 15px; margin-top: 10px; text-align: center;">
      <h3 style="color: var(--orange-dark); font-size: 10.5pt; margin-bottom: 3px;">✨ Happy Writing & Keep Flowing! ✨</h3>
      <p style="font-size: 8.5pt; color: var(--slate-text); margin: 0;">
        Handwriting connects physical movement with creative thought. With just 5 to 10 minutes of daily practice in RAPID WRITE, you'll see dramatic improvements in both your penmanship speed and aesthetic poise.
      </p>
    </div>
  </div>

  <div class="page-footer">
    <div>RAPID WRITE • Official Application Guide</div>
    <div>Page 6 of 6</div>
  </div>
</div>

</body>
</html>
`;

async function generatePdf() {
  const outputPath = path.join(__dirname, 'RAPID_WRITE_User_Guide.pdf');
  const htmlPath = path.join(__dirname, 'RAPID_WRITE_User_Guide.html');

  fs.writeFileSync(htmlPath, htmlContent, 'utf8');
  console.log('Saved HTML documentation to:', htmlPath);

  console.log('Launching headless Microsoft Edge via puppeteer-core...');
  const browser = await puppeteer.launch({
    executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-gpu',
      '--run-all-compositor-stages-before-draw'
    ]
  });

  const page = await browser.newPage();
  await page.setContent(htmlContent, { waitUntil: 'networkidle0' });

  console.log('Rendering high-fidelity vector PDF...');
  await page.pdf({
    path: outputPath,
    format: 'A4',
    printBackground: true,
    margin: {
      top: '0mm',
      bottom: '0mm',
      left: '0mm',
      right: '0mm'
    }
  });

  await browser.close();
  console.log('Successfully generated PDF at:', outputPath);

  const stats = fs.statSync(outputPath);
  console.log('PDF File Size:', (stats.size / 1024).toFixed(1), 'KB');
}

generatePdf().catch(err => {
  console.error('Error generating PDF:', err);
  process.exit(1);
});
