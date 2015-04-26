# encoding: UTF-8

module JekyllImport
  module Importers
    class MTIF < Importer
      def self.require_deps
        JekyllImport.require_with_fallback(%w[
          rubygems
          fileutils
          safe_yaml
          reverse_markdown
          mtif
        ])
      end

      def self.specify_options(c)
        c.option 'source', '--source FILE', 'Movable Type Import Format file'
      end

      def self.process(options)
        source = options.fetch('source')

        mtif_input = ::MTIF.load_file(source)

        # Ignored for now: comment ping
        translated_keys = [:author, :title, :basename, :date, :status, :unique_url, :excerpt, :category, :tag, :keywords, :body, :extended_body]
        ignored_keys = [:comment, :ping]
        
        mtif_input.posts.each do |post|
          extra_keys = post.data.keys - translated_keys - ignored_keys

          front_matter = {
            :layout => 'post',
            :author => post.author,
            :title => post.title,
            :date => post.date,
            :published => (post.status == 'Publish'),
            :basename => post.basename,
            :permalink => permalink(post),
            :categories => post.category,
            :tags => post.tag,
            :keywords => post.keywords.nil? ? nil : post.keywords.chomp.gsub("\n",","),
            :excerpt => post.excerpt
          }.delete_if {|key, value| value.nil? || (value.respond_to?(:empty?) && value.empty?)}
          
          extra_keys.each do |key|
            extra_key = "mtif_#{key}".to_sym
            front_matter[extra_key] = post.send(key)
          end

          body = extract_body(post)

          post_file = File.open(output_filename(post), "w")
          post_file << front_matter.to_yaml
          post_file << "---\n"
          post_file << body
          post_file.close
        end
      end

      def output_filename(post)
        "_posts/#{post.date.strftime('%Y-%m-%d')}-#{post.basename}.md"
      end

      def body(post)
        content = post.body
        content += "\n" + post.extended_body unless post.extended_body.nil? || post.extended_body.empty?
        ReverseMarkdown.convert content
      end
      
      def self.permalink(post)
        URI.parse(post.unique_url).path
      end
    end
  end
end
