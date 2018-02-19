require 'ffaker'

class Book
  attr_accessor :id, :name, :isbn, :year, :author, :author_id, :characters, :character_ids, :librarians, :librarian_ids

  @characters = []
  @character_ids = []

  def initialize(id, opts = {})
    @id = id
    @name = FFaker::Book.title
    @isbn = FFaker::Book.isbn
    @year = 1990 + rand(30)
    put_author(opts[:author_pool])
    put_characters(opts[:character_pool])
  end

  def put_author(pool)
    @author = pool.sample
    @author_id = @author.id
  end

  def put_characters(pool)
    @characters = (1..10).map { pool.sample }.uniq
    @character_ids = @characters.map(&:id)
  end
end

class Author
  attr_accessor :id, :name, :age, :consultants, :consultant_ids
  def initialize(id, consultant_pool)
    @id = id
    @name = FFaker::Name.name
    @age = 20 + rand(40)
    @consultants = (1..3).map { consultant_pool.sample }.uniq
    @consultant_ids = @consultants.map(&:id)
  end
end

class Consultant
  attr_accessor :id, :name
  def initialize(id)
    @id = id
    @name = FFaker::Name.name
  end
end

class Character
  attr_accessor :id, :name
  def initialize(id)
    @id = id
    @name = FFaker::Name.name
  end
end

class Villain < Character
  attr_accessor :kills
  def initialize(id)
    super(id)
    @kills = rand(20)
  end
end

class Hero < Character
  attr_accessor :kills
  def initialize(id)
    super(id)
    @kills = rand(20)
  end
end

class Models
  def initialize(count)
    consultant_pool = (1..50).map { |id| Consultant.new(id) }
    author_pool = (1..50).map { |id| Author.new(id, consultant_pool) }
    character_pool = (1..300).map { |id| [Hero, Villain].sample.new(id) }

    @storage = (1..count).map do |id|
      Book.new(id, character_pool: character_pool, author_pool: author_pool)
    end
  end

  def take(n)
    @storage.take(n)
  end
end
