source "https://rubygems.org"

# Specify your gem's dependencies in jekyll-linkpreview.gemspec
gemspec

# The issue that appraisal 2.4.1 can't work with bundler >= 2.4 was solved
# (see https://github.com/thoughtbot/appraisal/issues/199 for details),
# but a new version has not been released yet as of Apr 2023.
# As it's not possible to install a gem from a git repository in the gemspec file,
# appraisal is being installed in Gemfile.
group :development do
  gem 'appraisal', git: 'https://github.com/thoughtbot/appraisal'
end
