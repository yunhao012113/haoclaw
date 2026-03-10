# Upload To GitHub

This source tree is ready to be uploaded as a GitHub repository.

## Recommended upload source

Use the clean archive generated alongside this repo:

- `~/haoclaw-github-upload.tar.gz`

It excludes local build/output directories such as:

- `node_modules/`
- `ui/node_modules/`
- `dist/`
- `.DS_Store`

## Suggested repository name

- `haoclaw`

## First push checklist

1. Create an empty GitHub repository.
2. Extract `haoclaw-github-upload.tar.gz`.
3. Upload the extracted files to the repository root.
4. Set the default branch to `main`.
5. Review these files first:
   - `README.md`
   - `package.json`
   - `haoclaw.mjs`
   - `scripts/run-node.mjs`

## After upload

Run locally from the uploaded checkout:

```bash
pnpm install
node scripts/run-node.mjs --help
node scripts/run-node.mjs gateway
```

## Current known status

- Branding has been renamed to `haoclaw`.
- CLI and gateway were verified locally.
- Agent execution reaches model calls, but your model/backend settings still need to be validated in the target environment.
