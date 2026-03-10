# First Push

This directory is initialized as a local Git repository.

## Recommended first commit

```bash
cd /Users/yunhao/haoclaw-src
git add .
git commit -m "Initial Haoclaw import"
```

## Connect to GitHub

```bash
git remote add origin git@github.com:<your-name>/haoclaw.git
git push -u origin main
```

If you prefer HTTPS:

```bash
git remote add origin https://github.com/<your-name>/haoclaw.git
git push -u origin main
```

## Before pushing

Quick checks:

```bash
node scripts/run-node.mjs --help
zsh -lc 'haoclaw health'
```

## After pushing

- Open the `Actions` tab and confirm the standard GitHub-hosted workflows start normally.
- If you plan to publish images or tagged releases, read `RELEASING.md`.

## Notes

- `node_modules/` and `dist/` are ignored and should not be committed.
- `pnpm-lock.yaml` is tracked and should be included in the first push.
