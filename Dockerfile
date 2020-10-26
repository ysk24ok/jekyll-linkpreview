FROM ruby:2.6.5

RUN apt update \
 && apt install -y \
    vim \
 && rm -rf /var/lib/apt/lists/*
RUN gem install \
    bundler \
    jekyll
RUN mkdir /jekyll-linkpreview
ADD Gemfile /jekyll-linkpreview
ADD jekyll-linkpreview.gemspec /jekyll-linkpreview
ADD lib/jekyll-linkpreview/version.rb /jekyll-linkpreview/lib/jekyll-linkpreview/version.rb
RUN cd /jekyll-linkpreview && bundle install
