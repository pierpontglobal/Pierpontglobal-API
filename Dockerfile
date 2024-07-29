FROM ruby:2.5.1


RUN rm /etc/apt/sources.list

RUN echo "deb http://archive.debian.org/debian/ stretch main contrib non-free" >> /etc/apt/sources.list.d/stretch.list
RUN echo "deb http://archive.debian.org/debian/ stretch-proposed-updates main contrib non-free" >> /etc/apt/sources.list.d/stretch.list
RUN echo "deb http://archive.debian.org/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list.d/stretch.list

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev

RUN mkdir /pierpontglobal-api
WORKDIR /pierpontglobal-api

COPY Gemfile /pierpontglobal-api/Gemfile

COPY . /pierpontglobal-api

RUN gem install bundler -v 1.17.3
RUN bundle check || bundle install

EXPOSE 3000

CMD rm ./tmp/pids/*; bundle exec rails db:create; bundle exec rails db:migrate; bundle exec rails db:seed; bundle exec sidekiq -q default & bundle exec rails server -b 0.0.0.0
