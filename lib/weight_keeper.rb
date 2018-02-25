require "weight_keeper/version"
require "date"
require "fileutils"
require "sqlite3"
require "securerandom"
require "thor"

module WeightKeeper
  # Your code goes here...

  class CLI < Thor
  	
  	desc "add WEIGHT", "add your current weight to WeightKeeper"
  	def add(weight)
  		sqlite_db_file = File.join(ENV["HOME"], "/.weight_keeper/db/weight_keeper.sqlite3")
  		db_connection = SQLite3::Database.new(sqlite_db_file)
  		entry = JournalEntry.new(db_connection)
  		entry.weight = weight.to_f
  		entry.insert { entry.weight_achievement }
  		db_connection.close
  	end
  end

  class JournalEntry
  	attr_accessor :id, :weight, :date

  	def initialize(db_connection = nil)
  		@id = SecureRandom.uuid
  		@weight = 0.0
  		@date = Date.today.iso8601
  		@db_connection = db_connection
  	end

  	def insert
  		begin
  			insert_statement = @db_connection.prepare("INSERT INTO journal_entries (id, weight, added_at) VALUES (?, ?, ?);")
  			insert_statement.bind_params(@id, @weight, @date)
  			insert_statement.execute
  			
  			puts "Succesfully recorded new weight!"
  		rescue SQLite3::Exception => e 
  			puts "An error occured trying to save data:"
  			puts e
  		ensure
    		insert_statement.close if insert_statement
  		end

  		yield
  	end

  	def weight_achievement
  		previous_weight = get_previous_weight
  		current_weight = get_last_inserted_weight
  		diff = weight_diff(previous_weight, current_weight)
  		
  		if previous_weight > current_weight
  			puts "Congrats! You lost #{diff}lbs"
  		end
  	end

  	private 

  	def get_last_inserted_weight
  		last_input_weight = nil
  		 begin
	  		last_input_weight_statement = @db_connection.prepare("SELECT weight FROM journal_entries WHERE rowid = ?;")
	  		last_input_weight_statement.bind_params(@db_connection.last_insert_row_id)
	  		result_set = last_input_weight_statement.execute
	  		result_set.each do |value|
	  			last_input_weight = value.join.to_f
	  		end
  		rescue SQLite3::Exception => e
  			puts "An error has occured"
  			puts e
  		ensure
	  		last_input_weight_statement.close if last_input_weight_statement
  		end
  		last_input_weight
  	end

  	def get_previous_weight
  		previous_weight = nil
  		begin
  			previous_weight_row_id = @db_connection.last_insert_row_id - 1
  			previous_weight_statement = @db_connection.prepare("SELECT weight FROM journal_entries WHERE rowid = ?;")
  			previous_weight_statement.bind_params(previous_weight_row_id)
  			result_set = previous_weight_statement.execute
  			result_set.each do |value|
  				previous_weight = value.join.to_f
  			end
  		rescue SQLite3::Exception => e
  			puts "An error has occured"
  			puts e
  		ensure
	  		previous_weight_statement.close if previous_weight_statement
  		end
  		previous_weight
  	end

  	def weight_diff(previous_weight, current_weight)
  		(previous_weight - current_weight).round(2)
  	end
  end

  class Setup
  	class << self 

  		def create_application_directory
  			@@app_path = File.join(ENV["HOME"], "/.weight_keeper")
  			FileUtils.mkdir_p(@@app_path) unless Dir.exist?(@@app_path)
  		end

  		def init_db
  			db_dir = File.join(@@app_path, "db")
  			FileUtils.mkdir_p(db_dir) unless Dir.exist?(db_dir)

  			db_file = File.join(db_dir, "weight_keeper.sqlite3")
  			FileUtils.touch(db_file) unless File.exist?(db_file)

  			db = SQLite3::Database.new(db_file)

  			journal_entries_create_statement = 
  				<<-SQL
					  CREATE TABLE IF NOT EXISTS journal_entries (
					    id TEXT PRIMARY KEY,
					    weight REAL NOT NULL,
					    added_at TEXT NOT NULL
					  );
					SQL

				db.execute(journal_entries_create_statement)
  		end

  		def run
  			create_application_directory
  			init_db
  		end
  	end

  end
end
