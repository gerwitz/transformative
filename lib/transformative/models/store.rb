# module Transformative
  class Store < Sequel::Model

    TYPES = {
      1 => :Github
    }

    plugin :single_table_inheritance, :type_id, model_map: TYPES

    many_to_one :domain

    def type_desc
      return "Unknown"
    end

  end

  class StoreError < Transformative::TransformativeError
    def initialize(message)
      super("store", message)
    end
  end

# end
