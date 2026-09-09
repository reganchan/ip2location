FROM ruby:3.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-default libmysqlclient-dev
WORKDIR /rails-api-service
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]