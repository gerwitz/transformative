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
    return """\
layout: note
date: #{post.date_time}
slug: #{post.slug}
category: microblog
---
#{post.content}
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
    relative_url = "#{props[:year]}/#{props[:month]}/#{props[:day]}/#{props[:slug]}.html"
    return URI.join(site.url, relative_url).to_s
  end

  def file_path_for_media(media)
    props = post.view_properties
    relative_path = "source/notes/#{props[:year]}/#{props[:month]}/#{props[:day]}-#{props[:slug]}.html.md"
    return relative_path
  end

  def store_file(media)
    store.upload(file_path_for_media(media), media.file)
    return url_for_media(media)
  end

end
