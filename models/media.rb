class Media
  require 'rack/mime'

  def initialize(file_hash)
    @file = file_hash[:tempfile]
    @time = Time.now.utc

    type = file_hash[:type]
    if filename = file_hash[:filename]
      @slug = File.basename(filename)
      extension = File.extname(filename)
    end
    @extension = extension || Rack::Mime::MIME_TYPES.invert[type]
  end

  def view_properties
    {
      slug: slug,
      extension: @extension,
      year: @time.year,
      month: @time.month,
      day: @time.day
    }
  end

  def slug
    @slug ||= slugify
  end

  def slugify
    return "#{@time.strftime('%H%M%S')}-#{SecureRandom.hex(8).to_s}"
  end

  def extensionify
    return
  end

  def file
    @file
  end
end
