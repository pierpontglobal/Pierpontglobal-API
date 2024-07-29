FROM ruby:2.5.1

RUN rm /etc/apt/sources.list

RUN echo "deb http://archive.debian.org/debian/ stretch main contrib non-free" >> /etc/apt/sources.list.d/stretch.list
RUN echo "deb http://archive.debian.org/debian/ stretch-proposed-updates main contrib non-free" >> /etc/apt/sources.list.d/stretch.list
RUN echo "deb http://archive.debian.org/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list.d/stretch.list

RUN mkdir /sidekiq_worker
WORKDIR /sidekiq_worker

COPY . /sidekiq_worker

RUN gem install bundler -v 1.17.3
RUN bundle check || bundle install

CMD bundle exec sidekiq -q $QUEUENAME -c 10