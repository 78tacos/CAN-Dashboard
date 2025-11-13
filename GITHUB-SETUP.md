# GitHub Repository Setup - CAN Dashboard

## Step-by-Step Guide to Create GitHub Repository

### Option 1: Using GitHub Website (Easiest)

1. **Go to GitHub and create a new repository:**
   - Navigate to: https://github.com/new
   - Repository name: **`can-dashboard`**
   - Description: "Real-time CAN bus monitoring dashboard for electric train systems"
   - Set as Public or Private (your choice)
   - **DO NOT** initialize with README (we already have one)
   - Click "Create repository"

2. **Connect your local repository:**
   ```bash
   # Add the remote (replace YOUR_USERNAME with your GitHub username)
   git remote add origin https://github.com/YOUR_USERNAME/can-dashboard.git
   
   # Add all files
   git add .
   
   # Commit with a message
   git commit -m "Initial commit: CAN Dashboard with map visualization"
   
   # Push to GitHub
   git branch -M main
   git push -u origin main
   ```

### Option 2: Using Git Commands Only

```bash
# Initialize git (already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: CAN Dashboard with map visualization"

# Add remote (create the repo on GitHub first, then use this)
git remote add origin https://github.com/YOUR_USERNAME/can-dashboard.git

# Push
git branch -M main
git push -u origin main
```

---

## Repository Details

**Suggested Repository Name:** `can-dashboard`

**Suggested Description:**
```
Real-time CAN bus monitoring dashboard for electric train systems. 
Features OpenStreetMap integration, realistic battery physics, and 
WebSocket-based live data streaming.
```

**Topics/Tags to Add:**
- `can-bus`
- `socketcan`
- `websocket`
- `react`
- `python`
- `leaflet`
- `openstreetmap`
- `electric-vehicle`
- `real-time-monitoring`
- `dashboard`

---

## What's Included in This Repository

✅ Real-time CAN bus monitoring  
✅ Interactive OpenStreetMap with train route  
✅ Realistic battery physics (Ah, voltage, current)  
✅ WebSocket communication  
✅ Docker support  
✅ Cross-platform installers (Windows, Linux, macOS)  
✅ Comprehensive documentation  

---

## After Creating the Repository

### Update Remote URL (if needed)
```bash
# Check current remote
git remote -v

# Change remote URL if needed
git remote set-url origin https://github.com/YOUR_USERNAME/can-dashboard.git
```

### Push Future Changes
```bash
# Add changes
git add .

# Commit
git commit -m "Your commit message"

# Push
git push
```

---

## Repository Settings Recommendations

### About Section
- Add description
- Add website (if you deploy it)
- Add topics/tags

### Branch Protection (Optional)
- Protect `main` branch
- Require pull request reviews
- Enable status checks

### GitHub Pages (Optional)
If you want to host the standalone HTML:
1. Go to Settings → Pages
2. Source: Deploy from branch
3. Branch: `main` / `root`
4. Your site will be at: `https://YOUR_USERNAME.github.io/can-dashboard/`

---

## Quick Reference Commands

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/can-dashboard.git

# Check status
git status

# View commit history
git log --oneline

# Create new branch
git checkout -b feature-name

# Switch branches
git checkout main

# Pull latest changes
git pull

# Push changes
git push
```

---

*Repository Name: **can-dashboard***  
*Project Name: **CAN Dashboard***  
*Updated: November 12, 2025*
