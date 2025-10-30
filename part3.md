[Part 1](README.md)    [Part 2](part2.md)    Part 3

# Part 3 — GitHub Actions Tutorial (Step‑by‑Step to Full `ci.yml`)

This tutorial walks you through building your first **Continuous Integration (CI)** workflow for the Wordguesser app — step by step, from nothing to a complete pipeline with automated deployment.  
Each section explains *what to add*, *why it matters*, and *how to verify* it in GitHub Actions.

## Prerequisites
Before you begin:
- You completed **Part 2** (Dockerfile and docker-compose work locally).
- Your repo includes a `Gemfile` and `Gemfile.lock` that install and run correctly in your container.
- You have a branch named `main` (your CI workflow will trigger when you push to it).

## What to do
- First, complete the tutorial steps.
- When you're done, create a feature branch and make some small edits to the program. You can change some of the UI in the `.erb` files in the `view/` folder, or change the game logic in `lib/wordguesser_game.rb`, etc.
- Push your branch to your github fork.
- Open a pull request to merge your branch into main (on your repo, not CitadelCS).
- Merge the pull request.

## What to submit
Create a simple submission document with the following items and submit it to Canvas.
- 1-2 paragraphs responding to some of the reflection prompts at the end of this tutorial. (You may reflect on some other observation or experience if you prefer.)
- A screenshot of the workflow run of your merged pull request. Get to this from the Actions tab. Make sure the screenshot shows your username and the graphic of your ci.yml workflow (docker, rubocop, rspec, cucumber, deploy).

---

## Step 0 — Make the workflow folder
From your project root, run:
```bash
mkdir -p .github/workflows
```

Create a new file:
```bash
code .github/workflows/ci.yml
```

---

## Step 1 — Smallest possible workflow

**Goal:** Prove that GitHub Actions can run on your repo.

**Add this to `ci.yml`:**
````yaml
name: CI / CD

on:
  push:
    branches: [ "main" ]
````

**Why:** This tells GitHub *when* to run automation — every time you push to `main`.

**Verify:** Commit and push. Open the **Actions** tab in GitHub; you should see a new run (it will do nothing yet).

---

## Step 2 — Add a job that checks out the code

**Add this under your workflow:**
````yaml
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Say hello
        run: echo "GitHub Actions is working!"
````

**Why:** All workflows need to *check out* your repository before they can build or test code.

**Verify:** Push again. In **Actions**, look for a green check next to "Say hello".

---

## Step 3 — Build your Docker image (Part 2 in CI)

**Replace** the hello job with this one:
````yaml
jobs:
  build:
    name: Build Docker image
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          tags: wordguesser-ci:latest
          load: true
````

**Why:** This is the CI version of `docker compose build` — it builds the same container automatically.

**Verify:** The log should show the same Bundler installation steps as your local Docker build.

---

## Step 4 — Run RSpec in CI (inside the container)

**Append a new job:**
````yaml
  rspec:
    name: RSpec Tests
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run RSpec inside Docker
        run: |
          docker run --rm             -e RACK_ENV=test -e RAILS_ENV=test             -v ${{ github.workspace }}:/app             wordguesser-ci:latest             bash -lc "bundle exec rspec"
````

**Why:** This reproduces your Part 2 step (`docker compose run --rm app bash -lc "bundle exec rspec"`).

**Verify:** The job runs RSpec tests inside the container; look for familiar test output in the log.

---

## Step 5 — Add Cucumber tests

**Append another job:**
````yaml
  cucumber:
    name: Cucumber Tests
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Cucumber inside Docker
        run: |
          docker run --rm             -e RACK_ENV=test -e RAILS_ENV=test             -v ${{ github.workspace }}:/app             wordguesser-ci:latest             bash -lc "bundle exec cucumber"
````

**Why:** Separate jobs for RSpec and Cucumber let you see which test suite failed faster and more clearly.

**Verify:** The Actions run should show three jobs now: **build**, **rspec**, and **cucumber**.

---

## Step 6 — Add lightweight RuboCop linting (outside Docker)

### 6.1 Update your Gemfile
Make sure your Gemfile includes:
```ruby
group :development, :test do
  gem "rubocop", require: false
  gem "rubocop-rspec", require: false
end
```
Then update your bundle and push the lockfile:
```bash
bundle install
git add Gemfile Gemfile.lock
git commit -m "Add RuboCop gems"
git push
```

### 6.2 Add a RuboCop config file
Create a `.rubocop.yml` file in your project root with these contents:

```yaml
AllCops:
  NewCops: enable
  Include:
    - "lib/wordguesser_game.rb"
  Exclude:
    - "db/**/*"
    - "vendor/**/*"
    - "node_modules/**/*"

Layout/LineLength:
  Max: 120

# Disable some style rules to reduce noise
Style/StringLiterals:
  Enabled: false
Style/Documentation:
  Enabled: false
Style/FrozenStringLiteralComment:
  Enabled: false

Metrics/MethodLength:
  Max: 5
```

> 💡 This configuration only checks `lib/wordguesser_game.rb` and skips quote-style and docstring warnings.

### 6.3 Add the lint job to `ci.yml`
````yaml
  lint:
    name: RuboCop Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true

      - name: Run RuboCop on lib/wordguesser_game.rb
        run: |
          bundle exec rubocop lib/wordguesser_game.rb --require rubocop-rspec -f json | tee rubocop.json

      - name: Install jq
        run: sudo apt-get update -y && sudo apt-get install -y jq

      - name: Check offense threshold
        env:
          OFFENSE_THRESHOLD: "25"
        run: |
          COUNT=$(jq '.summary.offense_count' rubocop.json)
          echo "Found $COUNT offenses. Threshold: $OFFENSE_THRESHOLD"
          if [ "$COUNT" -gt "$OFFENSE_THRESHOLD" ]; then
            echo "::error::RuboCop offenses ($COUNT) exceed threshold ($OFFENSE_THRESHOLD)."
            exit 1
          fi
````

**Why:** This runs RuboCop only on your main game file and suppresses low-value warnings so you can focus on substantive issues.

**Verify:** The job should now pass quickly and only report meaningful problems.

---

## Step 7a — Setup for Deployment on Render (Docker Runtime)

Before the `deploy` job in your workflow can succeed, you need to connect your GitHub repo to a **Render Web Service** that uses your Dockerfile.

**Please note that Render requires a credit card even to use the free tier. If this is not possible for you, please research alternative options for the deploy step and give one a try. If you're not able to get it to work, just describe what you learned in a paragraph or two.**

### 1 Create your Web Service

1. Go to **[https://render.com](https://render.com)** and sign in using your GitHub account.  
2. Click **New → Web Service**.  
3. Under **Environment**, choose **Docker**.  
   > Because you selected Docker, the **Start Command** field will not appear — Render automatically uses the `CMD` from your `Dockerfile`.  
4. Select your **Wordguesser** repository.  
5. Leave **Root Directory** blank (your `Dockerfile` is in the repo root).  
6. Under **Advanced → Environment Variables**, add:
   ```
   PORT=9292
   RACK_ENV=production
   ```
7. Leave the other defaults as they are, then click **Create Web Service**.

> The first deployment may take several minutes while Render builds the Docker image.

---

### 2 Verify the `CMD` in your Dockerfile

Render will use the `CMD` instruction inside your `Dockerfile` to start the app automatically.  
Make sure your file ends with something like this:

```dockerfile
CMD ["bash","-lc","bundle exec rackup -o 0.0.0.0 -p ${PORT:-9292}"]
```

This ensures the container launches the Rack app correctly and listens on the port Render assigns.

---

### 3 Generate a Deploy Hook

1. In your Render dashboard, open your service’s **Settings** tab.  
2. Scroll to **Deploy Hooks** and click **Generate Deploy Hook**.  
3. Copy the long URL that looks like:
   ```
   https://api.render.com/deploy/srv-abc123xyz?key=abcdef123456
   ```

---

### 4 Add the Deploy Hook as a GitHub Secret

1. In your GitHub repository, go to **Settings → Secrets and variables → Actions**.  
2. Click **New repository secret**.  
3. Name it:
   ```
   RENDER_DEPLOY_HOOK_URL
   ```  
4. Paste the full URL you copied from Render.  
5. Save the secret.

---

### 5 Add Your Deploy Job

Your `deploy` job in `.github/workflows/ci.yml` should look like this:

````yaml
  deploy:
    name: Deploy to Render
    needs: [rspec, cucumber, lint]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - name: Trigger Render Deploy Hook
        env:
          DEPLOY_HOOK: ${{ secrets.RENDER_DEPLOY_HOOK_URL }}
        run: |
          if [ -z "$DEPLOY_HOOK" ]; then
            echo "::error::RENDER_DEPLOY_HOOK_URL secret is not set."
            exit 1
          fi
          curl -fsS -X POST "$DEPLOY_HOOK"
````

> This job runs **only** when all tests and lint checks pass on a push to `main`.

---

### 6 Test the Full Pipeline

1. Make a small commit (e.g., edit `README.md`).  
2. Push to **main**.  
3. Open the **Actions** tab and watch your jobs:
   ```
   build → rspec → cucumber → lint → deploy
   ```  
4. When the deploy step completes successfully, open your Render service’s public URL.  
   You should see your app live!

---

## Troubleshooting Map

| Problem | Likely Cause | Fix |
|----------|---------------|-----|
| Deployment fails | Wrong or missing Dockerfile `CMD` | Add correct CMD line to Dockerfile |
| `rubocop` not found | Gems missing from Gemfile | Add and run `bundle install` |
| Lint fails with hundreds of offenses | Configuration too broad | Check `.rubocop.yml` and limit scope |
| Deploy job skipped | Wrong branch or missing secret | Push to `main` and confirm secret name |

---

## Reflection Prompts

- How does automating deployment through Render differ from running your app locally in Docker?  
- Why does Render rely on the Dockerfile’s `CMD` instead of a separate “Start Command” field?  
- What benefits do you gain by deploying automatically after tests pass, versus doing it manually?  
- What could go wrong if your `CMD` doesn’t include the correct port or environment variables?  

---

**🎉 Congratulations!**  
You now have a complete **CI/CD pipeline** that builds, tests, lints, and deploys your app automatically whenever you push changes to the `main` branch.
