# DevOps Lab: CI/CD to AWS with Terraform (practice version)

A practice project that mirrors the shape of the challenge: a small React app,
a PR-gated CI pipeline, and a CD pipeline that deploys two isolated
environments (`devel`, `stage`) to private S3 + CloudFront with access logs.

Work through it in phases. Don't time yourself on the first pass; learn it.
Phase 7 is the timed rehearsal.

```
feature/* ──PR──▶ devel ──PR──▶ stage
   │               │              │
   CI on PR        CD: deploy     CD: deploy
                   devel env      stage env
```

## What's in the repo

| Path | What it is |
|---|---|
| `src/`, `index.html` | Tiny React app (Vite). Same npm scripts as the challenge: `lint`, `test`, `build` |
| `.github/workflows/ci.yml` | Runs on PRs: branch rules, install → lint → test → build, Terraform checks |
| `.github/workflows/cd.yml` | Runs on push to `devel`/`stage`: Terraform apply, S3 upload, cache invalidation |
| `.github/workflows/destroy.yml` | Manual teardown of one environment |
| `infra/bootstrap/` | One-time: state bucket, GitHub OIDC provider, deploy role (local state) |
| `infra/` | Root config, called once per environment with its own state key |
| `infra/modules/static-site/` | The reusable module: site bucket, log bucket, OAC, CloudFront |

**Mental model.** CloudFront + OAC is a reverse proxy in front of a backend
whose firewall only accepts the proxy. The S3 bucket is never public; the
bucket policy says "only this distribution may read".

---

## Phase 0: Tools and accounts (≈30 min, once)

- [ ] AWS account. Create a **budget alarm** (Billing → Budgets, e.g. $5).
- [ ] Install: `git`, Node 20+, `terraform` ≥ 1.10, `aws` CLI v2, `gh` CLI.
- [ ] `aws configure` with an admin-ish user for the bootstrap
      (only your laptop uses these keys; GitHub never sees them).
- [ ] `aws sts get-caller-identity` works.
- [ ] `gh auth login` works.

**Cost:** S3 + CloudFront for a tiny site is cents. The real risk is
forgetting things running, which is why Phase 8 exists.

---

## Phase 1: Run the app locally (≈15 min)

```bash
npm install          # also creates package-lock.json — commit it, CI caches on it
npm run lint
CI=true npm run test
npm run build        # output goes to dist/
npm run preview      # open the URL it prints
```

**Checkpoint:** all four commands succeed and `dist/` has `index.html` plus
an `assets/` folder with hashed file names.

**Understand:** why are the asset names hashed? (Look at the `cd.yml` upload
step: hashed files get a 1-year cache, `index.html` gets `no-cache`.)

---

## Phase 2: Repo and branches (≈15 min)

```bash
terraform fmt -recursive infra   # normalizes formatting so the CI fmt check passes
git init -b devel
git add . && git commit -m "Initial commit"
gh repo create devops-lab --private --source=. --push
git push -u origin devel
git checkout -b stage && git push -u origin stage && git checkout devel
```

- [ ] On GitHub: **Settings → General → Default branch = `devel`**.

**Checkpoint:** two branches, `devel` is default.

---

## Phase 3: CI and branch protection (≈45 min)

CI is already in `ci.yml`. Read it top to bottom first, then:

1. Open a first PR so GitHub learns the check names:
   ```bash
   git checkout -b feature/readme-badge
   echo "Practice repo for CI/CD with Terraform." >> README.md
   git add README.md && git commit -m "Add README" && git push -u origin HEAD
   gh pr create --base devel --fill
   ```
2. Watch the checks: `Branch rules`, `Install, lint, test, build`,
   `Terraform fmt and validate`. Open the run and look at the **summary table**.
3. **Settings → Rules → Rulesets → New branch ruleset**, target `devel` and `stage`:
   - Restrict deletions; Block force pushes
   - Require a pull request before merging (approvals: 0 if you're solo; say why on camera)
   - Require status checks to pass: add the three checks above
   - Do **not** add yourself to the bypass list
4. Try `git push origin devel` directly from a local commit. It must be **rejected**.
5. Merge the PR.

**Checkpoint:** direct push rejected; PR merged only after green checks.

**Note:** CD will also run on that merge and fail, because AWS isn't wired up yet.
That's expected; Phase 5 fixes it.

**Understand:** why do lint/test/build each run even if a previous one
failed? (Look at the `if:` on each step.) A reviewer gets all the feedback
from one run instead of fixing one thing at a time.

---

## Phase 4: Bootstrap AWS (≈30 min)

```bash
cd infra/bootstrap
cp terraform.tfvars.example terraform.tfvars   # edit: bucket name, your GitHub user, repo
terraform init
terraform apply
terraform output
```

If you get "EntityAlreadyExists" for the OIDC provider, your account already
has it. Set `create_oidc_provider = false` and apply again.

Copy the three outputs into **GitHub → Settings → Secrets and variables →
Actions → Variables** (they're not secret, so use Variables, not Secrets):

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN` | from output |
| `TF_STATE_BUCKET` | from output |
| `AWS_REGION` | `us-east-1` |

Then **Settings → Environments**, create `devel` and `stage`.
(Optional: on `stage`, add yourself as required reviewer to see an approval gate.)

**Keep `infra/bootstrap/terraform.tfstate`** safe. It's local and gitignored.

**Understand:** open `bootstrap/main.tf` and find the trust policy. Which
GitHub jobs can assume the role? Only jobs in *your* repo that declare
`environment: devel` or `environment: stage`. That's why `cd.yml` sets
`environment:`.

---

## Phase 5: First deploy, by hand (≈30 min)

Deploy `devel` from your laptop once, so you see each step before automating it:

```bash
cd infra
terraform init \
  -backend-config="bucket=<TF_STATE_BUCKET>" \
  -backend-config="key=devops-lab/devel/terraform.tfstate" \
  -backend-config="region=us-east-1"
terraform plan  -var-file=envs/devel.tfvars
terraform apply -var-file=envs/devel.tfvars     # CloudFront takes ~5–15 min
terraform output
```

Upload and open:
```bash
cd .. && VITE_APP_ENV=devel npm run build
aws s3 sync dist/ s3://$(terraform -chdir=infra output -raw site_bucket) --delete
open "$(terraform -chdir=infra output -raw site_url)"    # or paste into a browser
```

**Checkpoint:** the site shows the **Development** badge.

**Security checks (do these, they make great on-camera moments):**
- `curl -I https://<site-bucket>.s3.amazonaws.com/index.html` → **403**. Bucket is private.
- `curl -I http://<cloudfront-domain>/` → **301** to https.
- `curl -I https://<cloudfront-domain>/some/route` → **200** (SPA fallback).
- After a few minutes of browsing: `aws s3 ls s3://<logs-bucket>/cloudfront/` shows `.gz` log files
  (delivery can take 5–30 minutes; don't panic).

**Understand:** you just did by hand everything `cd.yml` does. Now compare
them line by line.

---

## Phase 6: Full flow through the pipelines (≈45 min)

Create these PRs. They are your "sample PRs" for the challenge.

| # | Branch → base | Change | Expected |
|---|---|---|---|
| 1 | `feature/new-subtitle` → `devel` | Edit the `<p>` text in `App.jsx` | ✅ all green, merge, CD deploys devel |
| 2 | `bugfix/lint-demo` → `devel` | Add `const unused = 1;` in `greeting.js` | ❌ Lint fails, test/build still report. Fix with a second commit → ✅ |
| 3 | `feature/break-test` → `devel` | Change `'Staging'` to `'Stage'` in `greeting.js` | ❌ Test fails |
| 4 | `my-change` → `devel` | anything | ❌ Branch rules: bad name |
| 5 | `feature/sneaky` → `stage` | anything | ❌ Branch rules: stage only from devel |
| 6 | `devel` → `stage` | (`gh pr create --base stage --head devel`) | ✅ merge, CD deploys **stage** |

After #1 and #6, open both URLs: **Development** and **Staging** badges, two
separate distributions, two separate state files.

Leave #2–#5 open (or close without merging) so you can show them later.

**Understand:**
- Where is each environment's state? `aws s3 ls s3://<TF_STATE_BUCKET>/devops-lab/ --recursive`
- What stops two deploys colliding? `concurrency:` in `cd.yml` plus the S3 lock file.

---

## Phase 7: Timed rehearsal (60 min, record yourself)

Destroy both environments (Phase 8). Then create a **new empty repo** with only
the app code (`src/`, `index.html`, configs, `package.json`) and rebuild the
workflows, Terraform and rulesets with a timer and screen recorder on. Keep the
bootstrap (state bucket and role; just add the new repo name to the trust policy).
Look at this repo only when you're stuck, and note where.
Talk out loud the whole time. Suggested pacing:

| Minutes | Goal |
|---|---|
| 0–5 | Explain the plan and architecture (draw the diagram above) |
| 5–15 | CI workflow + branch rules; open first PR |
| 15–30 | Terraform module + root; **start `terraform apply` for both envs early** |
| 30–40 | CD workflow while CloudFront deploys; rulesets |
| 40–52 | Run the sample PRs; show green and red runs; open both URLs |
| 52–60 | Show logs bucket, security checks, recap, mention destroy workflow |

Then watch the recording. Note where you went silent or got stuck. Repeat
until it fits in about 50 minutes; the extra 10 is your buffer.

**Phrases worth having ready:**
- "I use OIDC so there are no long-lived AWS keys in GitHub."
- "Each environment has its own state file, so they're isolated blast radiuses."
- "The bucket is private; only this distribution can read it via OAC."
- "CI must pass before merge; CD only runs on protected branches, so nothing unreviewed is deployed."
- "In a real team I'd require 1–2 approvals and CODEOWNERS; solo, GitHub won't let me approve my own PR."

---

## Phase 8: Cleanup (do it every time)

**Actions → Destroy environment → Run workflow**, once for `devel` and once
for `stage`. Run it from the matching branch if you added branch restrictions
to the GitHub Environments. CloudFront deletion takes a while; that's normal.

When you're completely done with the lab:
```bash
cd infra/bootstrap
# empty the versioned state bucket first (Console → bucket → Empty), then:
terraform destroy
```

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | Repo/owner typo in bootstrap tfvars, or the job has no `environment:` |
| `setup-node` error about lock file | `package-lock.json` not committed |
| Log bucket error mentioning ACLs | Ownership must be `BucketOwnerPreferred` (already in the module; check you didn't change it) |
| Site shows AccessDenied XML | Bucket policy not applied yet, or files uploaded to the wrong bucket |
| Old content after deploy | Invalidation still running (1–2 min) or browser cache; check `index.html` has `no-cache` |
| Required checks never appear in the ruleset picker | They only show after they've run at least once on a PR |
| `Error acquiring the state lock` | A previous run died mid-apply; check no run is active, then `terraform force-unlock <id>` |
