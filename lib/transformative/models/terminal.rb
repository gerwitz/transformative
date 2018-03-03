module Transformative
  class Terminal < Sequel::Model

    TYPES = [
      {id: 1, desc: "GitHub"}
    ]

    many_to_one :site

    def type_desc
      match = TYPES.detect { |t| t[:id] = type_id }
      return match[:desc]
    end

  end
end
