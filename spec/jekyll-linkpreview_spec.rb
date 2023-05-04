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

  def cache_dir
    @@cache_dir
  end

  def template_dir
    @source_dir.nil? || @source_dir.empty? ?
      @@template_dir : File.join(@source_dir, @@template_dir)
  end
end

RSpec.describe 'Jekyll::Linkpreview::Properties' do
  before do
    @title = 'awesome.org - an awesome organization in the world'
    @type = 'website'
    @url = 'https://awesome.org/about'
    @image = 'https://awesome.org/images/favicon.ico'
    @description = 'An awesome organization in the world.'
    @domain = 'awesome.org'
    @template_file = 'linkpreview.html'
    @properties = Jekyll::Linkpreview::Properties.new({
      'title' => @title,
      'type' => @type,
      'url' => @url,
      'image' => @image,
      'description' => @description,
      'domain' => @domain,
    }, @template_file)
  end

  describe '#to_hash' do
    it 'can return hash' do
      got = @properties.to_hash
      expect(got['title']).to eq @title
      expect(got['type']).to eq @type
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
      expect(got['link_type']).to eq @type
      expect(got['link_url']).to eq @url
      expect(got['link_image']).to eq @image
      expect(got['link_description']).to eq @description
      expect(got['link_domain']).to eq @domain
    end
  end

  describe '#template_file' do
    it 'can return template file' do
      got = @properties.template_file
      expect(got).to eq @template_file
    end
  end
end

RSpec.describe 'Jekyll::Linkpreview::OpenGraphPropertiesFactory' do
  before do
    @factory = Jekyll::Linkpreview::OpenGraphPropertiesFactory.new
  end

  describe '#from_page' do
    let(:domain) { 'awesome.org' }
    let(:secure_domain) { "secure.#{domain}" }
    let(:url) { "https://#{domain}/about" }

    describe 'basic metadata' do
      describe 'og:title' do
        before do
          @title = 'awesome.org - an awesome organization in the world'
          @page = MetaInspector.new(url, :document => _generate_html([["og:title", @title]]))
        end

        it "can extract 'og:title'" do
          got = @factory.from_page(@page).to_hash
          expect(got['title']).to eq @title
        end
      end

      describe 'og:url' do
        where(:og_url) do
          [
            # Intentinally a domain different from 'awesome.org' is used
            # to show the url is extracted from 'og:url'.
            ['https://example.com/about'],  # https
            ['http://example.com/about'],  # http
            ['ill-formed'],  # ill-formed
          ]
        end

        with_them do
          before do
            @page = MetaInspector.new(url, :document => _generate_html([["og:url", og_url]]))
          end

          it "can extract 'og:url'" do
            got = @factory.from_page(@page).to_hash
            expect(got['url']).to eq og_url
          end
        end
      end

      describe 'og:image' do
        where(:image, :expected) do
          [
            ["https://#{domain}/ogp.jpg", "https://#{domain}/ogp.jpg"],  # absolute url
            ['/ogp.jpg', "https://#{domain}/ogp.jpg"],  # root-relative url
          ]
        end

        with_them do
          before do
            @page = MetaInspector.new(url, :document => _generate_html([["og:image", image]]))
          end

          it "can extract 'og:image'" do
            got = @factory.from_page(@page).to_hash
            expect(got['image']).to eq expected
          end
        end
      end
    end

    describe 'optional metadata' do
      describe 'og:image:secure_url' do
        where(:image_secure_url, :expected) do
          [
            ["https://#{secure_domain}/ogp.jpg", "https://#{secure_domain}/ogp.jpg"],  # absolute url
            ['/ogp.jpg', "https://#{domain}/ogp.jpg"],  # root-relative url
          ]
        end

        with_them do
          before do
            @page = MetaInspector.new(url, :document => _generate_html([["og:image:secure_url", image_secure_url]]))
          end

          it "can extract 'og:image:secure_url" do
            got = @factory.from_page(@page).to_hash
            expect(got['image_secure_url']).to eq expected
          end
        end
      end

      describe 'og:image:type' do
        before do
          @image_type = 'image/jpeg'
          @page = MetaInspector.new(url, :document => _generate_html([["og:image:type", @image_type]]))
        end

        it "can extract 'og:image:type'" do
          got = @factory.from_page(@page).to_hash
          expect(got['image_type']).to eq @image_type
        end
      end

      describe 'og:image:width' do
        before do
          @image_width = '400'
          @page = MetaInspector.new(url, :document => _generate_html([["og:image:width", @image_width]]))
        end

        it "can extract 'og:image:width'" do
          got = @factory.from_page(@page).to_hash
          expect(got['image_width']).to eq @image_width
        end
      end

      describe 'og:image:height' do
        before do
          @image_height = '300'
          @page = MetaInspector.new(url, :document => _generate_html([["og:image:height", @image_height]]))
        end

        it "can extract 'og:image:height'" do
          got = @factory.from_page(@page).to_hash
          expect(got['image_height']).to eq @image_height
        end
      end

      describe 'og:image:alt' do
        before do
          @image_alt = 'A shiny red apple with a bite taken out'
          @page = MetaInspector.new(url, :document => _generate_html([["og:image:alt", @image_alt]]))
        end

        it "can extract 'og:image:alt'" do
          got = @factory.from_page(@page).to_hash
          expect(got['image_alt']).to eq @image_alt
        end
      end

      describe 'og:video' do
        where(:video, :expected) do
          [
            ["https://#{domain}/movie.swf", "https://#{domain}/movie.swf"],  # absolute url
            ['/movie.swf', "https://#{domain}/movie.swf"],  # root-relative url
          ]
        end

        with_them do
          before do
            @page = MetaInspector.new(url, :document => _generate_html([["og:video", video]]))
          end

          it "can extract 'og:video'" do
            got = @factory.from_page(@page).to_hash
            expect(got['video']).to eq expected
          end
        end
      end

      describe 'og:video:secure_url' do
        where(:video_secure_url, :expected) do
          [
            ["https://#{secure_domain}/movie.swf", "https://#{secure_domain}/movie.swf"],  # absolute url
            ['/movie.swf', "https://#{domain}/movie.swf"],  # root-relative url
          ]
        end

        with_them do
          before do
            @page = MetaInspector.new(url, :document => _generate_html([["og:video:secure_url", video_secure_url]]))
          end

          it "can extract 'og:video:secure_url'" do
            got = @factory.from_page(@page).to_hash
            expect(got['video_secure_url']).to eq expected
          end
        end
      end

      describe 'og:video:type' do
        before do
          @video_type = 'application/x-shockwave-flash'
          @page = MetaInspector.new(url, :document => _generate_html([["og:video:type", @video_type]]))
        end

        it "can extract 'og:video:type'" do
          got = @factory.from_page(@page).to_hash
          expect(got['video_type']).to eq @video_type
        end
      end

      describe 'og:video:width' do
        before do
          @video_width = '400'
          @page = MetaInspector.new(url, :document => _generate_html([["og:video:width", @video_width]]))
        end

        it "can extract 'og:video:width'" do
          got = @factory.from_page(@page).to_hash
          expect(got['video_width']).to eq @video_width
        end
      end

      describe 'og:video:height' do
        before do
          @video_height = '300'
          @page = MetaInspector.new(url, :document => _generate_html([["og:video:height", @video_height]]))
        end

        it "can extract 'og:video:height'" do
          got = @factory.from_page(@page).to_hash
          expect(got['video_height']).to eq @video_height
        end
      end

      describe 'og:audio' do
        where(:audio, :expected) do
          [
            ["https://#{domain}/sound.mp3", "https://#{domain}/sound.mp3"],  # absolute url
            ['/sound.mp3', "https://#{domain}/sound.mp3"],  # root-relative url
          ]
        end

        with_them do
          before do
            @page = MetaInspector.new(url, :document => _generate_html([["og:audio", audio]]))
          end

          it "can extract 'og:audio'" do
            got = @factory.from_page(@page).to_hash
            expect(got['audio']).to eq expected
          end
        end
      end

      describe 'og:audio:secure_url' do
        where(:audio_secure_url, :expected) do
          [
            ["https://#{secure_domain}/sound.mp3", "https://#{secure_domain}/sound.mp3"],  # absolute url
            ['/sound.mp3', "https://#{domain}/sound.mp3"],  # root-relative url
          ]
        end

        with_them do
          before do
            @page = MetaInspector.new(url, :document => _generate_html([["og:audio:secure_url", audio_secure_url]]))
          end

          it "can extract 'og:audio:secure_url'" do
            got = @factory.from_page(@page).to_hash
            expect(got['audio_secure_url']).to eq expected
          end
        end
      end

      describe 'og:audio:type' do
        before do
          @audio_type = 'audio/mpeg'
          @page = MetaInspector.new(url, :document => _generate_html([["og:audio:type", @audio_type]]))
        end

        it "can extract 'og:audio:type'" do
          got = @factory.from_page(@page).to_hash
          expect(got['audio_type']).to eq @audio_type
        end
      end

      describe 'other optional metadata' do
        context "when other optional metadata tags have a content" do
          before do
            url = 'https://awesome.org/about'
            @description = 'An awesome organization in the world.'
            @determiner = 'the'
            @locale = 'en_GB'
            @locale_alternate = ['fr_FR', 'es_ES']
            @site_name = 'IMDb'
            @page = MetaInspector.new(
              url,
              :document => _generate_html([
                ["og:description", @description],
                ["og:determiner", @determiner],
                ["og:locale", @locale],
                ["og:locale:alternate", @locale_alternate[0]],
                ["og:locale:alternate", @locale_alternate[1]],
                ["og:site_name", @site_name],
              ])
            )
          end

          it 'can extract metadata' do
            got = @factory.from_page(@page).to_hash
            expect(got['description']).to eq @description
            expect(got['determiner']).to eq @determiner
            expect(got['locale']).to eq @locale
            # TODO: All values must be extracted.
            expect(got['locale_alternate']).to eq @locale_alternate[0]
            expect(got['site_name']).to eq @site_name
          end
        end
      end

      describe 'domain' do
        before do
          @page = MetaInspector.new(url, :document => _generate_html([]))
        end

        it 'can extract domain' do
          got = @factory.from_page(@page).to_hash
          expect(got['domain']).to eq domain
        end
      end
    end
  end

  describe '#from_hash' do
    before do
      @hash = {
        'title' => 'awesome.org - an awesome organization in the world',
        'type' => 'website',
        'url' => 'https://awesome.org/about',
        'domain' => 'awesome.org',
        'image' => 'https://awesome.org/images/favicon.ico',
        'description' => 'An awesome organization in the world.',
      }
    end

    it 'can return an instance of Properties' do
      got = @factory.from_hash(@hash)
      expect(got.instance_of? Jekyll::Linkpreview::Properties).to eq true
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
      @page_title_in_body = MetaInspector.new(
        @url,
        :document => <<-EOS
<html>
  <body>
    <title>#{@title}</title>
  </body>
</html>
      EOS
      )
    end

    context 'when parsing HTML whose title tag is in head' do
      it 'can get title and other properties' do
        check_properties(@factory.from_page(@page).to_hash)
      end
    end

    context 'when parsing HTML whose title tag is in body' do
      it 'can get title and other properties' do
        check_properties(@factory.from_page(@page_title_in_body).to_hash)
      end
    end

    def check_properties(got)
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

    it 'can return an instance of Properties' do
      got = @factory.from_hash(@hash)
      expect(got.instance_of? Jekyll::Linkpreview::Properties).to eq true
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
      [Jekyll::Configuration::DEFAULTS["source"]],
      ["."], # Explicitly specified
      ["_content"], # Modified
    ]
  end
  with_them do
    source = params[:site_source]
    describe '#render' do
      before do
        @title = 'awesome.org - an awesome organization in the world'
        @type = 'website'
        @domain = 'awesome.org'
        @url = "https://#{@domain}/about"
        @image = "https://#{@domain}/images/favicon.ico"
        @description = 'An awesome organization in the world.'
        tokenizer = Liquid::Tokenizer.new('')
        parse_context = Liquid::ParseContext.new
        @tag = TestLinkpreviewTag.parse(nil, @url, tokenizer, parse_context)
        FileUtils.mkdir_p File.join(source, @tag.template_dir)
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

      describe 'custom template for ogp pages' do
        before do
          allow(@tag).to receive(:get_properties).and_return(
            Jekyll::Linkpreview::OpenGraphPropertiesFactory.new.from_hash({
              'title' => @title,
              'type' => @type,
              'url' => @url,
              'image' => @image,
              'description' => @description,
              'domain' => @domain,
            })
          )
        end

        context 'when a custom template file for ogp pages exists' do
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

        context 'when a custom template file for non-ogp pages exists' do
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

      describe 'custom template for non-ogp pages' do
        before do
          allow(@tag).to receive(:get_properties).and_return(
            Jekyll::Linkpreview::NonOpenGraphPropertiesFactory.new.from_hash({
              'title' => @title,
              'url' => @url,
              'description' => @description,
              'domain' => @domain,
            })
          )
        end

        context 'when a custom template file for non-ogp pages exists' do
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

        context 'when a custom template file for ogp pages exists' do
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
      @type = 'website'
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
    <meta property="og:type" content="#{@type}" />
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
        expect(got['type']).to eq @type
        expect(got['url']).to eq @url
        expect(got['domain']).to eq @domain
        expect(got['image']).to eq @image
        expect(got['description']).to eq @description

        got = @tag.get_properties(@url).to_hash
        expect(got['title']).to eq @title
        expect(got['type']).to eq @type
        expect(got['url']).to eq @url
        expect(got['domain']).to eq @domain
        expect(got['image']).to eq @image
        expect(got['description']).to eq @description
      end
    end

    context 'when the page has all required OGP tags' do
      before do
        allow(@tag).to receive(:fetch).and_return(
          MetaInspector.new(
            @url,
            :document => <<-EOS
<html>
  <head>
    <meta property="og:title" content="#{@title}" />
    <meta property="og:type" content="#{@type}" />
    <meta property="og:url" content="#{@url}" />
    <meta property="og:image" content="#{@image}" />
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

      it 'can spawn OpenGraphProtocolFactory' do
        expect(@tag).to receive(:fetch).exactly(1).times
        got = @tag.get_properties @url
        expect(got.instance_of? Jekyll::Linkpreview::Properties).to eq true
        expect(got.template_file).to eq Jekyll::Linkpreview::OpenGraphPropertiesFactory::template_file
      end
    end

    context 'when the page is missing required OGP tags' do
      before do
        allow(@tag).to receive(:fetch).and_return(
          MetaInspector.new(
            @url,
            :document => <<-EOS
<html>
  <head>
    <meta property="something" content="unrelated" />
    <meta property="is" content="here" />
    <meta property="og:title" content="is set but other required tags are missing" />
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

      it 'can spawn NonOpenGraphProtocolFactory' do
        expect(@tag).to receive(:fetch).exactly(1).times
        got = @tag.get_properties @url
        expect(got.instance_of? Jekyll::Linkpreview::Properties).to eq true
        expect(got.template_file).to eq Jekyll::Linkpreview::NonOpenGraphPropertiesFactory::template_file
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

def _generate_html(properties)
  meta_tags = []
  properties.each do |property, content|
    meta_tags << "<meta property=\"#{property}\" content=\"#{content}\" />"
  end
  "<html><head>" + meta_tags.join + "</head></html>"
end
