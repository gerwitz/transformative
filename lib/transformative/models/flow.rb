class Flow < Sequel::Model

  # def handles_type?(type)
  #   return post_types.contains(type)
  # end

  def post_type
    return Transformative::Post::TYPES[post_type_id].to_s
  end

  def url_for_post(post)
    return post.properties.inspect
  end

  def content_for_post(post)
    return post.properties.inspect
  end

end
