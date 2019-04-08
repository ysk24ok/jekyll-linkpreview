# Jekyll::Linkpreview

Jekyll plugin to generate link preview by `{% linkpreview %}` tag. The plugin fetches [Open Graph protocols](http://ogp.me/) of the designated page to generate preview. The og properties are saved as JSON for caching and it is used when rebuilding the site.

For example, `{% linkpreview https://github.com %}` tag generates following HTML when you run `jekyll build`,

```html
<div class="jekyll-linkpreview-wrapper">
  <p><a href="https://github.com" target="_blank">https://github.com</a></p>
  <div class="jekyll-linkpreview-wrapper-inner">
    <div class="jekyll-linkpreview-content">
      <div class="jekyll-linkpreview-image">
        <a href="https://github.com" target="_blank">
          <img src="https://github.githubassets.com/images/modules/open_graph/github-logo.png" />
        </a>
      </div>
      <div class="jekyll-linkpreview-body">
        <h2 class="jekyll-linkpreview-title">
          <a href="https://github.com" target="_blank">Build software better, together</a>
        </h2>
        <div class="jekyll-linkpreview-description">GitHub is where people build software. More than 31 million people use GitHub to discover, fork, and contribute to over 100 million projects.</div>
      </div>
    </div>
    <div class="jekyll-linkpreview-footer">
      <a href="https://github.com" target="_blank">github.com</a>
    </div>
  </div>
</div>
```

Applying appropriate CSS, the link preview will be like this.

<img width="613" alt="スクリーンショット 2019-04-03 20 52 50" src="https://user-images.githubusercontent.com/3449164/55479970-35baf100-565a-11e9-8c5d-709213917f74.png">

## Installation

See https://jekyllrb.com/docs/plugins/installation/ .

## Usage

1. Create `_cache` directory where you run `jekyll build` or `jekyll serve`.

1. Embed [linkpreview.css](assets/css/linkpreview.css) into your Website.

1. Use `{% linkpreview %}` tag.

1. Run `jekyll build` or `jekyll serve`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ysk24ok/jekyll-linkpreview.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
