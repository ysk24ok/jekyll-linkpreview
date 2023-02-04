# Jekyll::Linkpreview

[![Build Status](https://travis-ci.com/ysk24ok/jekyll-linkpreview.svg?branch=master)](https://travis-ci.com/ysk24ok/jekyll-linkpreview)

Jekyll plugin to generate link preview by `{% linkpreview %}` tag. The plugin fetches [Open Graph protocol](http://ogp.me/) metadata of the designated page to generate preview. The og properties are saved as JSON for caching and it is used when rebuilding the site.

You can pass url directly to the tag,

```
{% linkpreview "https://github.com/ysk24ok/jekyll-linkpreview" %}
```

or, can pass a url variable.

```
{% assign jekyll_linkpreview_page = "https://github.com/ysk24ok/jekyll-linkpreview" %}
{% linkpreview jekyll_linkpreview_page %}
```

By applying [linkpreview.css](assets/css/linkpreview.css), the link preview will be like this.

<img width="613" alt="スクリーンショット 2020-10-26 19 10 26" src="https://user-images.githubusercontent.com/3449164/97160548-db472f80-17bf-11eb-9cc2-383a076fb14d.png">

When the page does not have Open Graph protocol metadata, the preview will be like this.

<img width="613" alt="スクリーンショット 2020-10-26 19 10 35" src="https://user-images.githubusercontent.com/3449164/97160564-e00be380-17bf-11eb-8adb-55c2a07520f1.png">

You can override the default templates, see [Custom templates](#user-content-custom-templates).

## Installation

See https://jekyllrb.com/docs/plugins/installation/ .

## Usage

1. Create `_cache` directory.
   * This directory _must_ exist under your project root even if you've modified the [site source](https://jekyllrb.com/docs/configuration/options/).

1. Embed [linkpreview.css](assets/css/linkpreview.css) into your Website.

1. Use `{% linkpreview %}` tag.

1. Run `jekyll build` or `jekyll serve`.


## Custom templates

You can override the default templates used for generating previews, both in case Open Graph protocol metadata exists or does not exist for a given page.

### Template for pages where Open Graph protocol metadata exists

 1. Place `linkpreview.html` file inside `_includes/` folder of your Jekyll site (`_includes/linkpreview.html`)
     * The folder is the same one you would store files for use with `{% include fragment.html %}` tag. 
       Therefore, it *must* be under the [site's source](https://jekyllrb.com/docs/configuration/options/).

 2. Use built-in variables to extract data which you would like to render. Available variables are:
  * **link_url** i.e. `{{ link_url }}`
  * **link_title** i.e. `{{ link_title }}`
  * **link_type** i.e. `{{ link_type }}`
  * **link_image** i.e. `{{ link_image }}`
  * **link_description** i.e. `{{ link_description }}`
  * **link_domain** i.e. `{{ link_domain }}`

### Template for pages where Open Graph protocol metadata does not exist

1. Place `linkpreview_nog.html` file inside `_includes/` folder of your Jekyll site (`_includes/linkpreview_nog.html`)
   * The folder is the same one you would store files for use with `{% include fragment.html %}` tag.
     Therefore, it *must* be under the [site's source](https://jekyllrb.com/docs/configuration/options/).

 2. Use built-in variables to extract data which you would like to render. Available variables are:
  * **link_url** i.e. `{{ link_url }}`
  * **link_title** i.e. `{{ link_title }}`
  * **link_description** i.e. `{{ link_description }}`
  * **link_domain** i.e. `{{ link_domain }}`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Test with Jekyll site

First, build a Docker image and run a container.

```console
$ docker build --no-cache -t jekyll_linkpreview_dev .
$ docker run --rm -it -w /jekyll-linkpreview -p 4000:4000 jekyll_linkpreview_dev /bin/bash
```

Create a new Jekyll site and move into the new directory.

```console
# bundle exec jekyll new testsite && cd testsite
```

Add this line to `:jekyll_plugins` group of Gemfile.

```console
gem "jekyll-linkpreview", git: "https://github.com/YOUR_ACCOUNT/jekyll-linkpreview", branch: "YOUR_BRANCH"
```

Install the dependecies to your new site.

```console
# bundle install
```

Add a tag such as `{% linkpreview "https://github.com/ysk24ok/jekyll-linkpreview" %}` to `index.markdown` , then start a Jekyll server.

```console
# bundle exec jekyll serve --host 0.0.0.0
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ysk24ok/jekyll-linkpreview.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
