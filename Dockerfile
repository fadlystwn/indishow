FROM ruby:3.2.2-slim

ENV RAILS_ENV=production

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev libvips curl git sqlite3 pkg-config

# Node.js + Yarn (for Vite + Tailwind)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn vite

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.5.7 && bundle install

COPY . .

# Don't precompile here (Railway doesn't support build-time secrets)
# RUN bundle exec rake assets:precompile

EXPOSE 3000 3036

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
