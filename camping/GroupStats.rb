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

pp $config_file
module GroupStats::Controllers
  class Index < R '/'
    def get
      File.open("index.html")
    end
  end
  
  class PostsMost < R '/rest/postsmost'
    def get()
		if(@input.content == nil)
			@input.content = ""
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

		result = database.execute( "SELECT users.Name, count(user_id) as count FROM messages join users on messages.user_id = users.Uid group by user_id order by count desc")
		headers['Content-Type'] = "application/json"
		return result.to_json
    end
  end
end

module GroupStats::Views
  #not using
end
