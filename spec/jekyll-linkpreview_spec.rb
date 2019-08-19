require 'jekyll'
require 'rspec/mocks/standalone'
#require_relative '../lib/jekyll/linkpreview'
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
  attr_reader :markup, :og_properties

  protected
  def save_cache_file(filepath, properties)
    nil
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

  describe '#get_properties' do
    before do
      markup = ''
      tokenizer = Liquid::Tokenizer.new('')
      parse_context = Liquid::ParseContext.new
      @tag = TestLinkpreviewTag.parse(nil, markup, tokenizer, parse_context)
    end

    context 'when the page has all required properties' do
      before do
        allow(@tag.og_properties).to receive(:fetch).and_return({
          'og:title' => ['Build software better, together'],
          'og:url' => ['https://github.com'],
          'og:image' => ['https://github.githubassets.com/images/modules/open_graph/github-logo.png'],
          'og:description' => ['GitHub is where people build software.']
        })
      end

      it 'can extract all properties' do
        properties = @tag.get_properties('https://github.com')
        expect(properties['title']).to eq 'Build software better, together'
        expect(properties['url']).to eq 'https://github.com'
        expect(properties['image']).to eq 'https://github.githubassets.com/images/modules/open_graph/github-logo.png'
        expect(properties['description']).to eq 'GitHub is where people build software.'
        expect(properties['domain']).to eq 'github.com'
      end
    end

    context "when 'og:url' is http" do
      before do
        allow(@tag.og_properties).to receive(:fetch).and_return({
          'og:url' => ['http://hoge.org/foo/bar']
        })
      end

      it 'can extract domain' do
        properties = @tag.get_properties('https://github.com')
        expect(properties['url']).to eq 'http://hoge.org/foo/bar'
        expect(properties['domain']).to eq 'hoge.org'
      end
    end

    context 'when the page has no og properties' do
      before do
        allow(@tag.og_properties).to receive(:fetch).and_return({})
      end

      it 'has no properties' do
        properties = @tag.get_properties('https://github.com')
        expect(properties['title']).to eq nil
        expect(properties['url']).to eq nil
        expect(properties['image']).to eq nil
        expect(properties['description']).to eq nil
        expect(properties['domain']).to eq nil
      end
    end
  end
end

Liquid::Template.register_tag("test_linkpreview", TestLinkpreviewTag)

RSpec.describe "Integration test" do
  context "when URL is directly passed to the tag" do
    it "can generate link preview" do
      t = Liquid::Template.new
      t.parse("{% test_linkpreview https://github.com %}")
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
