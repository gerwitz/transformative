module Transformative
  class Site < Sequel::Model
    one_to_many :terminals
  end
end
