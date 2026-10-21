# 🌐 24/7 Online Deployment Guide for RAPID WRITE

Your project is now fully configured for **24/7/365 cloud hosting** with zero hosting fees.

---

## ⚡ Option 1: Cloudflare Pages (Recommended — Never Sleeps, Ultra Fast)

Cloudflare Pages provides permanent 24/7 uptime on Cloudflare's global edge network with **zero cold starts** (it will never spin down or pause).

### 🚀 Instant Deployment via Command Line (under 2 minutes)

1. **Log in to Cloudflare:**
   Open a terminal in this directory and run:
   ```cmd
   npx wrangler login
   ```
   *(A browser tab will open asking you to authorize Cloudflare. Click "Allow".)*

2. **Deploy the live app:**
   ```cmd
   npm run deploy:cloudflare
   ```
   *(Or run: `npx wrangler pages deploy build/web --project-name rapid-write`)*

3. **Done!** Wrangler will output your permanent 24/7 production URL:
   ```
   ✨ Success! Uploaded files to Cloudflare Pages
   🌎 Deployment complete! Take a peek over at https://rapid-write.pages.dev
   ```

### 🔗 Alternative: Connect via GitHub (Automatic Updates on push)
1. Push your repository to GitHub:
   ```bash
   git remote add origin https://github.com/<YOUR-USERNAME>/<REPO-NAME>.git
   git branch -M main
   git push -u origin main
   ```
2. Go to **[Cloudflare Dashboard](https://dash.cloudflare.com/)** &rarr; **Workers & Pages** &rarr; **Create application** &rarr; **Pages** &rarr; **Connect to Git**.
3. Select your repo and configure:
   - **Framework preset**: `None`
   - **Build output directory**: `build/web`
4. Click **Save and Deploy**. Any future git pushes will auto-deploy!

---

## 🚀 Option 2: Render.com (Node.js Server)

Render runs your native `server.js` directly.

1. Push your code to GitHub (see above).
2. Go to **[Render.com Dashboard](https://dashboard.render.com/)** and click **New +** &rarr; **Web Service**.
3. Connect your GitHub repository.
4. Render will auto-read `render.yaml` or you can verify:
   - **Environment**: `Node`
   - **Build Command**: `npm install` (or leave empty)
   - **Start Command**: `node server.js`
5. Click **Create Web Service**. Your app will be live at `https://rapid-write-evaluator.onrender.com`.

> **💡 Keeping Render Awake 24/7:**
> Render's free tier enters sleep mode after 15 minutes of inactivity. To keep it awake 24/7 with zero spin-down delay:
> 1. Sign up for free at **[cron-job.org](https://cron-job.org)** or **[UptimeRobot](https://uptimerobot.com)**.
> 2. Create a HTTP monitor to ping your Render URL every **10 minutes**. This prevents Render from ever sleeping.

---

## 🛠️ What has been configured for you:
- [x] **`server.js`**: Updated to support `process.env.PORT` dynamically for cloud hosting.
- [x] **`package.json`**: Created with automated start and Cloudflare deploy scripts.
- [x] **`functions/api/handwriting.js`**: Created Cloudflare Edge function to proxy Google Digital Ink Handwriting recognition with full CORS support.
- [x] **`build/web/_redirects` & `_headers`**: Configured SPA routing and high-performance WebAssembly (`canvaskit.wasm`) caching headers.
- [x] **`render.yaml`**: Pre-configured Render blueprint for 1-click deployment.
- [x] **Git Repository**: Initialized with `.gitignore` and committed with production build included.
