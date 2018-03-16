require "fileutils"
require "sqlite3"

module WeightKeeper
  class Setup
    class << self 
      @@app_path = File.join(ENV["DOCKER_VOLUME_PATH"], "/.weight_keeper")

      def create_application_directory
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