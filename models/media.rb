class Media
  require 'rack/mime'

  def initialize(file_hash)
    @file = file_hash[:tempfile]
    @time = Time.now.utc
puts "file_hash: #{file_hash}"
    @type = file_hash[:type]
puts "type: #{@type}"
puts "slugify: #{slugify}"
    @filename = file_hash[:filename] || slugify + Rack::Mime::MIME_TYPES.invert[@type]
  end

  def view_properties
    {
      filename: @filename,
      year: @time.year,
      month: @time.month,
      day: @time.day
    }
  end

  def slug
    @slug ||= slugify
  end

  def slugify
    return "#{@time.strftime('%d-%H%M%S')}-#{SecureRandom.hex.to_s}"
  end

  def file
    @file
  end
end
