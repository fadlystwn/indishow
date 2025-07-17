# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

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

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    pkg-config \
    libpq-dev \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base

COPY --from=build ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp && \
    ln -sf /dev/stdout log/production.log

USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 5000
CMD ["./bin/rails", "server"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:5000/up || exit 1