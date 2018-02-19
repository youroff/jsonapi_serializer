require 'ffaker'

RSpec.shared_context 'models' do

  before(:context) do
    class Movie
      attr_accessor :id, :name, :release_year, :cast, :director, :director_id, :cast_ids
      # def director_id
      #   director.id
      # end
      #
      # def cast_ids
      #   cast.map(&:id)
      # end
    end

    class CastMember
      attr_accessor :id, :name, :age
    end

    class Actor < CastMember; end
    class Writer < CastMember; end

    class Director
      attr_accessor :id, :name, :movie_count
    end
  end

  let(:director_pool) {
    (1..10).map do |id|
      build_director(id)
    end
  }

  let(:cast_pool) {
    (1..50).map do |id|
      build_cast(id)
    end
  }

  def build_cast(id)
    [Actor, Writer].sample.new.tap do |cast|
      cast.id = id
      cast.name = FFaker::Name.name
      cast.age = 18 + rand(50)
    end
  end

  def build_director(id)
    Director.new.tap do |director|
      director.id = id
      director.name = FFaker::Name.name
      director.movie_count = 1 + rand(10)
    end
  end

  def build_movies(count)
    (1..count).map {|id| build_movie(id)}
  end

  def build_movie(id)
    Movie.new.tap do |movie|
      movie.id = id
      movie.name = FFaker::Movie.title
      movie.release_year = 1990 + rand(30)
      movie.director = director_pool.sample
      movie.director_id = movie.director.id
      movie.cast = (1..3).map do
        cast_pool.sample
      end
      movie.cast_ids = movie.cast.map(&:id)
    end
  end

  def build_all_movies
    @movies ||= build_movies(1000)
  end

  after(:context) do
    %i[
      Movie
      CastMember
      Actor
      Writer
      Director
    ].each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end
end
