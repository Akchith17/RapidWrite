# RapidWrite Handwriting Aesthetic Evaluation Algorithm: Formal Specification

**System**: RapidWrite  
**Algorithm**: Five-Stage Multi-Dimensional Aesthetic Evaluator  
**Authors**: RapidWrite Research Team  
**Scope**: Stylus Input, On-Device Digital Ink, and Computer Vision Image Segmentation  

---

## 1. Mathematical Formulation of the 5 Stages

### Stage 1: Repeated Letters & Common Stroke Patterns

Given an ordered sequence of detected glyph bounding boxes $\mathcal{G} = \{g_1, g_2, \dots, g_N\}$ and target sentence character list $\mathcal{T} = [c_1, c_2, \dots, c_M]$:

1. **Glyph-to-Character Mapping**:
   $$\text{char\_idx}(i) = \min\left(M - 1, \; \left\lfloor \frac{i}{N} \cdot M \right\rfloor \right)$$
   $$g_i \mapsto c_{\text{char\_idx}(i)}$$

2. **Repeated Character Subsets**:
   For key repeated characters $\alpha \in \{e, t, s, a, o, r, l, d\}$:
   $$\mathcal{G}_\alpha = \{g_i \in \mathcal{G} \mid g_i \mapsto \alpha\}$$

3. **Intra-Letter Variance**:
   $$\text{MAD}(H_\alpha) = \operatorname{median}\left(\left|h - \operatorname{median}(H_\alpha)\right|\right), \quad \forall h \in \{g.height \mid g \in \mathcal{G}_\alpha\}$$
   $$\text{MAD}(\Theta_\alpha) = \operatorname{median}\left(\left|\theta - \operatorname{median}(\Theta_\alpha)\right|\right), \quad \forall \theta \in \{g.slant \mid g \in \mathcal{G}_\alpha\}$$

---

### Stage 2: Geometric & Spatial Feature Extraction

1. **Central Moments & Slant Angle**:
   For pixel intensity distribution $I(x, y)$ of a binary glyph component:
   $$\mu_{p, q} = \sum_{x} \sum_{y} (x - \bar{x})^p (y - \bar{y})^q I(x, y)$$
   The principal axis slant orientation in degrees relative to vertical is:
   $$\theta = \frac{1}{2} \operatorname{atan2}\left(2\mu_{11}, \; \mu_{20} - \mu_{02}\right) - 90^\circ$$

2. **Baseline Drift ($\sigma_{\text{baseline}}$)**:
   For contact points $(x_i, y_i + h_i)$ along text line $\mathcal{L}$:
   Fit linear regression $y = \beta_1 x + \beta_0$:
   $$\beta_1 = \frac{\sum (x_i - \bar{x})(y_i - \bar{y})}{\sum (x_i - \bar{x})^2}, \quad \beta_0 = \bar{y} - \beta_1 \bar{x}$$
   The baseline drift is measured by the robust standard deviation of residuals:
   $$\sigma_{\text{baseline}} = 1.4826 \times \operatorname{median}\left(\left| (y_i + h_i) - (\beta_1 x_i + \beta_0) \right|\right)$$

3. **Inter-Glyph Spacing**:
   $$\Delta x_i = x_{i+1} - (x_i + w_i), \quad \text{for } x_{i+1} \ge x_i$$
   $$S_{\text{median}} = \operatorname{median}(\Delta x), \quad \text{MAD}_S = \operatorname{median}(|\Delta x - S_{\text{median}}|)$$

---

### Stage 3: Personal Reference Profile Construction

The profile represents the student's personal handwriting style:
$$\mathcal{P}_{\text{user}} = \left\{ (M_H, \text{MAD}_H), \; (M_\Theta, \text{MAD}_\Theta), \; (M_S, \text{MAD}_S), \; (\sigma_{\text{base}}, \tau_{\text{base}}) \right\}$$
Natural personal tolerance intervals are defined as:
$$\mathcal{I}_{\text{natural}}(X) = [M_X - 2.0 \cdot \text{MAD}_X, \; M_X + 2.0 \cdot \text{MAD}_X]$$

---

### Stage 4: Deviation Analysis from Personal Baseline

For any subsequent practice sample with current features $x_{\text{current}}$:
$$Z_X = \frac{|x_{\text{current}} - M_{X, \text{ref}}|}{1.4826 \times \max(0.5, \text{MAD}_{X, \text{ref}})}$$

- **Fairness Filter**:
  $$\text{Penalty}(Z_X) = \begin{cases} 
  0, & \text{if } Z_X \le 1.5 \\
  w_X \cdot (Z_X - 1.5), & \text{if } Z_X > 1.5 
  \end{cases}$$

---

### Stage 5: Consistency Evaluation & Multi-Dimensional Scoring

1. **Alignment Score**:
   $$\text{Score}_{\text{align}} = \operatorname{clamp}\left(30, 99, \; 100 - \left(\frac{\sigma_{\text{base}}}{\kappa_{\text{cohort}}}\right) \times 2.8\right)$$
   Where $\kappa_{\text{cohort}} = 1.55$ for Elementary / Middle School on unlined paper, and $1.0$ for Senior on lined paper.

2. **Slant Consistency Score**:
   $$\text{Score}_{\text{slant}} = \operatorname{clamp}\left(30, 99, \; 100 - \text{MAD}_\Theta \times \lambda_{\text{slant}}\right)$$

3. **Spacing Score**:
   $$\text{Score}_{\text{spacing}} = \operatorname{clamp}\left(30, 98, \; 100 - \text{MAD}_S \times \lambda_{\text{spacing}}\right)$$

4. **Letter Formation Score**:
   $$\text{Score}_{\text{formation}} = \operatorname{clamp}\left(30, 98, \; (100 - \text{MAD}_H \cdot \lambda_H) + B_{\text{formation}}\right)$$

5. **Readability Score**:
   $$\text{Score}_{\text{readability}} = \operatorname{clamp}\left(35, 99, \; (0.35 \cdot \text{Score}_{\text{align}} + 0.40 \cdot \text{Score}_{\text{formation}} + 0.25 \cdot \text{Score}_{\text{spacing}}) \times \gamma_{\text{scale}}\right)$$

6. **Consistency Score**:
   $$\text{Score}_{\text{consistency}} = \operatorname{clamp}\left(30, 98, \; (0.50 \cdot \text{Score}_{\text{slant}} + 0.50 \cdot (100 - \text{MAD}_H \cdot \lambda_H)) - \sum \text{Penalty}(Z)\right)$$

7. **Visual Organization Score**:
   $$\text{Score}_{\text{org}} = \operatorname{clamp}\left(35, 98, \; 0.50 \cdot \text{Score}_{\text{align}} + 0.30 \cdot \text{Score}_{\text{spacing}} + 0.20 \cdot \text{Score}_{\text{consistency}}\right)$$

8. **Overall Composite Aesthetic Score**:
   $$\text{Score}_{\text{overall}} = 0.22 \cdot \text{Score}_{\text{readability}} + 0.18 \cdot \text{Score}_{\text{formation}} + 0.18 \cdot \text{Score}_{\text{align}} + 0.16 \cdot \text{Score}_{\text{consistency}} + 0.14 \cdot \text{Score}_{\text{spacing}} + 0.12 \cdot \text{Score}_{\text{org}}$$

---

## 2. Letter Grade Calibration Thresholds

| Grade Range | Letter Grade | Qualitative Assessment |
| :---: | :---: | :--- |
| **92.0 – 100.0** | **A+** | Exemplary penmanship rhythm, flawless baseline alignment, and uniform letter formations. |
| **85.0 – 91.9** | **A** | Fluid, disciplined script with excellent readability and controlled stroke cadence. |
| **78.0 – 84.9** | **B+** | Strong consistent handwriting cadence with minor natural variation. |
| **70.0 – 77.9** | **B** | Solid readability and legible letterforms with developing baseline consistency. |
| **60.0 – 69.9** | **C+** | Legible script displaying noticeable baseline drift or fluctuating letter heights. |
| **< 60.0** | **C** | Developing penmanship foundations requiring focus on letter spacing and baseline stability. |
