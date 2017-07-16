class Movie < ApplicationRecord
  @@genres_cache #used to easily obtain the genre id we need
  
  has_and_belongs_to_many :genres
  has_and_belongs_to_many :directors, class_name: "Person", join_table: "movie_directors"
  has_and_belongs_to_many :writers, class_name: "Person", join_table: "movie_writers"
  has_and_belongs_to_many :actors, class_name: "Person", join_table: "movie_actors"
  
  def self.bulk_insert (movies)
    unless defined? @@genres_cache
      make_genres_cache
    end
    
    assign_genres = {}
    movies_values = movies.map do
      # @type [Array<String>] movie
      |movie|
      imdb_id_int = movie["tconst"][2..-1].to_i #used for indexing purposes, otherwise i'd have to inner join on varchar which is very slow
      end_year = (movie["endYear"] == '\N') ? nil : movie["endYear"].to_i
      genres = (movie["genres"] == '\N') ? nil : movie["genres"].split(",")
      
      if genres != nil
        # put the genres these film has in a hash for later use (i.e. for inserting in a bulk operation)
        assign_genres[imdb_id_int] = genres
        
        genres.each do |genre_name|
          if !@@genres_cache.include?(genre_name)
            genre = Genre.new({name: genre_name})
            genre.save
            @@genres_cache[genre.name] = genre.id
          end
        end
      end

      sanitize_sql_for_assignment([
        "\n(?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())",
        movie["tconst"], imdb_id_int, movie["titleType"], movie["primaryTitle"], movie["originalTitle"], movie["startYear"].to_i, end_year, movie["runtimeMinutes"].to_i
      ])
    end.join(",")
    
    # bulk insert the movies
    insert_movies_sql = "
      INSERT INTO #{Movie.table_name}
        (`imdb_id`, `imdb_id_int`, `movie_type`, `primary_title`, `original_title`, `start_year`, `end_year`, `runtime`, `created_at`, `updated_at`) 
      VALUES #{movies_values}
    "
    ActiveRecord::Base.connection.execute(insert_movies_sql)

    #generetes a "input" table we use in the query below to provide input data
    genres_movies_input = assign_genres.map do |imdb_id_int, genres|
      genres.map do |genre|
        sanitize_sql_for_assignment([
          "SELECT ? `imdb_id_int`, ? `genre_id` \n",
          imdb_id_int, @@genres_cache[genre]
        ])
      end.join("UNION\n")
    end.join("UNION\n")

    #bulk insert the relationships between movies and genres
    insert_genres_movies_sql = "
      INSERT INTO genres_movies (`movie_id`, `genre_id`)
        SELECT m.id, input.genre_id
        FROM (
          #{genres_movies_input}
        ) input
        INNER JOIN `movies` m ON m.imdb_id_int = input.imdb_id_int 
    "
    ActiveRecord::Base.connection.execute(insert_genres_movies_sql)
  end
  
  private
    
    # this method just creates a hash with the key being a genre name and the value being the corresponding id 
    def self.make_genres_cache
      @@genres_cache = {}
      Genre.all.each do |genre|
        @@genres_cache[genre.name] = genre.id
      end
    end
  
end
