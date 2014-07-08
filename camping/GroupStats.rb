require 'pp'
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
        refreshGroupList()
        updateStateGroupList(@state.scraper.getGroups)

        return redirect Index
    end
  end

  def updateStateGroupList(grouplist)
    @state.groups = Array.new
        grouplist.each do |group|
            @state.groups.push(group['group_id'].to_i)
        end
    end
  
  def getGroups(group_id)
      if @state.groups.include?(group_id.to_i)
          return true
      else
          return false
      end
  end

  def refreshGroupList()
      groups = @state.scraper.getGroups
      groups.each do | group |
          @state.scraper.populateGroup(group['group_id'].to_i)
      end
      updateStateGroupList(groups)
      return groups.to_json
  end

  def parseTimeZone(timezone)
  
      #Timezone parsing bullshit
      if(timezone == nil)
          timezone = '04:00'
      else
          if timezone.to_i < 0
              if timezone.to_i < 9
                  timezone = "0#{@input.timezone.to_i.abs}:00"
              else
                  timezone = "#{@input.timezone.to_i.abs}:00"
              end
          else
              if timezone.to_i < 9
                  timezone = "-0#{@input.timezone.to_i.abs}:00"
              else
                  timezone = "-#{@input.timezone.to_i.abs}:00"
              end
          end
      end

      return timezone
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
        return refreshGroupList()
    end
  end

  class UserGroup < R '/rest/usergroup'
    def get()
        if(@input.groupid == nil)
            return false
        end
        
        final_results = Array.new
        users = $database.execute("select user_groups.user_id from user_groups where user_groups.group_id=?",
            @input.groupid
        )
        
        users.each do | userid |
            result = Hash.new
            $database.results_as_hash = true
            result = $database.execute("SELECT * from users join user_groups using(user_id) where user_id = ? and group_id = ?",
                userid,
                @input.groupid
            )
            result = result[0]
     
            total_posts = $database.execute("SELECT  count(messages.user_id) as count FROM messages WHERE messages.user_id=? AND messages.group_id=?",
                userid,
                @input.groupid
            )[0][0]
            result.merge!(:total_posts => total_posts)
            
            total_likes_received = $database.execute("select count(likes.user_id) as count from likes left join messages on messages.message_id=likes.message_id where messages.user_id=? AND messages.group_id=?",
                userid,
                @input.groupid
            )[0][0]
            result.merge!(:total_likes_received => total_likes_received)

            if (total_likes_received.to_f == 0 || total_posts.to_f == 0)
                result.merge!(:likes_to_posts_ratio => 0)
            else
                result.merge!(:likes_to_posts_ratio => total_likes_received.to_f/total_posts.to_f)
            end

            top_post = $database.execute("select count(likes.user_id) as count, messages.text from likes join messages on messages.message_id=likes.message_id WHERE messages.user_id=? and messages.group_id=? and messages.image=='none' group by messages.message_id order by count desc limit 1",
                userid,
                @input.groupid
            )
            if !top_post.empty?
                result.merge!(:top_post_likes => top_post[0][0])
                result.merge!(:top_post => top_post[0][1])
            end

            final_results.push(result)
        end
        $database.results_as_hash = false
        
        return final_results.to_json
    end
  end

  class User < R '/rest/user'
    def get()
        ifGroup = true
        if(@input.userid == nil)
            @input.userid = @state.user_id
        end
        if(@input.groupid == nil)
            ifGroup = false
        end
        
        result = Hash.new
        $database.results_as_hash = true
        if ifGroup 
            result = $database.execute("SELECT * from users join user_groups using(user_id) where user_id = ? and group_id = ?",
                @input.userid,
                @input.groupid
            )
            result = result[0]
        else
            result = @state.scraper.getUserInfo
            result = result['response']
        end
       
        if ifGroup
            total_posts = $database.execute("SELECT  count(messages.user_id) as count FROM messages WHERE messages.user_id=? AND messages.group_id=?",
                @input.userid,
                @input.groupid
            )[0][0]
            result.merge!(:total_posts => total_posts)
        else 
            total_posts = $database.execute("SELECT  count(messages.user_id) as count FROM messages WHERE messages.user_id=?",
                @input.userid
            )[0][0]
            result.merge!(:total_posts => total_posts)
        end
           
        if ifGroup 
            total_likes_received = $database.execute("select count(likes.user_id) as count from likes left join messages on messages.message_id=likes.message_id where messages.user_id=? AND messages.group_id=?",
                @input.userid,
                @input.groupid
            )[0][0]
            result.merge!(:total_likes_received => total_likes_received)
            
             if (total_likes_received.to_f == 0 || total_posts.to_f == 0)
                result.merge!(:likes_to_posts_ratio => 0)
             else
                result.merge!(:likes_to_posts_ratio => total_likes_received.to_f/total_posts.to_f)
             end
        else
            total_likes_received = $database.execute("select count(likes.user_id) as count from likes left join messages on messages.message_id=likes.message_id where messages.user_id=?",
                @input.userid
            )[0][0]
            result.merge!(:total_likes_received => total_likes_received)

            if (total_likes_received.to_f == 0 || total_posts.to_f == 0)
                result.merge!(:likes_to_posts_ratio => 0)
            else
                result.merge!(:likes_to_posts_ratio => total_likes_received.to_f/total_posts.to_f)
            end
        end

        if ifGroup
            top_post = $database.execute("select count(likes.user_id) as count, messages.text from likes join messages on messages.message_id=likes.message_id WHERE messages.user_id=? and messages.group_id=? and messages.image=='none' group by messages.message_id order by count desc limit 1",
                @input.userid,
                @input.groupid
            )
            if !top_post.empty?
                result.merge!(:top_post_likes => top_post[0][0])
                result.merge!(:top_post => top_post[0][1])
            end
        else
            top_post = $database.execute("select count(likes.user_id) as count, messages.text from likes join messages on messages.message_id=likes.message_id WHERE messages.user_id=? and messages.image=='none' group by messages.message_id order by count desc limit 1",
                @input.userid,
            )
            result.merge!(:top_post_likes => top_post[0][0])
            result.merge!(:top_post => top_post[0][1])
        end
        $database.results_as_hash = false
        
        return result.to_json
    end
  end
  
  class Group < R '/rest/group'
    def get()
        if !getGroups(@input.groupid)
            return 'nil'
        end
 
        $database.results_as_hash = true
        result = $database.execute( "SELECT groups.group_id, groups.name, groups.image, groups.updated_at 
            FROM groups join user_groups on groups.group_id = user_groups.group_id 
            where user_groups.user_id = ? and groups.group_id = ?", 
            @state.user_id,
            @input.groupid
        )
        if(result.length == 0)
            @status = 400
            return "";
        end
        
        users = $database.execute( "select user_id, user_groups.name from users
            join user_groups using(user_id)
            join groups using (group_id)
            where groups.group_id = ?", 
            @input.groupid
            )
        result[0].merge!(:users => users);
        $database.results_as_hash = false
        return result[0].to_json
    end
  end
  
  class ScrapeGroup < R '/rest/scrapegroup'
    def get()
        if !getGroups(@input.groupid)
            return 'nil'
        end

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
        if(@input.num == nil)
            @input.num = 1
        end

        if !getGroups(@input.groupid)
            return 'nil'
        end

        $database.results_as_hash = true
        result = $database.execute( "select count(likes.user_id) as count, messages.text, user_groups.Name, users.avatar_url from likes join messages on messages.message_id=likes.message_id left join user_groups on user_groups.user_id=messages.user_id left join users on users.user_id=messages.user_id WHERE messages.created_at > datetime('now', ?) AND messages.group_id=? AND user_groups.group_id=? and messages.image=='none' group by messages.message_id order by count desc limit ?",
        "-" + @input.days + " day",
        @input.groupid,
        @input.groupid,
        @input.num)
        headers['Content-Type'] = "application/json"
        $database.results_as_hash = false
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

        if !getGroups(@input.groupid)
            return 'nil'
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

        if !getGroups(@input.groupid)
            return 'nil'
        end

        result = $database.execute( "SELECT text FROM messages WHERE messages.created_at > datetime('now', ?) AND group_id=?",
        "-" + @input.days + " day",
        @input.groupid)

        stop_words = Array.new
        f = File.open(File.join(File.expand_path(File.dirname(__FILE__)), 'commonlyusedwords.txt') )
        f.each_line do | line |
            stop_words.push line.split("\n")
        end

        counts = Hash.new 0
        #counts = Array.new 0
        result.each do | text |
            stop_words.each do | stop_word |
                if text[0].to_s.downcase.include? stop_word[0].downcase
                    text[0].gsub!(/(^|\s|\W)#{stop_word[0].to_s}(\'s|\s|\W|$)/i, ' ')
                end
            end
            text[0].split.each do | word |
                word = word.downcase
                word.delete!("^a-zA-Z0-9")
                counts[word] += 1
                #if counts.find {|w| w[:text] == word}
                    #counts.find {|w| w[:text] == word}[:size] += 1
                #else
                    #counts.push({:text => word, :size => 1})
                #end
            end

        end

        final = Array.new 0
        counts.each do | x |
            final.push(x.to_a)
        end
        headers['Content-Type'] = "application/json"
        return result.to_json
        #return counts.to_a
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

        if !getGroups(@input.groupid)
            return 'nil'
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

        if !getGroups(@input.groupid)
            return 'nil'
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

        if !getGroups(@input.groupid)
            return 'nil'
        end
        
        result = $database.execute( "SELECT user_groups.Name, count(messages.user_id) as count FROM user_groups left join messages on messages.user_id = user_groups.user_id WHERE messages.created_at > datetime('now', ?) AND messages.group_id=? AND user_groups.group_id=? group by messages.user_id order by count desc",
        "-" + @input.days + " day",
        @input.groupid,
        @input.groupid)
        headers['Content-Type'] = "application/json"
        return result.to_json
    end
  end

  class DailyPostFrequency < R '/rest/dailypostfrequency'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end

        if !getGroups(@input.groupid)
            return 'nil'
        end

        result = $database.execute( "select strftime('%H', messages.created_at, ? ) as time, count(strftime('%H', messages.created_at, '-04:00')) from messages where messages.created_at > datetime('now', ?) AND messages.group_id=? group by strftime('%H', messages.created_at) order by time asc",
        parseTimeZone(@input.timezone),
        "-" + @input.days + " day",
        @input.groupid)
        headers['Content-Type'] = "application/json"
       
        i = 0
        while (i < 24)
            check = true
            result.each do |count|
                if count[0].to_i == i
                    count[0] = count[0].to_i
                    check = false
                end
            end

            if check == true
                result.push([i,0])
            end
            i += 1
        end

        result.sort! {|a,b| a[0] <=> b[0]}
        return result.to_json
    end
  end

  class WeeklyPostFrequency < R '/rest/weeklypostfrequency'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end

        if !getGroups(@input.groupid)
            return 'nil'
        end

        result = $database.execute( "select strftime('%w', messages.created_at) as time, count(strftime('%w', messages.created_at)) from messages where messages.created_at > datetime('now', ?) AND messages.group_id=? group by strftime('%w', messages.created_at) order by time asc",
        "-" + @input.days + " day",
        @input.groupid)
        headers['Content-Type'] = "application/json"

        i = 0
        while (i < 7)
            check = true
            result.each do |count|
                if count[0].to_i == i
                    count[0] = count[0].to_i
                    check = false
                end
            end

            if check == true
                result.push([i,0])
            end
            i += 1
        end

        result.sort! {|a,b| a[0] <=> b[0]}
        result.each do |count|
            date = Date.new(2014,6,15 + count[0])
            count[0] = date.strftime("%A")
        end
        return result.to_json
    end
  end
  
  class Heatdata < R '/rest/heatdata'
    def get()
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end
        
        $database.results_as_hash = false
        result = $database.execute( "select strftime('%w',messages.created_at) as date,strftime('%H',messages.created_at, ?) as hour, count(message_id) from messages
                join groups using(group_id)
                where group_id = ?
                group by strftime('%w',messages.created_at), strftime('%H',messages.created_at)
                order by strftime('%w',messages.created_at) asc, strftime('%H',messages.created_at)",
            parseTimeZone(@input.timezone), 
            @input.groupid)
        #todo: enforce user id
        result.each do |a|
            a[1] = a[1].to_i
            a[0] = a[0].to_i
        end
        $database.results_as_hash = false
        return result.to_json
    end
  end

  class GroupJoinRate < R '/rest/groupjoinrate'
    def get()
        if(@input.days == nil)
            @input.days = "9999999999"
        end
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end
        if(@input.num == nil)
            @input.num = 1
        end

        if !getGroups(@input.groupid)
            return 'nil'
        end

        #$database.results_as_hash = true
        temp_result = $database.execute( "SELECT strftime('%s', MIN(m.created_at)) First_Post
            FROM messages m       
                 INNER JOIN user_groups ug
                       ON m.group_id = ug.group_id
                          AND m.user_id = ug.user_id           
                   INNER JOIN groups g        
                         ON ug.[group_id] = g.[group_id]   
            WHERE m.group_id=?
            GROUP BY g.[name], ug.name
            ORDER BY First_Post",
        @input.groupid)

        i = 0
        result = Array.new 
        temp_result.each do | element |
            result.push([1000*element[0].to_i, i])
            i += 1
        end
        headers['Content-Type'] = "application/json"
        $database.results_as_hash = false
        return result.to_json
    end
  end
  
  class NgramData < R '/rest/ngramdata'
    def get()
        if(@input.groupid == nil)
            @status = 400
            return 'need group id'
        end
        if(@input.search == nil)
            @status = 400
            return 'need search terms'
        end
        terms = @input.search.split(",")
        toReturn = { :series => []};
        $database.results_as_hash = false
        
        dateRange = $database.execute("select strftime('%s', created_at), strftime('%s', updated_at) from groups where group_id = ?",
            @input.groupid);
        toReturn["startDate"] = dateRange[0][0].to_i * 1000
        toReturn["endDate"] = dateRange[0][1].to_i * 1000
        terms.each do |term|
            chartdata = [];
            $database.results_as_hash = true
            #alternate query that doesn't return 0 weeks, but is much faster
            #result = $database.execute( "select strftime('%s', m.created_at) as time, count(message_id) as messages,
            #   (select count(message_id) from messages
            #        where group_id = ?
            #        and strftime('%W', messages.created_at) = strftime('%W', m.created_at)
            #        and strftime('%Y', messages.created_at) = strftime('%Y', m.created_at)
            #        group by strftime('%W', messages.created_at), strftime('%Y', messages.created_at)
            #        order by messages.created_at asc
            #   ) as totalmessages
            # from messages as m
            #    where group_id = ?
            #    and text like ?
            #    group by strftime('%W', m.created_at), strftime('%Y', m.created_at)
            #    order by m.created_at asc",
            #    @input.groupid,
            #    @input.groupid,
            #    '%'+term+'%')
                
            result = $database.execute( "select strftime('%s', m.created_at) as time, count(message_id) as totalmessages,
                   (select count(message_id) from messages
                        where group_id = ?
                        and strftime('%W', messages.created_at) = strftime('%W', m.created_at)
                        and strftime('%Y', messages.created_at) = strftime('%Y', m.created_at)
                        and text like ?
                   ) as messages
                 from messages as m
                where group_id = ?
                group by strftime('%W', m.created_at), strftime('%Y', m.created_at)
                order by m.created_at asc",
                @input.groupid,
                '%'+term+'%',
                @input.groupid)   
                
            result.each do |a|
                if(a["messages"] == nil)
                    chartdata.push([a["time"].to_i * 1000, 0])
                else
                    chartdata.push([
                            a["time"].to_i * 1000, #highcharts likes dates in milliseconds
                            ((a["messages"].to_f / a["totalmessages"])*100).round(3)
                        ]);
                end
            end
            currseries = {:data => chartdata, :name => term};
            toReturn[:series].push(currseries);
        end
        #todo: enforce user id
        
        $database.results_as_hash = false
        
        return toReturn.to_json
    end
  end
end

module GroupStats::Views
    def initalAuth
        p "Welcome to my blog"
    end
end
