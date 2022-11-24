require 'fileutils'

require 'jekyll'
require 'metainspector'
require 'nokogiri'
require 'rspec/mocks/standalone'
require 'rspec-parameterized'
# require_relative '../lib/jekyll-linkpreview'
require 'jekyll-linkpreview'

RSpec.describe 'Liquid::Template' do
  it "has 'linkpreview' tag" do
    expect(Liquid::Template.tags['linkpreview']).to be Jekyll::Linkpreview::LinkpreviewTag
  end
end

RSpec.describe 'Jekyll::Linkpreview' do
  it "has a version number" do
    expect(Jekyll::Linkpreview::VERSION).not_to be nil
  end
end

class TestLinkpreviewTag < Jekyll::Linkpreview::LinkpreviewTag
  attr_reader :markup
  attr_writer :source_dir

  def cache_dir
    @@cache_dir
  end

  def template_dir
    @source_dir.nil? || @source_dir.empty? ?
      @@template_dir : File.join(@source_dir, @@template_dir)
  end
end

RSpec.describe 'Jekyll::Linkpreview::OpenGraphProperties' do
  before do
    @title = 'awesome.org - an awesome organization in the world'
    @url = 'https://awesome.org/about'
    @image = 'https://awesome.org/images/favicon.ico'
    @description = 'An awesome organization in the world.'
    @domain = 'awesome.org'
    @properties = Jekyll::Linkpreview::OpenGraphProperties.new @title, @url, @image, @description, @domain
  end

  describe '#to_hash' do
    it 'can return hash' do
      got = @properties.to_hash
      expect(got['title']).to eq @title
      expect(got['url']).to eq @url
      expect(got['image']).to eq @image
      expect(got['description']).to eq @description
      expect(got['domain']).to eq @domain
    end
  end

  describe '#to_hash_for_custom_template' do
    it 'can return hash for custom template' do
      got = @properties.to_hash_for_custom_template
      expect(got['link_title']).to eq @title
      expect(got['link_url']).to eq @url
      expect(got['link_image']).to eq @image
      expect(got['link_description']).to eq @description
      expect(got['link_domain']).to eq @domain
    end
  end
end

RSpec.describe 'Jekyll::Linkpreview::NonOpenGraphProperties' do
  before do
    @title = 'awesome.org - an awesome organization in the world'
    @url = 'https://awesome.org/about'
    @description = 'An awesome organization in the world.'
    @domain = 'awesome.org'
    @properties = Jekyll::Linkpreview::NonOpenGraphProperties.new @title, @url, @description, @domain
  end

  describe '#to_hash' do
    it 'can return hash' do
      got = @properties.to_hash
      expect(got['title']).to eq @title
      expect(got['url']).to eq @url
      expect(got['description']).to eq @description
      expect(got['domain']).to eq @domain
    end
  end

  describe '#to_hash_for_custom_template' do
    it 'can return hash for custom template' do
      got = @properties.to_hash_for_custom_template
      expect(got['link_title']).to eq @title
      expect(got['link_url']).to eq @url
      expect(got['link_description']).to eq @description
      expect(got['link_domain']).to eq @domain
    end
  end
end

RSpec.describe 'Jekyll::Linkpreview::OpenGraphPropertiesFactory' do
  before do
    @factory = Jekyll::Linkpreview::OpenGraphPropertiesFactory.new
  end

  describe '#from_page' do
    describe 'title' do
      context "when 'og:title' tag has a content" do
        before do
          @title = 'awesome.org - an awesome organization in the world'
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:title" content="#{@title}" />
  </head>
</html>
EOS
          )
        end

        it 'can extract title' do
          got = @factory.from_page(@page).to_hash
          expect(got['title']).to eq @title
        end
      end

      context "when 'og:title' tag has an empty content" do
        before do
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:title" content="" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract title' do
          got = @factory.from_page(@page).to_hash
          expect(got['title']).to eq ''
        end
      end

      context "when 'og:title' tag does not exist" do
        before do
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:url" content="#{url}" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract title' do
          got = @factory.from_page(@page).to_hash
          expect(got['title']).to eq nil
        end
      end
    end

    describe 'url and domain' do
      context "when 'og:url' tag is https" do
        before do
          @domain = 'awesome.org'
          @url = "https://#{@domain}/about"
          @page = MetaInspector.new(
            @url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:url" content="#{@url}" />
  </head>
</html>
EOS
          )
        end

        it 'can extract url and domain' do
          got = @factory.from_page(@page).to_hash
          expect(got['url']).to eq @url
          expect(got['domain']).to eq @domain
        end
      end

      context "when 'og:url' tag is http" do
        before do
          @domain = 'awesome.org'
          @url = "https://#{@domain}/about"
          @page = MetaInspector.new(
            @url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:url" content="#{@url}" />
  </head>
</html>
EOS
          )
        end

        it 'can extract url and domain' do
          got = @factory.from_page(@page).to_hash
          expect(got['url']).to eq @url
          expect(got['domain']).to eq @domain
        end
      end

      context "when 'og:url' tag has ill-formed URL" do
        before do
          @domain = 'awesome.org'
          url = "https://#{@domain}/about"
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:url" content="ill-formed" />
  </head>
</html>
EOS
          )
        end

        it 'can extract url and domain' do
          got = @factory.from_page(@page).to_hash
          expect(got['url']).to eq 'ill-formed'
          expect(got['domain']).to eq @domain
        end
      end

      context "when 'og:url' tag has an empty content" do
        before do
          @domain = 'awesome.org'
          url = "https://#{@domain}/about"
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:url" content="" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract url but can extract domain' do
          got = @factory.from_page(@page).to_hash
          expect(got['url']).to eq ''
          expect(got['domain']).to eq @domain
        end
      end

      context "when 'og:url' tag does not exist" do
        before do
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:title" content="" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract url but can extract domain' do
          got = @factory.from_page(@page).to_hash
          expect(got['url']).to eq nil
          expect(got['domain']).to eq 'awesome.org'
        end
      end
    end

    describe 'image' do
      context "when the content of 'og:image' tag is an absolute url" do
        before do
          root_url = 'https://awesome.org/'
          url = URI.join(root_url, 'about').to_s
          @image_url = URI.join(root_url, 'images/favicon.ico').to_s
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:image" content="#{@image_url}" />
  </head>
</html>
EOS
          )
        end

        it 'can extract image url' do
          got = @factory.from_page(@page).to_hash
          expect(got['image']).to eq @image_url
        end
      end

      context "when the content of 'og:image' tag is a root-relative url" do
        before do
          @root_url = 'https://awesome.org/'
          url = URI.join(@root_url, 'about').to_s
          @image_url = '/images/favicon.ico'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:image" content="#{@image_url}" />
  </head>
</html>
EOS
          )
        end

        it 'can convert a root-relative image url to an absolute one' do
          got = @factory.from_page(@page).to_hash
          expect(got['image']).to eq URI.join(@root_url, @image_url).to_s
        end
      end

      context "when 'og:image' tag has an empty content" do
        before do
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:image" content="" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract image url' do
          got = @factory.from_page(@page).to_hash
          expect(got['image']).to eq ''
        end
      end

      context "when 'og:image' tag does not exist" do
        before do
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:title" content="" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract image url' do
          got = @factory.from_page(@page).to_hash
          expect(got['image']).to eq nil
        end
      end
    end

    describe 'description' do
      context "when 'og:description' tag has a content" do
        before do
          url = 'https://awesome.org/about'
          @description = 'An awesome organization in the world.'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:description" content="#{@description}" />
  </head>
</html>
EOS
          )
        end

        it 'can extract description' do
          got = @factory.from_page(@page).to_hash
          expect(got['description']).to eq @description
        end
      end

      context "when 'og:description' tag has an empty content" do
        before do
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:description" content="" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract description' do
          got = @factory.from_page(@page).to_hash
          expect(got['description']).to eq ''
        end
      end

      context "when 'og:description' tag does not exist" do
        before do
          url = 'https://awesome.org/about'
          @page = MetaInspector.new(
            url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:title" content="" />
  </head>
</html>
EOS
          )
        end

        it 'cannot extract description' do
          got = @factory.from_page(@page).to_hash
          expect(got['description']).to eq nil
        end
      end
    end
  end

  describe '#from_hash' do
    before do
      @hash = {
        'title' => 'awesome.org - an awesome organization in the world',
        'url' => 'https://awesome.org/about',
        'domain' => 'awesome.org',
        'image' => 'https://awesome.org/images/favicon.ico',
        'description' => 'An awesome organization in the world.',
      }
    end

    it 'can return an instance of OpenGraphProperties' do
      got = @factory.from_hash(@hash)
      expect(got.instance_of? Jekyll::Linkpreview::OpenGraphProperties).to eq true
      expect(got.to_hash).to eq @hash
    end
  end
end

RSpec.describe 'Jekyll::Linkpreview::NonOpenGraphPropertiesFactory' do
  before do
    @factory = Jekyll::Linkpreview::NonOpenGraphPropertiesFactory.new
  end

  describe '#from_page' do
    before do
      @title = 'awesome.org - an awesome organization in the world'
      @domain = 'awesome.org'
      @url = "https://#{@domain}/about"
      @page = MetaInspector.new(
        @url,
        :document => <<-EOS
<html>
  <head>
    <title>#{@title}</title>
  </head>
  <body></body>
</html>
EOS
      )
    end

    it 'can return an instance of NonOpenGraphProperties' do
      got = @factory.from_page(@page).to_hash
      expect(got['title']).to eq @title
      expect(got['url']).to eq @url
      expect(got['description']).to eq '...'
      expect(got['domain']).to eq @domain
    end
  end

  describe '#from_hash' do
    before do
      @hash = {
        'title' => 'awesome.org - an awesome organization in the world',
        'url' => 'https://awesome.org/about',
        'domain' => 'awesome.org',
        'description' => 'An awesome organization in the world.',
      }
    end

    it 'can return an instance of NonOpenGraphProperties' do
      got = @factory.from_hash(@hash)
      expect(got.instance_of? Jekyll::Linkpreview::NonOpenGraphProperties).to eq true
      expect(got.to_hash).to eq @hash
    end
  end
end

RSpec.describe 'Jekyll::Linkpreview::LinkpreviewTag' do
  describe '#initialize' do
    context "when 'markup' is followed by empty spaces" do
      it 'deletes empty spaces' do
        markup = 'https://github.com  '
        tokenizer = Liquid::Tokenizer.new('')
        parse_context = Liquid::ParseContext.new
        tag = TestLinkpreviewTag.parse(nil, markup, tokenizer, parse_context)
        expect(tag.markup).to eq 'https://github.com'
      end
    end
  end

  where(:site_source) do
    [
      [Dir.pwd], # Default value for Jekyll
      ["."], # Explicitly specified
      ["_content"], # Modified
    ]
  end
  with_them do
    source = params[:site_source]
    describe '#render' do
      before do
        @title = 'awesome.org - an awesome organization in the world'
        @domain = 'awesome.org'
        @url = "https://#{@domain}/about"
        @image = "https://#{@domain}/images/favicon.ico"
        @description = 'An awesome organization in the world.'
        tokenizer = Liquid::Tokenizer.new('')
        parse_context = Liquid::ParseContext.new
        @tag = TestLinkpreviewTag.parse(nil, @url, tokenizer, parse_context)
        Dir.mkdir File.join(source, @tag.template_dir)
      end

      after do
        FileUtils.rm_r File.join(source, @tag.template_dir)
      end

      def check_default_template_with_image_is_rendered(html)
        doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
        expect(doc.xpath('//h2[@class="jekyll-linkpreview-title"]/a').inner_text).to eq @title
        expect(doc.xpath('//h2[@class="jekyll-linkpreview-title"]/a').attribute('href').value).to eq @url
        expect(doc.xpath('//div[@class="jekyll-linkpreview-footer"]/a').inner_text).to eq @domain
        expect(doc.xpath('//div[@class="jekyll-linkpreview-footer"]/a').attribute('href').value).to eq "//#{@domain}"
        expect(doc.xpath('//div[@class="jekyll-linkpreview-image"]/a/img').attribute('src').value).to eq @image
        expect(doc.xpath('//div[@class="jekyll-linkpreview-description"]').inner_text).to eq @description
      end

      def check_default_template_without_image_is_rendered(html)
        doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
        expect(doc.xpath('//h2[@class="jekyll-linkpreview-title"]/a').inner_text).to eq @title
        expect(doc.xpath('//h2[@class="jekyll-linkpreview-title"]/a').attribute('href').value).to eq @url
        expect(doc.xpath('//div[@class="jekyll-linkpreview-footer"]/a').inner_text).to eq @domain
        expect(doc.xpath('//div[@class="jekyll-linkpreview-footer"]/a').attribute('href').value).to eq "//#{@domain}"
        expect(doc.xpath('//div[@class="jekyll-linkpreview-image"]')).to be_empty
        expect(doc.xpath('//div[@class="jekyll-linkpreview-description"]').inner_text).to eq @description
      end

      def get_context(source_dir)
        config = { 'source' => source_dir, 'skip_config_files' => 'true' }
        Liquid::Context.new({}, {}, {
          :site => Jekyll::Site.new(Jekyll::configuration(config))
        })
      end

      def create_ogp_template(source)
        @filepath = File.join source, @tag.template_dir, 'linkpreview.html'
        File.open(@filepath, 'w') { |f| f.write <<-EOS
<div>
  <p class="title">{{ link_title }}</p>
  <p class="url">{{ link_url }}</p>
  <p class="domain">{{ link_domain }}</p>
  <p class="image">{{ link_image }}</p>
  <p class="description">{{ link_description }}</p>
</dic>
EOS
        }
      end

      def create_nogp_template(source)
        @filepath = File.join source, @tag.template_dir, 'linkpreview_nog.html'
        File.open(@filepath, 'w') { |f| f.write <<-EOS
<div>
  <p class="title">{{ link_title }}</p>
  <p class="url">{{ link_url }}</p>
  <p class="domain">{{ link_domain }}</p>
  <p class="description">{{ link_description }}</p>
</dic>
EOS
        }
      end

      describe 'custom template for OpenGraphProperties' do
        before do
          allow(@tag).to receive(:get_properties).and_return(
            Jekyll::Linkpreview::OpenGraphProperties.new @title, @url, @image, @description, @domain
          )
        end

        context 'when a custom template file for OpenGraphProperties exists' do
          before do
            create_ogp_template source
          end
          it 'can render custom template' do
            html = @tag.render get_context(source)
            doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
            expect(doc.xpath('//p[@class="title"]').inner_text).to eq @title
            expect(doc.xpath('//p[@class="url"]').inner_text).to eq @url
            expect(doc.xpath('//p[@class="domain"]').inner_text).to eq @domain
            expect(doc.xpath('//p[@class="image"]').inner_text).to eq @image
            expect(doc.xpath('//p[@class="description"]').inner_text).to eq @description
          end
        end

        context 'when a custom template file for NonOpenGraphProperties exists' do
          before do
            create_nogp_template source
          end
          it 'cannot render custom template' do
            html = @tag.render get_context(source)
            check_default_template_with_image_is_rendered html
          end
        end

        context 'when no custom template file exists' do
          it 'cannot render custom template' do
            html = @tag.render get_context(source)
            check_default_template_with_image_is_rendered html
          end
        end
      end

      describe 'custom template for NonOpenGraphProperties' do
        before do
          allow(@tag).to receive(:get_properties).and_return(
            Jekyll::Linkpreview::NonOpenGraphProperties.new @title, @url, @description, @domain
          )
        end

        context 'when a custom template file for NonOpenGraphProperties exists' do
          before do
            create_nogp_template source
          end
          it 'can render custom template' do
            html = @tag.render get_context(source)
            doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
            expect(doc.xpath('//p[@class="title"]').inner_text).to eq @title
            expect(doc.xpath('//p[@class="url"]').inner_text).to eq @url
            expect(doc.xpath('//p[@class="domain"]').inner_text).to eq @domain
            expect(doc.xpath('//p[@class="description"]').inner_text).to eq @description
          end
        end

        context 'when a custom template file for OpenGraphProperties exists' do
          before do
            create_ogp_template source
          end
          it 'cannot render custom template' do
            html = @tag.render get_context(source)
            check_default_template_without_image_is_rendered html
          end
        end

        context 'when no custom template file exists' do
          it 'cannot render custom template' do
            html = @tag.render get_context(source)
            check_default_template_without_image_is_rendered html
          end
        end
      end
    end
  end

  describe '#get_properties' do
    before do
      @title = 'awesome.org - an awesome organization in the world'
      @domain = 'awesome.org'
      @url = "https://#{@domain}/about"
      @image = "https://#{@domain}/images/favicon.ico"
      @description = 'An awesome organization in the world.'
      tokenizer = Liquid::Tokenizer.new('')
      parse_context = Liquid::ParseContext.new
      @tag = TestLinkpreviewTag.parse(nil, @url, tokenizer, parse_context)
    end

    context 'when a cache file does not exist' do
      before do
        allow(@tag).to receive(:fetch).and_return(
          MetaInspector.new(
            @url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:title" content="#{@title}" />
    <meta property="og:url" content="#{@url}" />
    <meta property="og:image" content="#{@image}" />
    <meta property="og:description" content="#{@description}" />
  </head>
</html>
EOS
          )
        )
        Dir.mkdir @tag.cache_dir
      end

      after do
        FileUtils.rm_r(@tag.cache_dir)
      end

      it 'can save properties to a cache file and load it on the next call' do
        expect(@tag).to receive(:fetch).exactly(1).times

        got = @tag.get_properties(@url).to_hash
        expect(got['title']).to eq @title
        expect(got['url']).to eq @url
        expect(got['domain']).to eq @domain
        expect(got['image']).to eq @image
        expect(got['description']).to eq @description

        got = @tag.get_properties(@url).to_hash
        expect(got['title']).to eq @title
        expect(got['url']).to eq @url
        expect(got['domain']).to eq @domain
        expect(got['image']).to eq @image
        expect(got['description']).to eq @description
      end
    end
  end
end

Liquid::Template.register_tag("test_linkpreview", TestLinkpreviewTag)

RSpec.describe "Integration test" do
  before do
    # Mocked configuration values
    @context = Liquid::Context.new({}, {}, {
      :site => Jekyll::Site.new(Jekyll::configuration({'source' => '', 'skip_config_files' => true}))
    })
  end

  context "when URL is directly passed to the tag" do
    it "can generate link preview" do
      t = Liquid::Template.new
      t.parse('{% test_linkpreview "https://github.com" %}')
      expect(t.render(@context)).not_to include('Liquid error: internal')
    end
  end

  context "when URL has no OpenGraph tags" do
    it "can generate link preview" do
      t = Liquid::Template.new
      t.parse('{% test_linkpreview "https://connect2id.com/products/nimbus-jose-jwt/vulnerabilities" %}')
      expect(t.render(@context)).not_to include('Liquid error: internal')
    end
  end

  context "when URL is passed as a variable" do
    it "can generate link preview" do
      t = Liquid::Template.new
      t.parse("{% assign url = 'https://github.com' %}{% test_linkpreview url %}")
      expect(t.render(@context)).not_to include('Liquid error: internal')
    end
  end

  context "when URL is passed as a variable in a for loop" do
    it "can generate link preview" do
      assigns = {'urls' => ['https://github.com', 'https://google.com']}
      template = '{% for url in urls %}{% test_linkpreview url %}{% endfor %}'
      got = Liquid::Template.parse(template).render!(@context, assigns)
      expect(got).not_to include('Liquid error: internal')
    end
  end
end
