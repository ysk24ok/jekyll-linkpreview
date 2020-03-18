FROM ruby:2.6.5

RUN apt-get -y update
RUN gem install bundler
