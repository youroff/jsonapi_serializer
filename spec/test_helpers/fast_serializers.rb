require 'fast_jsonapi'

RSpec.shared_context 'fast serializers' do

  before(:context) do
    class CastSerializer
      include FastJsonapi::ObjectSerializer
      attributes :name, :age
    end

    # class Actor < CastMember; end
    # class Writer < CastMember; end

    class DirectorSerializer
      include FastJsonapi::ObjectSerializer
      attributes :name, :movie_count
    end

    class MovieSerializer
      include FastJsonapi::ObjectSerializer
      attributes :name, :release_year
      has_many :cast#, serializer: CastSerializer
      belongs_to :director
    end
  end

  after(:context) do
    %i[
      MovieSerializer
      CastSerializer
      DirectorSerializer
    ].each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end
end
