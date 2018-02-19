require "spec_helper"
require "benchmark"

describe AltJsonapi::Serializer do
  include_context "models" do
    let(:movies) { build_movies(1000) }
  end

  # before(:all) { GC.disable }
  # after(:all) { GC.enable }

  context "fast" do
    include_context "fast serializers"
    it "" do
      movies
      serializer = MovieSerializer.new(movies, include: [:director, :cast])
      p Benchmark.measure {
        hash = serializer.serialized_json
        p hash.length
        # p hash
      }.real * 1000
    end
  end

  context "alt" do
    include_context "alt serializers"
    it "" do
      movies
      serializer = MovieSerializer.new(include: [:director, :cast])
      p Benchmark.measure {
        hash = serializer.serialized_json(movies)
        p hash.length
        # p hash
      }.real * 1000
    end
  end


end
