# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install minimal runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    && rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# ---------- Build stage ----------
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    pkg-config \
    libpq-dev \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy source and precompile assets
COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---------- Final stage ----------
FROM base

# Copy gems and app
COPY --from=build ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=build /rails /rails

# Create a non-root user and prepare dirs
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp && \
    ln -sf /dev/stdout log/production.log

USER rails:rails

# Entrypoint for Rails (usually handles DB checks, etc.)
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose port 8080 (expected by Railway)
EXPOSE 8080

# Use Puma and config/puma.rb for production
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# Healthcheck for Railway
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/up || exit 1
