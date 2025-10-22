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