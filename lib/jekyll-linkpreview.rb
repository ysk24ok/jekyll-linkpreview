require "digest"
require "json"
require 'uri'

require "metainspector"
require "jekyll-linkpreview/version"

module Jekyll
  module Linkpreview
    class Properties
      def initialize(properties, template_file)
        @properties = properties
        @template_file = template_file
      end

      def to_hash()
        @properties
      end

      def to_hash_for_custom_template()
        hash_for_custom_template = {}
        @properties.each{ |key, value|
          hash_for_custom_template[key] = value
          # NOTE: 'link_*' variables will be deleted in v1.0.0.
          hash_for_custom_template['link_' + key] = value
        }
        hash_for_custom_template
      end

      def template_file()
        @template_file
      end
    end

    class OpenGraphPropertiesFactory
      @@template_file = 'linkpreview.html'

      def self.template_file
        @@template_file
      end

      def from_page(page)
        properties = page.meta_tags['property']
        og_properties = {
          # basic metadata (https://ogp.me/#metadata)
          'title' => get_property(properties, 'og:title'),
          'type' => get_property(properties, 'og:type'),
          'url' => get_property(properties, 'og:url'),
          'image' => convert_to_absolute_url(get_property(properties, 'og:image'), page.root_url),
          # optional metadata (https://ogp.me/#optional)
          ## image
          'image_secure_url' => convert_to_absolute_url(get_property(properties, 'og:image:secure_url'), page.root_url),
          'image_type' => get_property(properties, 'og:image:type'),
          'image_width' => get_property(properties, 'og:image:width'),
          'image_height' => get_property(properties, 'og:image:height'),
          'image_alt' => get_property(properties, 'og:image:alt'),
          ## video
          'video' => convert_to_absolute_url(get_property(properties, 'og:video'), page.root_url),
          'video_secure_url' => convert_to_absolute_url(get_property(properties, 'og:video:secure_url'), page.root_url),
          'video_type' => get_property(properties, 'og:video:type'),
          'video_width' => get_property(properties, 'og:video:width'),
          'video_height' => get_property(properties, 'og:video:height'),
          ## audio
          'audio' => convert_to_absolute_url(get_property(properties, 'og:audio'), page.root_url),
          'audio_secure_url' => convert_to_absolute_url(get_property(properties, 'og:audio:secure_url'), page.root_url),
          'audio_type' => get_property(properties, 'og:audio:type'),
          ## other optional metadata
          'description' => get_property(properties, 'og:description'),
          'determiner' => get_property(properties, 'og:determiner'),
          'locale' => get_property(properties, 'og:locale'),
          'locale_alternate' => get_property(properties, 'og:locale:alternate'),
          'site_name' => get_property(properties, 'og:site_name'),
          # not defined in OGP
          'domain' => page.host,
        }
        Properties.new(og_properties, @@template_file)
      end

      def from_hash(hash)
        Properties.new(hash, @@template_file)
      end

      private
      def get_property(properties, key)
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

    class NonOpenGraphPropertiesFactory
      @@template_file = 'linkpreview_nog.html'

      def self.template_file
        @@template_file
      end

      def from_page(page)
        Properties.new({
          'title' => page.best_title,
          'url' => page.url,
          'description' => page.best_description,
          'domain' => page.host,
        }, @@template_file)
      end

      def from_hash(hash)
        Properties.new(hash, @@template_file)
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
        if Dir.exist?(@@cache_dir) then
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
        if !%w[og:title og:type og:url og:image].all? { |required_tag|
          page.meta_tags['property'].include?(required_tag)
        }
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
