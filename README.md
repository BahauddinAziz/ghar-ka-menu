# Ghar Ka Menu — Kya Banaye?

A tiny meal-decision tracker for the kitchen. Single HTML file, no backend,
no database — everything is saved in the browser (localStorage) on each
person's phone.

## What it does

- **Suggest**: pick "Jhatpat" (quick, no prep) or "Time hai" (anything),
  tap Suggest, and it serves up the dish you've cooked least recently.
- **Track**: tap "Bana!" on any dish to log that you cooked it today
  (tap again to undo). Shows last-cooked and this-month counts.
- **Manage**: add new dishes (with prep notes for plan-ahead ones), remove old ones.

## Run locally

Just open `index.html` in a browser. That's it.

## Deploy on DigitalOcean App Platform (free static site tier)

App Platform deploys from a GitHub repo, so it's a 3-step flow:

### 1. Push this folder to GitHub

```bash
cd ghar-ka-menu
git init && git add . && git commit -m "ghar ka menu"
# create a repo named ghar-ka-menu on GitHub, then:
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/ghar-ka-menu.git
git push -u origin main
```

(If you have the GitHub CLI: `gh repo create ghar-ka-menu --public --source=. --push`)

### 2. Edit the app spec

Open `.do/app.yaml` and replace `YOUR_GITHUB_USERNAME` with your GitHub username.

> First time only: DigitalOcean needs permission to read your GitHub repos.
> Easiest is to authorize once via the DO dashboard (Apps → Create App → GitHub),
> or run the create command below and follow the link in the error message.

### 3. Create the app with doctl

```bash
doctl apps create --spec .do/app.yaml
```

Check status / get your URL:

```bash
doctl apps list
```

You'll get a URL like `https://ghar-ka-menu-xxxxx.ondigitalocean.app`.
Open it on your phone and "Add to Home Screen" — now it lives next to
your other apps. Every `git push` auto-deploys.

## Costs

Static sites on App Platform: the first 3 are on the free tier
($0, at the time of writing). This app is one static file, so it qualifies.

## Notes

- Data is per-device (localStorage). Your phone and your partner's phone
  each keep their own log. If you want one shared log for the whole family,
  that needs a small backend — easy upgrade later.
- Region in the spec is `blr` (Bangalore). Change if you like.
