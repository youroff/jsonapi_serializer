require 'fast_jsonapi'

module FastJsonapiTest

  class AuthorSerializer
    include FastJsonapi::ObjectSerializer
    attributes :name, :age
  end

  class CharacterSerializer
    include FastJsonapi::ObjectSerializer
    attributes :name
  end

  class BookSerializer
    include FastJsonapi::ObjectSerializer
    attributes :name, :isbn, :year
    belongs_to :author
    has_many :characters
  end

  def self.base(records, type = :hash)
    serializer = BookSerializer.new(records)
    case type
    when :hash
      serializer.serializable_hash
    when :json
      serializer.serialized_json
    end
  end

  def self.with_included(records, type = :hash)
    serializer = BookSerializer.new(records, include: [:author])
    case type
    when :hash
      serializer.serializable_hash
    when :json
      serializer.serialized_json
    end
  end
end
