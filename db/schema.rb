# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170716185725) do

  create_table "genres", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genres_movies", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "movie_id", null: false
    t.bigint "genre_id", null: false
    t.index ["genre_id"], name: "index_genres_movies_on_genre_id"
    t.index ["movie_id"], name: "index_genres_movies_on_movie_id"
  end

  create_table "movie_actors", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "movie_id", null: false
    t.bigint "person_id", null: false
  end

  create_table "movie_directors", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "movie_id", null: false
    t.bigint "person_id", null: false
  end

  create_table "movie_writers", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "movie_id", null: false
    t.bigint "person_id", null: false
  end

  create_table "movies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "imdb_id"
    t.integer "imdb_id_int"
    t.string "movie_type"
    t.string "primary_title"
    t.string "original_title"
    t.integer "start_year"
    t.integer "end_year"
    t.integer "runtime"
    t.string "poster"
    t.float "average_rating", limit: 24
    t.integer "num_votes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["imdb_id_int"], name: "index_movies_on_imdb_id_int", unique: true
  end

  create_table "people", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "imdb_id"
    t.string "name"
    t.integer "birth_year"
    t.integer "death_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "professions"
  end

  create_table "person_known_for_movies", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "movie_id", null: false
    t.bigint "person_id", null: false
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.string "email"
    t.string "username"
    t.string "password_digest"
    t.string "token"
    t.text "description"
    t.index ["token"], name: "index_users_on_token", unique: true
  end

end
