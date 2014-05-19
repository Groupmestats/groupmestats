require 'sqlite3'
require 'json'
require 'yaml'
require 'pp'

Camping.goes :GroupStats
if !ARGV[1].nil?
    $config_file = ARGV[1]
else
    $config_file = 'web.yaml'
end

module GroupStats::Controllers
  class Index < R '/'
    def get
      begin 
        config = YAML.load_file($config_file)
      rescue
        abort('Configuration file not found.  Exiting...')
      end
      File.open(config['groupme']['index'])
    end
  end
  
  class PostsMost < R '/rest/postsmost'
    def get()
		if(@input.days == nil)
			@input.days = "9999999999"
		end
        begin
            config = YAML.load_file($config_file)
        rescue
            abort('Configuration file not found.  Exiting...')
        end
 
        begin
            database = SQLite3::Database.new( config['groupme']['database'] ) #name your db as db.sqlite3 and put it in the same folder as this file
        rescue
            abort('Did not specify a valid database file')
        end

		result = database.execute( "SELECT users.Name, count(messages.user_id) as count FROM users left join messages on messages.user_id = users.user_id where messages.created_at > datetime('now', ?) group by messages.user_id order by count desc",
		"-" + @input.days + " day")
		headers['Content-Type'] = "application/json"
		return result.to_json
    end
  end
end

module GroupStats::Views
  #not using
end
