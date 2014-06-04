require 'sqlite3'
require 'json'
require 'yaml'
require 'camping/session'
require 'set'
require 'erb'
require_relative '../bin/scraper.rb'

Camping.goes :GroupStats

def GroupStats.create
    set :secret, "this is my secret."
    include Camping::Session

    begin
        $config = YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), 'web.yaml') )
    rescue Errno::ENOENT => e
        abort('Configuration file not found.  Exiting...')
    end

    begin
        $database_path = $config['groupme']['database']
        $database = SQLite3::Database.new( $database_path )
    rescue Errno::ENOENT => e
        abort('Did not specify a valid database file')
    end
    
    if !$config['groupme']['client_id'].nil?
        $client_id = $config['groupme']['client_id']
    else    
        abort('Did not specify a GroupMe client_id')
    end
end

module GroupStats::Controllers

  class Index < R '/'
    def get 
        if(@state.token == nil)
            client_id = $client_id
            template_path = File.join(File.expand_path(File.dirname(__FILE__)), 'authenticate.html')
            return ERB.new(File.read(template_path)).result(binding)
        else
            File.open(File.join(File.expand_path(File.dirname(__FILE__)), 'index.html') )
        end
    end
  end
  
  class Authenticate < R '/authenticate'
    def get
       @state.token = @input.access_token
       $scraper = Scraper.new($database_path, @state.token)
       return redirect Index
    end
  end
  
  class GroupList < R '/rest/groupList'
    def get()
        $database.results_as_hash = true
        #result = $database.execute( "SELECT * FROM groups join user_groups on groups.group_id = user_groups.group_id where user_groups.user_id = ?", ####) #TODO: update to only get user's groups
        result = $database.execute( "SELECT * FROM groups");
        $database.results_as_hash = false
        return result.to_json
    end
  end
  
  class RefreshGroupList < R '/rest/refreshGroupList'
    def get()
        groups = $scraper.getGroups
        groups.each do | group |
            $scraper.populateGroup(group['group_id'].to_i)
        end
        return groups.to_json
    end
  end
  
  class ScrapeGroup < R '/rest/scrapegroup'
    def get()
        $scraper.scrapeNewMessages(@input.groupid)
        return true
    end
  end

  class WordCloud < R '/rest/wordcloud'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end
 
        result = $database.execute( "SELECT text FROM messages WHERE messages.created_at > datetime('now', ?) AND group_id=?",
        "-" + @input.days + " day",
        @input.groupid)
        headers['Content-Type'] = "application/json"
        return result.to_json
    end 
  end

  class TotalLikesReceived < R '/rest/totallikesreceived'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end

        result = $database.execute( "select user_groups.Name, count(likes.user_id) as count from user_groups left join likes on messages.message_id=likes.message_id left join messages on messages.user_id=user_groups.user_id where messages.created_at > datetime('now', ?) and messages.group_id=? and user_groups.group_id=? group by messages.user_id order by count desc",
        "-" + @input.days + " day",
        @input.groupid,
        @input.groupid)
        headers['Content-Type'] = "application/json"
        return result.to_json
    end
  end
      
  class PostsMost < R '/rest/postsmost'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end
        
        result = $database.execute( "SELECT user_groups.Name, count(messages.user_id) as count FROM user_groups left join messages on messages.user_id = user_groups.user_id WHERE messages.created_at > datetime('now', ?) AND messages.group_id=? AND user_groups.group_id=? group by messages.user_id order by count desc",
        "-" + @input.days + " day",
        @input.groupid,
        @input.groupid)
        headers['Content-Type'] = "application/json"
        return result.to_json
    end
  end
end

module GroupStats::Views
    def initalAuth
        p "Welcome to my blog"
    end
end
