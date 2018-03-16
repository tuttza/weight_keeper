require "sqlite3"
require "thor"
require "weight_keeper/models/journal_entry"

 module WeightKeeper
  class CLI < Thor
    def initialize(*args)
      super
      @sqlite_db_file = File.join(ENV["DOCKER_VOLUME_PATH"], "/.weight_keeper/db/weight_keeper.sqlite3")
      @db_connection = SQLite3::Database.new(@sqlite_db_file)
    end

    desc "add WEIGHT", "Add your current weight to WeightKeeper"
    def add(weight)
      entry = JournalEntry.new(@db_connection)
      entry.weight = weight.to_f
      entry.insert { entry.weight_achievement }
      @db_connection.close
    end

    desc "display_progress", "Display the amount of weight you have lost to date."
    def display_progress
      journal = JournalEntry.new(@db_connection)
      journal.total_weight_loss
      @db_connection.close
    end
  end
 end

