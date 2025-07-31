# Dockerfile

FROM ruby:3.1.2

# SQLite3 と Node.js / Yarn をインストール
RUN apt-get update -qq && \
    apt-get install -y build-essential libsqlite3-dev nodejs yarn

WORKDIR /myapp
COPY Gemfile* ./
RUN bundle install

COPY . .

# Rails サーバー起動コマンド
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]