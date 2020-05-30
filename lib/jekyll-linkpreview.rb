require "digest"
require "json"

require "metainspector"
require "jekyll-linkpreview/version"

module Jekyll
  module Linkpreview
    class OpenGraphProperties
      def get(url)
        og_properties = fetch(url)
        og_url = get_og_property(og_properties, 'og:url')
        domain = extract_domain(og_url)
        image_url = get_og_property(og_properties, 'og:image')
        {
          'title'       => get_og_property(og_properties, 'og:title'),
          'url'         => og_url,
          'image'       => convert_to_absolute_url(image_url, domain),
          'description' => get_og_property(og_properties, 'og:description'),
          'domain'      => domain
        }
      end

      private
      def get_og_property(properties, key)
        if !properties.key? key then
          return nil
        end
        properties[key][0]
      end

      private
      def fetch(url)
        MetaInspector.new(url).meta_tags['property']
      end

      private
      def convert_to_absolute_url(url, domain)
        if url.nil? then
          return nil
        end
        # root relative url
        if url[0] == '/' then
          return "//#{domain}#{url}"
        end
        url
      end

      private
      def extract_domain(url)
        if url.nil? then
          return nil
        end
        m = url.match(%r{(http|https)://([^/]+).*})
        if m.nil? then
          return nil
        end
        m[-1]
      end
    end

    class NonOpenGraphProperties
      def get(url)
        nog_properties = fetch(url)
        {
          'title'       => nog_properties.title,
          'url'         => nog_properties.url,
          'description' => nog_properties.parsed.xpath("//p").first.children.to_s,
          'domain'      => nog_properties.root_url
        }
      end

      private
      def fetch(url)
        MetaInspector.new(url)
      end
    end

    class LinkpreviewTag < Liquid::Tag
      @@cache_dir = '_cache'

      def initialize(tag_name, markup, parse_context)
        super
        @markup = markup.strip()
        @og_properties = OpenGraphProperties.new
        @nog_properties = NonOpenGraphProperties.new
      end

      def render(context)
        url = get_url_from(context)
        properties = get_properties(url)
        title       = properties['title']
        image       = properties['image']
        description = properties['description']
        domain      = properties['domain']

        if image.nil? then
          render_linkpreview_nog(context, url, title, description, domain)
        else
          render_linkpreview_og(context, url, title, image, description, domain)
        end
      end

      def get_properties(url)
        cache_filepath = "#{@@cache_dir}/%s.json" % Digest::MD5.hexdigest(url)
        if File.exist?(cache_filepath) then
          return load_cache_file(cache_filepath)
        end
        meta = MetaInspector.new(url).meta_tags['property']
        if meta.has_key?('og:title') then
          properties = @og_properties.get(url)
        else
          properties = @nog_properties.get(url)
        end
        if Dir.exists?(@@cache_dir) then
          save_cache_file(cache_filepath, properties)
        else
          # TODO: This message will be shown at all linkprevew tag
          warn "'#{@@cache_dir}' directory does not exist. Create it for caching."
        end
        properties
      end

      private
      def get_url_from(context)
        context[@markup]
      end

      private
      def load_cache_file(filepath)
        JSON.parse(File.open(filepath).read)
      end

      protected
      def save_cache_file(filepath, properties)
        File.open(filepath, 'w') { |f| f.write JSON.generate(properties) }
      end

      private
      def render_linkpreview_og(context, url, title, image, description, domain)
        template_path = get_linkpreview_og_template()
        if File.exist?(template_path)
          template_file = File.read template_path
          site = context.registers[:site]
          template_file = (Liquid::Template.parse template_file).render site.site_payload.merge!({"link_url" => url, "link_title" => title, "link_image" => image, "link_description" => description, "link_domain" => domain})
        else
          html = <<-EOS
<div class="jekyll-linkpreview-wrapper">
  <p><a href="#{url}" target="_blank">#{url}</a></p>
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
      <a href="//#{domain}" target="_blank">#{domain}</a>
    </div>
  </div>
</div>
EOS
          html
        end
      end

      private
      def render_linkpreview_nog(context, url, title, description, domain)
        template_path = get_linkpreview_nog_template()
        if File.exist?(template_path)
          template_file = File.read template_path
          site = context.registers[:site]
          template_file = (Liquid::Template.parse template_file).render site.site_payload.merge!({"link_url" => url, "link_title" => title, "link_description" => description, "link_domain" => domain})
        else
          html = <<-EOS
<div class="jekyll-linkpreview-wrapper">
  <p><a href="#{url}" target="_blank">#{url}</a></p>
  <div class="jekyll-linkpreview-wrapper-inner">
    <div class="jekyll-linkpreview-content">
      <div class="jekyll-linkpreview-body">
        <h2 class="jekyll-linkpreview-title">
          <a href="#{url}" target="_blank">#{title}</a>
        </h2>
        <div class="jekyll-linkpreview-description">#{description}</div>
      </div>
    </div>
    <div class="jekyll-linkpreview-footer">
      <a href="//#{domain}" target="_blank">#{domain}</a>
    </div>
  </div>
</div>
EOS
          html
        end
      end

      private
      def get_linkpreview_og_template()
        File.join Dir.pwd, "_includes", "linkpreview.html"
      end

      private
      def get_linkpreview_nog_template()
        File.join Dir.pwd, "_includes", "linkpreview_nog.html"
      end
    end
  end
end

Liquid::Template.register_tag("linkpreview", Jekyll::Linkpreview::LinkpreviewTag)
