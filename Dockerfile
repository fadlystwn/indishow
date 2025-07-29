FROM ruby:3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    imagemagick \
    libvips-dev \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*
# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle config set --local deployment 'true' \
    && bundle config set --local without 'development test' \
    && bundle install

# Copy package.json and package-lock.json (if exists)
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Create tmp and log directories
RUN mkdir -p tmp/pids log

# Set file permissions
RUN chmod +x bin/rails

# Expose port 3000
EXPOSE 3000

# Default command (can be overridden in docker-compose.yml)
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]