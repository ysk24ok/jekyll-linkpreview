require "digest"
require "json"
require 'uri'

require "metainspector"
require "jekyll-linkpreview/version"

module Jekyll
  module Linkpreview
    class OpenGraphProperties
      @@template_file = 'linkpreview.html'

      def initialize(title, url, image, description, domain)
        @title = title
        @url = url
        @image = image
        @description = description
        @domain = domain
      end

      def to_hash()
        {
          'title' => @title,
          'url' => @url,
          'image' => @image,
          'description' => @description,
          'domain' => @domain,
        }
      end

      def to_hash_for_custom_template()
        {
          'link_title' => @title,
          'link_url' => @url,
          'link_image' => @image,
          'link_description' => @description,
          'link_domain' => @domain
        }
      end

      def template_file()
        @@template_file
      end
    end

    class OpenGraphPropertiesFactory
      def from_page(page)
        og_properties = page.meta_tags['property']
        image_url = get_og_property(og_properties, 'og:image')
        title = get_og_property(og_properties, 'og:title')
        url = get_og_property(og_properties, 'og:url')
        image = convert_to_absolute_url(image_url, page.root_url)
        description = get_og_property(og_properties, 'og:description')
        domain = page.host
        OpenGraphProperties.new(title, url, image, description, domain)
      end

      def from_hash(hash)
        OpenGraphProperties.new(
          hash['title'], hash['url'], hash['image'], hash['description'], hash['domain'])
      end

      private
      def get_og_property(properties, key)
        if !properties.key? key then
          return nil
        end
        properties[key].first
      end

      private
      def convert_to_absolute_url(url, domain)
        if url.nil? then
          return nil
        end
        # root relative url
        if url[0] == '/' then
          return URI.join(domain, url).to_s
        end
        url
      end
    end

    class NonOpenGraphProperties
      @@template_file = 'linkpreview_nog.html'

      def initialize(title, url, description, domain)
        @title = title
        @url = url
        @description = description
        @domain = domain
      end

      def to_hash()
        {
          'title' => @title,
          'url' => @url,
          'description' => @description,
          'domain' => @domain,
        }
      end

      def to_hash_for_custom_template()
        {
          'link_title' => @title,
          'link_url' => @url,
          'link_description' => @description,
          'link_domain' => @domain
        }
      end

      def template_file()
        @@template_file
      end
    end

    class NonOpenGraphPropertiesFactory
      def from_page(page)
        NonOpenGraphProperties.new(page.best_title, page.url, get_description(page), page.host)
      end

      def from_hash(hash)
        NonOpenGraphProperties.new(
          hash['title'], hash['url'], hash['description'], hash['domain'])
      end

      private
      def get_description(page)
        if !page.parsed.xpath('//p[normalize-space()]').empty? then
          return page.parsed.xpath('//p[normalize-space()]').map(&:text).first[0..180] + "..."
        else
          return "..."
        end
      end
    end

    class LinkpreviewTag < Liquid::Tag
      @@cache_dir = '_cache'
      @@template_dir = '_includes'

      def initialize(tag_name, markup, parse_context)
        super
        @markup = markup.strip()
      end

      def render(context)
        url = get_url_from(context)
        properties = get_properties(url)
        render_linkpreview context, properties
      end

      def get_properties(url)
        cache_filepath = "#{@@cache_dir}/%s.json" % Digest::MD5.hexdigest(url)
        if File.exist?(cache_filepath) then
          hash = load_cache_file(cache_filepath)
          return create_properties_from_hash(hash)
        end
        page = fetch(url)
        properties = create_properties_from_page(page)
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
      def fetch(url)
        MetaInspector.new(url)
      end

      private
      def load_cache_file(filepath)
        JSON.parse(File.open(filepath).read)
      end

      protected
      def save_cache_file(filepath, properties)
        File.open(filepath, 'w') { |f| f.write JSON.generate(properties.to_hash) }
      end

      private
      def create_properties_from_page(page)
        if page.meta_tags['property'].empty? then
          factory = NonOpenGraphPropertiesFactory.new
        else
          factory = OpenGraphPropertiesFactory.new
        end
        factory.from_page(page)
      end

      private
      def create_properties_from_hash(hash)
        if hash['image'] then
          factory = OpenGraphPropertiesFactory.new
        else
          factory = NonOpenGraphPropertiesFactory.new
        end
        factory.from_hash(hash)
      end

      private
      def render_linkpreview(context, properties)
        template_path = get_custom_template_path context, properties
        if File.exist?(template_path)
          hash = properties.to_hash_for_custom_template
          gen_custom_template template_path, hash
        else
          gen_default_template properties.to_hash
        end
      end

      private
      def get_custom_template_path(context, properties)
        source_dir = get_source_dir_from context
        File.join source_dir, @@template_dir, properties.template_file
      end

      private
      def get_source_dir_from(context)
        File.absolute_path context.registers[:site].config['source'], Dir.pwd
      end

      private
      def gen_default_template(hash)
        title = hash['title']
        url = hash['url']
        description = hash['description']
        domain = hash['domain']
        image = hash['image']
        image_html = ""
        if image then
          image_html = <<-EOS
<div class="jekyll-linkpreview-image">
  <a href="#{url}" target="_blank">
    <img src="#{image}" />
  </a>
</div>
EOS
        end
        html = <<-EOS
<div class="jekyll-linkpreview-wrapper">
  <p><a href="#{url}" target="_blank">#{url}</a></p>
  <div class="jekyll-linkpreview-wrapper-inner">
    <div class="jekyll-linkpreview-content">
#{image_html}
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

      private
      def gen_custom_template(template_path, hash)
        template = File.read template_path
        Liquid::Template.parse(template).render!(hash)
      end
    end
  end
end

Liquid::Template.register_tag("linkpreview", Jekyll::Linkpreview::LinkpreviewTag)
