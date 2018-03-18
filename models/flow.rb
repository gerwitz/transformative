class Flow < Sequel::Model

  # def handles_type?(type)
  #   return post_types.contains(type)
  # end
  many_to_one :site
  many_to_one :store
  many_to_one :media_store, class: :Store

  def post_type
    return Post::TYPES[post_type_id].to_s
  end

  def url_for_post(post)
    props = post.view_properties
    relative_url = "#{props[:year]}/#{props[:month]}/#{props[:day]}/#{props[:slug]}.html"
    return URI.join(site.url, relative_url).to_s
  end

  def file_path_for_post(post)
    props = post.view_properties
    relative_path = "source/notes/#{props[:year]}/#{props[:month]}/#{props[:day]}-#{props[:slug]}.html.md"
    return relative_path
  end

  def file_content_for_post(post)
    props = post.view_properties
puts "🐌 file_content_for_post: #{props[:slug].inspect}"
    return """\
layout: note
date: #{props[:date_time]}
slug: #{props[:slug]}
category: microblog
---
#{props[:content]}
"""
  end

  def store_post(post)
# puts "💡 storing post: #{post.inspect}"
# puts "💡 destination: #{store.location} - #{file_path_for_post(post)}"
# puts "💡 content: #{file_content_for_post(post)}"
    store.put(file_path_for_post(post), file_content_for_post(post))
    return url_for_post(post)
  end

  def url_for_media(media)
    props = media.view_properties
    relative_url = "#{props[:year]}/#{props[:month]}/#{props[:day]}/#{props[:slug]}#{props[:extension]}"
    return URI.join(site.url, relative_url).to_s
  end

  def file_path_for_media(media)
    props = media.view_properties
    relative_path = "source/notes/#{props[:year]}/#{props[:month]}/#{props[:day]}-#{props[:slug]}#{props[:extension]}"
    return relative_path
  end

  def store_file(media)
    media_store.upload(file_path_for_media(media), media.file)
    return url_for_media(media)
  end

  def process_attachments(attachments)
    if attachments.is_a?(Array)
      attachments.map do |attachment|
        process_attachment(attachment)
      end
    else
      [process_attachment(attachments)]
    end
  end

  def process_attachment(attachment)
    if self.valid_url?(attachment)
      # TODO extract file from url and store?
      file
    else
      store_file(attachment)
    end
  end

private

  def self.valid_url?(url)
    begin
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
    end
  end

end
