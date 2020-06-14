require 'jekyll'
require 'rspec/mocks/standalone'
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
  attr_reader :markup, :og_properties, :nog_properties

  protected
  def save_cache_file(filepath, properties)
    nil
  end
end

RSpec.describe 'Jekyll::Linkpreview::OpenGraphProperties' do
  describe '#get' do
    before do
      @og_properties = Jekyll::Linkpreview::OpenGraphProperties.new
    end

    describe 'title' do
      context "when 'title' has a content" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'title' => 'hoge.org - an awesome organization in the world',
          })
        end

        it 'can extract title' do
          properties = @og_properties.get(nil)
          expect(properties['title']).to eq 'hoge.org - an awesome organization in the world'
        end
      end

      context "when 'title' has no content" do
        before do
          allow(@og_properties).to receive(:get).and_return({})
        end

        it 'cannot extract title' do
          properties = @og_properties.get(nil)
          expect(properties['title']).to eq nil
        end
      end
    end

    describe 'url and domain' do
      context "when 'url' is https" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'url' => 'https://hoge.org/foo/bar',
            'domain' => 'hoge.org'
          })
        end

        it 'can extract url and domain' do
          properties = @og_properties.get(nil)
          expect(properties['url']).to eq 'https://hoge.org/foo/bar'
          expect(properties['domain']).to eq 'hoge.org'
        end
      end

      context "when 'url' is http" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'url' => 'http://hoge.org/foo/bar',
            'domain' => 'hoge.org'
          })
        end

        it 'can extract url and domain' do
          properties = @og_properties.get(nil)
          expect(properties['url']).to eq 'http://hoge.org/foo/bar'
          expect(properties['domain']).to eq 'hoge.org'
        end
      end

      context "when 'url' tag has ill-formed URL" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'url' => 'ill-formed'
          })
        end

        it 'cannot extract url and domain' do
          properties = @og_properties.get(nil)
          expect(properties['url']).to eq 'ill-formed'
          expect(properties['domain']).to eq nil
        end
      end

      context "when 'url' tag has no content" do
        before do
          allow(@og_properties).to receive(:get).and_return({})
        end

        it 'cannot extract url and domain' do
          properties = @og_properties.get(nil)
          expect(properties['url']).to eq nil
          expect(properties['domain']).to eq nil
        end
      end
    end

    describe 'image' do
      context "when the content of 'image' tag is an absolute url" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'url' => 'https://hoge.org/foo/bar',
            'image' => 'https://hoge.org/images/favicon.ico'
          })
        end

        it 'can extract image url' do
          properties = @og_properties.get(nil)
          expect(properties['image']).to eq 'https://hoge.org/images/favicon.ico'
        end
      end

      context "when the content of 'image' tag is a root-relative url" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'url' => 'https://hoge.org/foo/bar',
            'image' => '//hoge.org/images/favicon.ico'
          })
        end

        it 'can convert a root-relative image url to an absolute one' do
          properties = @og_properties.get(nil)
          expect(properties['image']).to eq '//hoge.org/images/favicon.ico'
        end
      end

      context "when 'image' tag has no content" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'url' => 'https://hoge.org/foo/bar'
          })
        end

        it 'cannot extract image url' do
          properties = @og_properties.get(nil)
          expect(properties['image']).to eq nil
        end
      end
    end

    describe 'description' do
      context "when 'description' has a content" do
        before do
          allow(@og_properties).to receive(:get).and_return({
            'description' => 'An awesome organization in the world for doing hoge',
          })
        end

        it 'can extract description' do
          properties = @og_properties.get(nil)
          expect(properties['description']).to eq 'An awesome organization in the world for doing hoge'
        end
      end

      context "when 'description' has no content" do
        before do
          allow(@og_properties).to receive(:get).and_return({})
        end

        it 'cannot extract description' do
          properties = @og_properties.get(nil)
          expect(properties['description']).to eq nil
        end
      end
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
end

Liquid::Template.register_tag("test_linkpreview", TestLinkpreviewTag)

RSpec.describe "Integration test" do
  context "when URL is directly passed to the tag" do
    it "can generate link preview" do
      t = Liquid::Template.new
      t.parse('{% test_linkpreview "https://github.com" %}')
      expect(t.render).not_to include('Liquid error: internal')
    end
  end

  context "when URL has no OpenGraph tags" do
    it "can generate link preview" do
      t = Liquid::Template.new
      t.parse('{% test_linkpreview "https://connect2id.com/products/nimbus-jose-jwt/vulnerabilities" %}')
      expect(t.render).not_to include('Liquid error: internal')
    end
  end

  context "when URL is passed as a variable" do
    it "can generate link preview" do
      t = Liquid::Template.new
      t.parse("{% assign url = 'https://github.com' %}{% test_linkpreview url %}")
      expect(t.render).not_to include('Liquid error: internal')
    end
  end

  context "when URL is passed as a variable in a for loop" do
    it "can generate link preview" do
      assigns = {'urls' => ['https://github.com', 'https://google.com']}
      template = '{% for url in urls %}{% test_linkpreview url %}{% endfor %}'
      got = Liquid::Template.parse(template).render!(assigns)
      expect(got).not_to include('Liquid error: internal')
    end
  end
end
