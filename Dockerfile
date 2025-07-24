FROM ruby:3.1.2-alpine

RUN apk update && apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    yarn \
    tzdata \
    git

WORKDIR /app

COPY Gemfile* ./

RUN gem install bundler:2.6.9 \
 && bundle install --jobs 4

COPY . .

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]

