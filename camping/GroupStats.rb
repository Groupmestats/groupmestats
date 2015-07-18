require 'rubygems' 
require 'bundler/setup'
require 'json'
require 'yaml'
require 'camping/session'
require 'set'
require 'erb'
require_relative '../bin/scraper.rb'
require 'logger'
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

    if !$config['groupme']['client_id'].nil?
        $client_id = $config['groupme']['client_id']
    else    
        abort('Did not specify a GroupMe client_id')
    end

    begin
	$logging_path = $config['camping-server']['log']
        $logger = Logger.new($logging_path)
    rescue
	abort('Log file not found.  Exiting...')
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
	    @state.scraper = Scraper.new(@state.token, $logging_path)
            #@state.user_id = @state.scraper.getUser
            File.open(File.join(File.expand_path(File.dirname(__FILE__)), 'index.html') )
        end
    end
  end
  
  class Authenticate < R '/authenticate'
    def get
        $logger = Logger.new($logging_path)
        @state.token = @input.access_token
        @state.scraper = Scraper.new(@state.token, $logging_path)
        @state.user_id = @state.scraper.getUser
        
        $logger.info "authenticating"
        $logger.info "@state.token = #{@state.token}"

        @state.groups = Array.new
        refreshGroupList()
        #updateStateGroupList(@state.scraper.getGroups)

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

  def scrapeAll()
      $logger.info "Scraping all groups for user #{@state.token}"
      groups = @state.scraper.getGroups

      groups.each do |group|
	  if !getGroups(group['group_id'])
              return 'nil'
          end
          
	  thr = Thread.new { @state.scraper.scrapeNewMessages(group['group_id']) }
      end
  end

  def refreshGroupList()
      $logger.info "Refreshing Grouplist for @state.token = #{@state.token}"
      #groups = @state.scraper.getGroups
      #groups.each do | group |
          #@state.scraper.populateGroup(group['group_id'].to_i)
      #end
      #updateStateGroupList(groups)
      #return groups.to_json
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

  class GroupFacts < R '/rest/groupfacts'
    def get ()
        group = @state.scraper.getGroup(@input.groupid)
        return group.to_json
    end
  end

  class GroupList < R '/rest/groupList'
    def get()
	groups = @state.scraper.getGroups
	return groups.to_json
    end
  end

  class FirstPostTime < R '/rest/firstpostime'
    def get()
	time = @state.scraper.getFirstPostTime(@input.groupid)
	return time.to_json
    end
  end

  class RefreshGroupList < R '/rest/refreshGroupList'
    def get()
        return refreshGroupList()
    end
  end

  class ScrapeAll < R '/rest/scrapeall'
    def get()
        return scrapeAll()
    end
  end

  class User < R '/rest/user'
  end
  
  class Group < R '/rest/group'
    def get()
        group = @state.scraper.getGroup(@input.groupid)
        return group.to_json
    end
  end
  
  class ScrapeGroup < R '/rest/scrapegroup'
    def get()
        if !getGroups(@input.groupid)
            return 'nil'
        end

        #@state.scraper.scrapeNewMessages(@input.groupid)
    end
  end
end

module GroupStats::Views
    def initalAuth
        p "Welcome to my blog"
    end
end
