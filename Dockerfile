# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim

LABEL maintainer="fadlystwn@gmail.com"

# Set environment variables
ENV RAILS_ENV=production \
    BUNDLER_VERSION=2.5.7 \
    DEBIAN_FRONTEND=noninteractive \
    NODE_VERSION=20 \
    YARN_VERSION=1.22.19

WORKDIR /app

# Install OS packages
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libvips \
      curl \
      git \
      sqlite3 \
      pkg-config \
      libjemalloc2 \
      nodejs \
      gnupg && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and Yarn (needed for vite)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install --global yarn@$YARN_VERSION && \
    npm install --global vite

# Install bundler and gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v "$BUNDLER_VERSION" && \
    bundle install --jobs 4 --retry 3

# Add the project files
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile

# Expose ports (e.g., Puma on 3000, Vite on 3036)
EXPOSE 3000 3036

# Entrypoint to run the server (customize if needed)
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
