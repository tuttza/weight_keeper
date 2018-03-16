require "securerandom"
require "date"

module WeightKeeper
  class JournalEntry
  	attr_accessor :weight
    attr_reader :id, :date

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

    def total_weight_loss
      starting_weight_query = @db_connection.execute("SELECT weight FROM journal_entries WHERE rowid = 1;")
      starting_weight_result = nil
      starting_weight_query.each { |value| starting_weight_result = value.join.to_f }
      
      current_weight_query = @db_connection.execute("SELECT weight FROM journal_entries ORDER BY rowid DESC LIMIT 1;")
      current_weight_result = nil
      current_weight_query.each { |value| current_weight_result = value.join.to_f }

      diff = weight_diff(starting_weight_result, current_weight_result)

      unless diff.nil?
        puts "You have lost #{diff}lbs."
      else
        puts "You don't have any progress yet!"
      end
    end

  	def weight_achievement
  		previous_weight = get_previous_weight
  		current_weight = get_last_inserted_weight
  		diff = weight_diff(previous_weight, current_weight)
  		
      unless diff.nil?
  		  if previous_weight > current_weight
  			 puts "Congrats! You lost #{diff}lbs"
  		  end
      else
        puts "No weight has been entered yet."
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
  			puts "An error has occured:"
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
  			puts "An error has occured:"
  			puts e
  		ensure
    		previous_weight_statement.close if previous_weight_statement
  		end
  		previous_weight
  	end

  	def weight_diff(previous_weight, current_weight)
      unless previous_weight.nil? || current_weight.nil?
  		  (previous_weight - current_weight).round(2)
      end
  	end
  end
end