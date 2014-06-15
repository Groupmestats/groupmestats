require 'sqlite3'
require 'json'
require 'yaml'
require 'camping/session'
require 'set'
require 'erb'
require_relative '../bin/scraper.rb'

Camping.goes :GroupStats

module GroupStats
    set :secret, "this is my secret."
    include Camping::Session
end

def GroupStats.create
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

def checkGroups
    if @state.groups.include?(@input.group)
        return true
    else
        return false
    end
end

module GroupStats::Controllers

  class Index < R '/'
    def get 
        puts('AT INDEX @state.token nil ? ' +  String(@state.token == nil ));
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
        puts('authenticating');
        @state.token = @input.access_token
        @state.scraper = Scraper.new($database_path, @state.token)
        @state.user_id = @state.scraper.getUser
        puts('@state.token = ' + @state.token );

        @state.groups = Array.new
        @state.scraper.getGroups.each do |group|
            @state.groups.push(group['group_id'])
        end

        puts @state.groups
        return redirect Index
    end
  end

  class GroupList < R '/rest/groupList'
    def get()
        $database.results_as_hash = true
        result = $database.execute( "SELECT groups.group_id, groups.name, groups.image, groups.updated_at 
            FROM groups join user_groups on groups.group_id = user_groups.group_id 
            where user_groups.user_id = ?", 
            @state.user_id
        )
        $database.results_as_hash = false
        return result.to_json
    end
  end
  
  class RefreshGroupList < R '/rest/refreshGroupList'
    def get()
        groups = @state.scraper.getGroups
        groups.each do | group |
            @state.scraper.populateGroup(group['group_id'].to_i)
        end
        return groups.to_json
    end
  end
  
  class ScrapeGroup < R '/rest/scrapegroup'
    def get()
        @state.scraper.scrapeNewMessages(@input.groupid)
        return true
    end
  end

  class TopPost < R '/rest/toppost'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end

        result = $database.execute( "select count(likes.user_id) as count, messages.text, user_groups.Name, users.avatar_url from likes join messages on messages.message_id=likes.message_id left join user_groups on user_groups.user_id=messages.user_id left join users on users.user_id=messages.user_id WHERE messages.created_at > datetime('now', ?) AND messages.group_id=? AND user_groups.group_id=? and messages.image=='none' group by messages.message_id order by count desc limit 1",
        "-" + @input.days + " day",
        @input.groupid,
        @input.groupid)
        headers['Content-Type'] = "application/json"
        return result.to_json
    end
  end

  class TopImage < R '/rest/topimage'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end

        result = $database.execute("select count(likes.user_id) as count, messages.text, messages.image, user_groups.Name, users.avatar_url from likes join messages on messages.message_id=likes.message_id left join user_groups on user_groups.user_id=messages.user_id left join users on users.user_id=messages.user_id WHERE messages.created_at > datetime('now', ?) AND messages.group_id=? AND user_groups.group_id=? and messages.image!='none' group by messages.message_id order by count desc limit 1",
        "-" + @input.days + " day",
        @input.groupid,
        @input.groupid)
        headers['Content-Type'] = "application/json"
        return result.to_json
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

        #if GroupStats.checkGroups(@input.groupid)
        #    return nil
        #end 

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

  class TotalLikesGiven < R '/rest/totallikesgiven'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end

        result = $database.execute( "select user_groups.Name, count(likes.user_id) as count from likes left join user_groups on user_groups.user_id=likes.user_id left join messages on messages.message_id=likes.message_id where messages.created_at > datetime('now', ?) and messages.group_id=? and user_groups.group_id=? group by likes.user_id order by count desc",        
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
