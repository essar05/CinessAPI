require 'zlib'
require 'stringio'
require 'rubygems/package'

class UpdateImdbMoviesJob < ApplicationJob
  queue_as :default

  def perform(force = false, subjobs = ["download_data", "unzip_data", "update_db_cache"])
    if force != true and ran_today?
      Rails.logger.info "Job already ran today"
      return
    end
    
    if subjobs.include?("download_data")
      download_data
    end
    
    if subjobs.include?("unzip_data")
      unzip_data
    end
    
    if subjobs.include?("update_db_cache")
      ActiveRecord::Base.logger.level = 1
      
      update_titles
      #update_people
      #update_crew
      #update_cast
      #update_ratings
    end
    
  end
  
  private
  
    def update_titles
      t1 = Time.now

      # used to obtain the number of lines the file has, so we can display a percentage parsed
      size_file = File.open(Rails.root + "download/size.txt", "r")
      lines_count = 0
      lines_count_f = 0.0
      size_file.each_line do |line|
        lines_part = line.split(",")
        if lines_part[0] == "title.basics.tsv"
          lines_count = lines_part[1].to_i
          lines_count_f = lines_count.to_f
          break
        end
      end
      
      # we're executing bulk queries, so here we define the size of a chunk of movies
      chunk_size = 5000
      chunk = []
      
      do_insert = false # wether to start inserting from this movie onwards or not
      last_movie_id = "" # holds the imdb_id of the last movie in the db. not expecting older movies to change their data, so we can skip over them 
      last_movie = Movie.last
      if last_movie != nil
        last_movie_id = last_movie.imdb_id
      end
      
      File.open(Rails.root + "download/title.basics.tsv", 'r') do |file|
        csv = CSV.new(file, { col_sep: "\t", quote_char: "\x00", headers: true })
        while row = csv.shift
          if row['tconst'] > last_movie_id
            do_insert = true
          end

          next unless do_insert
          next if row["titleType"] != "movie" && row["titleType"] != "tvMovie" && row["titleType"] != "tvSeries"
          
          chunk.push(row)
  
          if chunk.size == chunk_size
            Movie.bulk_insert(chunk)
            chunk = [] # reset the chunk after we've built a full one
            puts "Inserting movies " + ((csv.lineno / lines_count_f) * 100).round(2).to_s + "%"
          end
        end
      end
      
      if chunk.size > 0
        Movie.bulk_insert(chunk)
        puts "Inserting movies 100%"
      end
      
      t2 = Time.now

      puts "Inserting movies: " + (t2 - t1).to_s + " seconds"
    end
  
    def update_crew
      File.open(Rails.root + "download/title.crew.tsv.gz", "rb") do |file|
        gzip = Zlib::GzipReader.new(file, { encoding: "UTF-8" })
        total_size = gzip.to_io.size.to_f
        i = 0
        gzip.each_line do # @type [String] line  
          |line|

          i += 1
          next if i - 1 == 0
          break if i == 10 #for testing purposes stop after 9 titles or wtv

          line.sub! '\N', ''
          
          progress = ((gzip.pos / total_size) * 100).round(2)
          
          # tconst	directors	writers
          # @type csv_line [Array<String>]
          csv_line = CSV.parse_line(line, { col_sep: "\t", quote_char: "\x00" })

          directors = []
          writers = []
          if csv_line[1] != nil
            directors_ids = csv_line[1].split(",")
            directors = Person.where(imdb_id: directors_ids)
          end
          if csv_line[2] != nil
            writers_ids = csv_line[2].split(",")
            writers = Person.where(imdb_id: writers_ids)
          end
          
          movie = Movie.find_by(imdb_id: csv_line[0])
          if movie != nil
            puts "[" + progress.to_s + "%] Updating crew for movie: " + movie.imdb_id + "(" + movie.primaryTitle + ")"
            movie.update({
              directors: directors,
              writers: writers
            })
          end
        end

        gzip.close
      end
    end
  
    def update_cast
      File.open(Rails.root + "download/title.principals.tsv.gz", "rb") do |file|
        gzip = Zlib::GzipReader.new(file, { encoding: "UTF-8" })
        total_size = gzip.to_io.size.to_f
        i = 0
        gzip.each_line do # @type [String] line  
          |line|

          i += 1
          next if i - 1 == 0
          break if i == 10 #for testing purposes stop after 9 titles or wtv
          
          progress = ((gzip.pos / total_size) * 100).round(2)
          
          # tconst	principalCast
          # @type csv_line [Array<String>]
          csv_line = CSV.parse_line(line, { col_sep: "\t", quote_char: "\x00" })

          actors = []
          if csv_line[1] != nil
            actors_ids = csv_line[1].split(",")
            actors = Person.where(imdb_id: actors_ids)
          end
          
          movie = Movie.find_by(imdb_id: csv_line[0])
          if movie != nil
            puts "[" + progress.to_s + "%] Updating cast for movie: " + movie.imdb_id + "(" + movie.primaryTitle + ")"
            movie.update({
              actors: actors
            })
          end
        end

        gzip.close
      end
    end
  
    def update_ratings
      File.open(Rails.root + "download/title.ratings.tsv.gz", "rb") do |file|
        gzip = Zlib::GzipReader.new(file, { encoding: "UTF-8" })
        # @type file_io [File]
        total_size = gzip.to_io.size.to_f
        
        i = 0
        gzip.each_line do # @type [String] line
          |line|
          
          i += 1
          next if i - 1 == 0
          break if i == 10 #for testing purposes stop after 9 titles or wtv

          # @type progress [Float]
          progress = ((gzip.pos / total_size) * 100).round(2)
          
          # tconst	averageRating	numVotes
          # @type csv_line [Array<String>]
          csv_line = CSV.parse_line(line, { col_sep: "\t", quote_char: "\x00" })

          movie = Movie.find_by(imdb_id: csv_line[0])
          if movie != nil
            puts "[" + progress.to_s + "%] Updating ratings for movie: " + movie.imdb_id + "(" + movie.primaryTitle + ")"
            movie.update({
              average_rating: csv_line[1].to_f,
              num_votes: csv_line[2].to_i
            })
          end
        end

        gzip.close
      end
    end
  
    def update_people
      File.open(Rails.root + "download/name.basics.tsv.gz", "rb") do |file|
        gzip = Zlib::GzipReader.new(file, { encoding: "UTF-8" })
        total_size = gzip.to_io.size.to_f
        i = 0
        gzip.each_line do |line|
          i += 1
          next if i - 1 == 0
          break if i == 10 #for testing purposes stop after 9 titles or wtv

          line.sub! '\N', ''
          
          progress = ((gzip.pos / total_size) * 100).round(2)
          
          # nconst	primaryName	birthYear	deathYear	primaryProfession	knownForTitles
          # @type csv_line [Array<String>]
          csv_line = CSV.parse_line(line, { col_sep: "\t", quote_char: "\x00" })
          
          known_for_imdb_ids = csv_line[5].split(",")
          known_for_movies = Movie.where(imdb_id: known_for_imdb_ids)

          person = Person.find_by(imdb_id: csv_line[0])
          if person == nil
            puts "[" + progress.to_s + "%] Inserting person: " + csv_line[0] + "(" + csv_line[1] + ")"
            person = Person.new(
              {
                imdb_id: csv_line[0],
                name: csv_line[1],
                birthYear: csv_line[2],
                deathYear: csv_line[3],
                professions: csv_line[4],
                known_for_movies: known_for_movies
              }
            ).save
          else
            puts "[" + progress.to_s + "%] Updating person: " + csv_line[0] + "(" + csv_line[1] + ")"
            person.update({
              imdb_id: csv_line[0],
              name: csv_line[1],
              birthYear: csv_line[2],
              deathYear: csv_line[3],
              professions: csv_line[4],
              known_for_movies: known_for_movies
            })
          end
        end

        gzip.close
      end
    end
  
    def download_data
      aws_credentials = JSON.load(File.read(Rails.root + "config/aws.json"))

      # noinspection RubyArgCount
      s3 = Aws::S3::Client.new({
        region: 'us-east-1',
        credentials: Aws::Credentials.new(aws_credentials["AccessKeyId"], aws_credentials["SecretAccessKey"]),
        ssl_verify_peer: false
      })

      #use_accelerate_endpoint: true

      files_to_download = ["title.basics.tsv.gz", "title.crew.tsv.gz", "title.principals.tsv.gz", "title.ratings.tsv.gz", "name.basics.tsv.gz"]

      files_to_download.each do |file_name|
        resp = s3.get_object(
          response_target: Rails.root + "download/" + file_name,
          bucket: 'imdb-datasets',
          request_payer: "requester",
          key: "documents/v1/current/" + file_name
        )
      end
    end
    
    def ran_today?
      result = false
      today = Date::today.to_s
      last_run_date_file = __dir__ + "/update_imdb_last_run.log"
      if File.exists?(last_run_date_file)
        last_run_date = File.read(last_run_date_file).strip
      else
        last_run_date = today
      end
  
      file = File.open(last_run_date_file, "w")
      file.puts today
      file.close
  
      return result
    end
  
    def unzip_data
      files_to_decompress = ["title.basics.tsv.gz", "title.crew.tsv.gz", "title.principals.tsv.gz", "title.ratings.tsv.gz", "name.basics.tsv.gz"]
      files_to_decompress.each do |file_name|
        File.open(Rails.root + "download/" + file_name, "rb") do |file|
          output_file = File.open(Rails.root + "download/" + file_name.chomp(".gz"), "w")
          size_file = File.open(Rails.root + "download/size.txt", "a")
          lines_count = 0
          
          gzip = Zlib::GzipReader.new(file)
          gzip.each_line do |line|
            lines_count += 1
            output_file.write(line)
          end
          
          size_file.write(file_name.chomp(".gz") + "," + lines_count.to_s + "\n")
          
          size_file.close
          output_file.close
          gzip.close
        end
      end
    end
  
end