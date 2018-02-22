require 'jsonapi_serializer'

module JsonapiSerializerTest
  JsonapiSerializer.set_type_namespace_separator :ignore

  class AuthorSerializer
    include JsonapiSerializer::Base
    attributes :name, :age
  end

  class CharacterSerializer
    include JsonapiSerializer::Base
    attributes :name
  end

  class BookSerializer
    include JsonapiSerializer::Base
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
