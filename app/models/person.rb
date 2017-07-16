class Person < ApplicationRecord
  has_and_belongs_to_many :directed_movies, class_name: "Movie", join_table: "movie_directors"
  has_and_belongs_to_many :written_movies, class_name: "Movie", join_table: "movie_writers"
  has_and_belongs_to_many :acted_in_movies, class_name: "Movie", join_table: "movie_actors"
  has_and_belongs_to_many :known_for_movies, class_name: "Movie", join_table: "person_known_for_movies"
end
