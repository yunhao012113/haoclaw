# Releasing Haoclaw

This fork can be published from a normal GitHub repository without custom CI runners.

## What already exists

- CI runs on pushes to `main` and pull requests
- Docker release workflow publishes images to `ghcr.io/<owner>/<repo>`
- package metadata is already branded as `haoclaw`

## Before your first public release

1. Push the repository to GitHub.
2. Open `Actions` and confirm CI passes on `main`.
3. Decide your public repository path:
   - `github.com/<your-name>/haoclaw`
   - or an org-owned repo if this is a team project
4. Review these files:
   - `package.json`
   - `appcast.xml`
   - `scripts/make_appcast.sh`
   - `.github/workflows/docker-release.yml`

## GitHub release flow

Create and push a semantic tag:

```bash
cd /Users/yunhao/haoclaw-src
git tag v2026.3.9
git push origin v2026.3.9
```

Recommended follow-up:

1. Open GitHub Releases.
2. Draft a release for the new tag.
3. Copy the relevant changelog notes.
4. Attach any packaged artifacts you want users to download directly.

## Container images

The Docker release workflow is set to publish to:

```text
ghcr.io/<github-owner>/<github-repo>
```

On `main`, it publishes branch tags.
On `v*` tags, it publishes versioned tags.

To use GitHub Container Registry successfully:

- keep GitHub Actions enabled
- keep package permissions enabled for the repository
- make sure the repository owner is allowed to publish packages

## NPM publishing

This repository is not yet configured with a dedicated npm publish workflow.

If you want `npm install -g haoclaw` to work for others, you still need to decide:

- whether the package name `haoclaw` will be published publicly
- whether you want public npm releases or GitHub-only source installs
- which build artifacts must be included in the published package

Before publishing to npm, run:

```bash
cd /Users/yunhao/haoclaw-src
pnpm install
pnpm build
pnpm release:check
npm pack --dry-run
```

## Practical recommendation

For the first public release, keep it simple:

1. publish the GitHub repository
2. verify CI
3. cut a Git tag
4. publish a GitHub Release
5. add npm publishing only after the package contents are stable
