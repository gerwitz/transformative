module Transformative
  class Card < Post

    def initialize(properties, url=nil)
      super(properties, url)
    end

    def h_type
      'h-card'
    end

    def filename
      "/card/#{@url}.json"
    end

    def generate_url
      generate_url_slug
    end

  end
end