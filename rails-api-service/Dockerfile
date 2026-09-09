FROM ruby:3.2
RUN apt-get update -qq && apt-get install -y build-essential libmariadb-dev-compat libmariadb-dev
WORKDIR /rails-api-service
COPY Gemfile ./
RUN bundle install
RUN bundle exec rails app:update:bin
COPY . .
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
