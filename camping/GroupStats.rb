require 'sqlite3'
require 'json'

Camping.goes :GroupStats

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
		database = SQLite3::Database.new( 'db.sqlite3' ) #name your db as db.sqlite3 and put it in the same folder as this file
		result = database.execute( "SELECT users.Name, count(user_id) as count FROM messages join users on messages.user_id = users.Uid group by user_id order by count desc")
		headers['Content-Type'] = "application/json"
		return result.to_json
    end
  end
end

module GroupStats::Views
  #not using
end