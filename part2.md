[Part 1](README.md)    Part 2    [Part 3](part3.md)

Wordguesser
=============================================================

(v1.1, September 2015.  Written by Armando Fox and Nick Herson)
(some edits by mverdicchio 21 September 2015)
(refinements by Armando Fox September 2017)
(other updates from Michael Ball and others)

This codebase originated as an assignment for a software engineering course wherein students would incrementally develop a ruby version of Wordguesser (Hangman) using BDD and TDD, then wrap it in a Sinatra web server.

In this DevOps course, we will use the completed solution to this assignment as a starting point in an exercise to containerize the app and add it to a CI/CD pipeline.

# Part 2 — Containerize & Test the Wordguesser App

## Goals
- Build a Docker image for the app  
- Run the app locally via a container  
- Run RSpec and Cucumber **inside** the container  
- Use a simple Docker Compose setup that’s easy to extend later

---

## A. Files You Will Add

### 1) `Dockerfile`

Copy the following contents into a new file named **Dockerfile** at the project root.

````dockerfile
# Use an official Ruby image with build tools so native gems can compile if needed.
# You can pin to a specific version for reproducibility, e.g., ruby:3.3.9
FROM ruby:3.3

# Create and switch to the app directory inside the image.
WORKDIR /app

# Install system packages your app/gems might need.
RUN apt-get update -y &&     apt-get install -y --no-install-recommends build-essential nodejs git curl &&     rm -rf /var/lib/apt/lists/*

# Set environment defaults for development.
ENV RACK_ENV=development     RAILS_ENV=development     BUNDLE_PATH=/usr/local/bundle

# Copy gem manifests first for layer caching.
COPY Gemfile Gemfile.lock* ./

# Install Ruby gems.
RUN bundle config set path "$BUNDLE_PATH" &&     bundle install --jobs=4 --retry=3

# Copy the rest of the app code.
COPY . .

# Expose the port (default 9292 for Rack/Sinatra apps).
EXPOSE 9292

# Optional healthcheck (adjust path if necessary).
HEALTHCHECK --interval=30s --timeout=5s --retries=3   CMD curl -fsS "http://localhost:${PORT:-9292}/" || exit 1

# Default command for running the app.
CMD ["bash", "-lc", "bundle exec rackup -o 0.0.0.0 -p ${PORT:-9292}"]
````

---

### 2) `docker-compose.yml`

Copy this content into a new file named **docker-compose.yml**.

````yaml
version: "3.9"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile

    image: wordguesser:dev

    ports:
      - "9292:9292"

    volumes:
      - .:/app

    environment:
      - PORT=9292
      - RACK_ENV=development
      - RAILS_ENV=development
````

---

## B. Build the Image

Run this once to build your container image:

```
docker compose build
```

This uses your Dockerfile to produce an image named **wordguesser:dev** and caches the gem installation layer for faster rebuilds.

---

## C. Run the App Locally

Start the containerized app:

```
docker compose up
```

Then open a browser to:

```
http://localhost:9292
```

To stop the container, press **Ctrl+C**.  
To run in detached mode, use `docker compose up -d` and later `docker compose down`.

---

## D. Run Tests Inside the Container

You’ll now use Docker to execute your RSpec and Cucumber tests, ensuring a consistent environment for everyone.

**Run RSpec:**
```
docker compose run --rm app bash -lc "bundle exec rspec"
```

**Run Cucumber:**
```
docker compose run --rm app bash -lc "bundle exec cucumber"
```

To open an interactive shell in the container:
```
docker compose run --rm app bash
```

---

## E. Clean Rebuild (if needed)

When gems or dependencies change, do a clean rebuild:

```
docker compose down
docker compose build --no-cache
docker compose up --force-recreate
```

---

## F. Quick Explanation of What Changed

- **Dockerfile** → defines the container image (what software and tools are installed)  
- **docker-compose.yml** → defines how to run the container (ports, volumes, env vars)  
- Together, they let you run and test the app in a consistent, reproducible environment.

---

## G. Troubleshooting Tips

- **Port already in use:**  
  Change the **host** port in the `ports:` mapping, e.g. `"9393:9292"`.

- **Gem install errors:**  
  You may need extra libraries. Add them to the `apt-get install` line, then rebuild.

- **File or path issues:**  
  Ensure the container’s working directory matches the app’s structure (`/app`).

---

## H. What to Submit

1. A working `Dockerfile` and `docker-compose.yml` at the repo root  
2. Screenshots showing:
   - The app running in the browser  
   - Passing RSpec and Cucumber output  
3. A short writeup (2–3 sentences) on what you learned from containerizing the app

---

## I. Reflection Questions

Answer briefly in your README or in a separate file:

1. **Reproducibility:**  
   How does containerization help ensure that your app runs consistently across different machines and environments?

2. **Separation of Concerns:**  
   Why do Dockerfile and docker-compose.yml serve different purposes? How might Compose help if this app later needs a database or other services?

---

*End of Part 2*
