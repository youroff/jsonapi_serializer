require 'alt_jsonapi'

module AltJsonapiTest
  AltJsonapi.set_type_namespace_separator :ignore

  class AuthorSerializer
    include AltJsonapi::Serializer
    attributes :name, :age
  end

  class CharacterSerializer
    include AltJsonapi::Serializer
    attributes :name
  end

  class BookSerializer
    include AltJsonapi::Serializer
    attributes :name, :isbn, :year
    belongs_to :author, serializer: AuthorSerializer
    has_many :characters, serializer: CharacterSerializer
  end

  def self.base(records, type = :hash)
    serializer = BookSerializer.new()
    case type
    when :hash
      serializer.serializable_hash(records)
    when :json
      serializer.serialized_json(records)
    end
  end

  def self.with_included(records, type = :hash)
    serializer = BookSerializer.new(include: [:author])
    case type
    when :hash
      serializer.serializable_hash(records)
    when :json
      serializer.serialized_json(records)
    end
  end
end
