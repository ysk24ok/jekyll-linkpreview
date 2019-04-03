require "digest"
require "json"

require "metainspector"
require "jekyll-linkpreview/version"

module Jekyll
  module Linkpreview
    class LinkpreviewTag < Liquid::Tag
      def initialize(tag_name, markup, parse_context)
        super
        @markup = markup.rstrip()
        @cache_filepath = "_cache/%s.json" % Digest::MD5.hexdigest(@markup)
      end

      def render(context)
        properties = get_properties()
        title       = properties['title']
        url         = properties['url']
        image       = properties['image']
        description = properties['description']
        domain      = properties['domain']
        if title.nil? || url.nil? || image.nil? then
          html = <<-EOS
<div class="jekyll-linkpreview-wrapper">
  <p><a href="#{@markup}" target="_blank">#{@markup}</a></p>
</div>
          EOS
          return html
        end
        html = <<-EOS
<div class="jekyll-linkpreview-wrapper">
  <p><a href="#{@markup}" target="_blank">#{@markup}</a></p>
  <div class="jekyll-linkpreview-wrapper-inner">
    <div class="jekyll-linkpreview-content">
      <div class="jekyll-linkpreview-image">
        <a href="#{url}" target="_blank">
          <img src="#{image}" />
        </a>
      </div>
      <div class="jekyll-linkpreview-body">
        <h2 class="jekyll-linkpreview-title">
          <a href="#{url}" target="_blank">#{title}</a>
        </h2>
        <div class="jekyll-linkpreview-description">#{description}</div>
      </div>
    </div>
    <div class="jekyll-linkpreview-footer">
      <a href="#{url}" target="_blank">#{domain}</a>
    </div>
  </div>
</div>
        EOS
        html
      end

      def get_properties()
        if File.exist?(@cache_filepath) then
          return load_cache_file
        else
          og_properties = fetch_og_properties()
          url = get_og_property(og_properties, 'og:url')
          properties = {
            'title'       => get_og_property(og_properties, 'og:title'),
            'url'         => url,
            'image'       => get_og_property(og_properties, 'og:image'),
            'description' => get_og_property(og_properties, 'og:description'),
            'domain'      => extract_domain(url)
          }
          save_cache_file(properties)
          return properties
        end
      end

      private
      def fetch_og_properties()
        MetaInspector.new(@markup).meta_tags['property']
      end

      private
      def get_og_property(properties, key)
        if !properties.key? key then
          return nil
        end
        properties[key][0]
      end

      private
      def extract_domain(url)
        if url.nil? then
          return nil
        end
        url.match(%r{(http|https)://([^/]+).*})[-1]
      end

      private
      def load_cache_file()
        JSON.parse(File.open(@cache_filepath).read)
      end

      private
      def save_cache_file(properties)
        File.open(@cache_filepath, 'w').write(JSON.generate(properties))
      end
    end
  end
end

Liquid::Template.register_tag("linkpreview", Jekyll::Linkpreview::LinkpreviewTag)
