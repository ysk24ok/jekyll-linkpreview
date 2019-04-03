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
  attr_reader :markup
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
      markup = 'https://github.com'
      tokenizer = Liquid::Tokenizer.new('')
      parse_context = Liquid::ParseContext.new
      @tag = TestLinkpreviewTag.parse(nil, markup, tokenizer, parse_context)
    end

    context 'when the page has all required properties' do
      before do
        allow(@tag).to receive(:fetch_og_properties).and_return({
          'og:title' => ['Build software better, together'],
          'og:url' => ['https://github.com'],
          'og:image' => ['https://github.githubassets.com/images/modules/open_graph/github-logo.png'],
          'og:description' => ['GitHub is where people build software.']
        })
        allow(@tag).to receive(:save_cache_file)
      end

      it 'can extract all properties' do
        properties = @tag.get_properties()
        expect(properties['title']).to eq 'Build software better, together'
        expect(properties['url']).to eq 'https://github.com'
        expect(properties['image']).to eq 'https://github.githubassets.com/images/modules/open_graph/github-logo.png'
        expect(properties['description']).to eq 'GitHub is where people build software.'
        expect(properties['domain']).to eq 'github.com'
      end
    end

    context "when 'og:url' is http" do
      before do
        allow(@tag).to receive(:fetch_og_properties).and_return({
          'og:url' => ['http://hoge.org/foo/bar']
        })
        allow(@tag).to receive(:save_cache_file)
      end

      it 'can extract domain' do
        properties = @tag.get_properties()
        expect(properties['url']).to eq 'http://hoge.org/foo/bar'
        expect(properties['domain']).to eq 'hoge.org'
      end
    end

    context 'when the page has no og properties' do
      before do
        allow(@tag).to receive(:fetch_og_properties).and_return({})
        allow(@tag).to receive(:save_cache_file)
      end

      it 'has no properties' do
        properties = @tag.get_properties()
        expect(properties['title']).to eq nil
        expect(properties['url']).to eq nil
        expect(properties['image']).to eq nil
        expect(properties['description']).to eq nil
        expect(properties['domain']).to eq nil
      end
    end
  end
end
