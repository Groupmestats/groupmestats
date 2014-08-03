#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'time'
require 'sqlite3'
require 'logger'
require 'pp'

require_relative 'groupme'

#Scraper class.  This is initialized with a path to the sqlite database and a groupme oauth token
class Scraper
    #$logger = Logger.new('/var/log/camping-server/groupstats.log')
    $time = Time.now.to_i
    $gm = Groupme.new($logger)

    #Constructor that takes a path to the sqlite database and a groupme oauth token
    def initialize(database, token, logger)
        @database = database
        @token = token

        pp "TESTING: #{logger}"
        @logger = Logger.new(logger)
 
        begin
            database = SQLite3::Database.new( @database )
        rescue
            @logger.error "Invalid database file"
            abort('Invalid database file')
        end

        @logger.info "Database does not exist.  Creating database"

        if database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='user_groups';").empty?
            database.execute('CREATE TABLE user_groups(user_id INT, group_id INT, name TEXT, FOREIGN KEY(user_id) REFERENCES users(user_id), FOREIGN KEY(group_id) REFERENCES groups(group_id));')
        end

        if database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='groups';").empty?
            database.execute('CREATE TABLE groups(group_id INT PRIMARY KEY, name TEXT, date_scraped DATETIME, image TEXT, creator TEXT, created_at DATETIME, updated_at DATETIME);')
        end

        if database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users';").empty?
            database.execute('CREATE TABLE users(user_id INT PRIMARY KEY, avatar_url TEXT);')
        end

        if database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='messages';").empty?
            database.execute('CREATE TABLE messages(message_id INT PRIMARY KEY, created_at DATETIME, user_id INT, name TEXT, group_id INT, avatar_url TEXT, text TEXT, image TEXT, FOREIGN KEY(user_id) REFERENCES users(user_id), FOREIGN KEY(group_id) REFERENCES groups(group_id));')
        end

        if database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='likes';").empty?
            database.execute('CREATE TABLE likes(message_id INT, user_id INT, FOREIGN KEY(message_id) REFERENCES messages(message_id), FOREIGN KEY(user_id) REFERENCES users(user_id))' )
        end        
    end

    #Returns the user_id
    def getUser
        return $gm.get("/users/me/", @token)['response']['id']
    end

    def getUserInfo
        return $gm.get("/users/me/", @token)
    end

    #Returns an array of hashes, containing the name and group_id of each group the user belongs to
    def getGroups
        groups = $gm.get("/groups/", @token)
        group_ids = Array.new

        groups['response'].each do |group|
            group_ids.push({
                'name' => group['name'],
                'group_id' => group['id'],
                'image' => group['image_url']})
        end

        return group_ids
    end

    #Returns the last time the group was updated
    def getLastUpdate(group_id)
        database = SQLite3::Database.new( @database )
        group = $gm.get("/groups/#{group_id}/", @token)['response']

        return group['updated_at']
    end

    #For a given group, it adds the group and users, if new.  Otherwise, it just updates them
    def populateGroup(group_id)
        database = SQLite3::Database.new( @database )
        group = $gm.get("/groups/#{group_id}/", @token)['response']

        if group['image_url'].nil?
            group['image_url'] = 'img/groupme.png'
        elsif group['image_url'].empty?
            group['image_url'] = 'img/groupme.png'
        else
            group['image_url'] = "#{group['image_url']}.avatar"
        end

        group_info = Hash.new
        user_info = Hash.new
        user_group_info = Hash.new
       
        #Adds new group if they don't exist, and updates the group if they do 
        if database.execute( "SELECT * FROM groups WHERE group_id='#{group['group_id']}'").empty? 
            group_info[group['group_id']] = [group['created_at'], group['name'], group['image_url'], group['creator_user_id'], false ]
            @logger.info "Adding new group #{group['name']} to the database"
        else
            group_info[group['group_id']] = [group['created_at'], group['name'], group['image_url'], group['creator_user_id'], true ]
        end
       
        #Adds any new members to the group, and updates any members who have made changes 
        group['members'].each do | member |

            if member['image_url'].nil?
                member['image_url'] = 'img/groupme.png'
            elsif member['image_url'].empty?
                member['image_url'] = 'img/groupme.png'
            else
                member['image_url'] = "#{member['image_url']}.avatar"
            end

            if database.execute( "SELECT * FROM users WHERE user_id='#{member['user_id']}'").empty?
                user_info[member['user_id'] ] = [member['image_url'], false ]
            else
                user_info[member['user_id'] ] = [member['image_url'], true ]
            end
            if database.execute( "SELECT * FROM user_groups WHERE user_id='#{member['user_id']}' AND group_id='#{group['group_id']}'").empty?
                user_group_info[member['user_id']] = [group['group_id'], member['nickname'], false]
            else
                  user_group_info[member['user_id']] = [group['group_id'], member['nickname'], true]
            end
        end

        database.transaction
        group_info.each do | key, value |
            if value[4]
                database.execute( "UPDATE groups SET name=?, image=?, creator=?, created_at=datetime('#{value[0]}','unixepoch') WHERE group_id='#{key}'",
                    key,
                    value[1],
                    value[2],
                    value[3] ) 
            else    
                database.execute( "INSERT INTO groups(group_id, name, image, creator, created_at) VALUES (?, ?, ?, ?, datetime('#{value[0]}','unixepoch'))",
                    key,
                    value[1],
                    value[2],
                    value[3] )
            end
        end
        
        user_info.each do | key, value |
            if value[1]
                database.execute( "UPDATE users SET avatar_url=? WHERE user_id='#{key}'",
                    value[0] )
            else
                database.execute( "INSERT INTO users(user_id, avatar_url) VALUES (?, ?)",
                    key,
                    value[0] )
            end 
        end

        user_group_info.each do | key, value |
            if value[2]
                database.execute( "UPDATE user_groups SET name=? WHERE user_id='#{key}' AND group_id='#{value[0]}'",
                    value[1] )
            else
                database.execute( "INSERT INTO user_groups(user_id, group_id, name) VALUES (?, ?, ?)",
                    key,
                    value[0],
                    value[1] )
            end
        end
        database.commit
    end

    def scrapeNewMessages(group_id)
        database = SQLite3::Database.new( @database )

        if database.execute( "SELECT * FROM groups WHERE group_id='#{group_id}'").empty?
            populateGroup(group_id)
            scrapeMessages(group_id)
        else
            update_time = database.execute( "SELECT strftime('%s', updated_at) FROM groups WHERE group_id='#{group_id}'" )        
            scrapeMessages(Time.now.to_i - update_time[0][0].to_i, group_id)
        end
        
        group = $gm.get("groups/#{group_id}/", @token)['response']
        @logger.info "Scraped messages from #{group['name']}"

        database = SQLite3::Database.new( @database )
        database.execute("UPDATE groups SET updated_at=datetime('#{group['updated_at']}','unixepoch') WHERE group_id='#{group['group_id']}'")
    end

    #This will pull all messages for a given period of time and group, and store it in the messages table.  Takes in a time, in epoch seconds.  To search for all messages, entire the current epoch time.
    def scrapeMessages(searchTime = Time.now.to_i, group_id)
        database = SQLite3::Database.new( @database ) 

        id = 0
        t = Time.now.to_i
       
        scraped_messages = Hash.new        
        scraped_likes = Array.new

        t1 = Time.new

        while (Time.now.to_i - t.to_i) < (searchTime + 604800) do

            if id == 0
                messages = $gm.get("groups/#{group_id}/messages", @token, "limit=100")['response']
            else
                messages = $gm.get("groups/#{group_id}/messages", @token, "limit=100&before_id=#{id}")['response']
            end

            if messages.nil?
                break
                return false
            end

            messages['messages'].each do | message |
                t = Time.at(message['created_at'])
                if ((Time.now.to_i - t.to_i) < searchTime)
                   if database.execute( "SELECT * FROM messages WHERE message_id='#{message['id']}'").empty?
                       image = "none"
                       liked_users = ""
                       num_likes = 0
                       if !message['attachments'].empty?
                           if message['attachments'][0]['type'] == "image"
                              image = message['attachments'][0]['url'] 
                           end
                       end
                       if !message['favorited_by'].nil?
                           if message['favorited_by'].length != 0
                               message['favorited_by'].each do | user |
                                   scraped_likes.push([message['id'], user])
                               end
                           end 
                       end
                       if !message['text'].nil?
                           scraped_messages[ message['id'] ] = [ message['created_at'], message['user_id'], message['name'], message['group_id'], message['avatar_url'], message['text'], image ]
                       else
                           scraped_messages[ message['id'] ] = [ message['created_at'], message['user_id'], message['name'], message['group_id'], message['avatar_url'], 'none', image ]
                       end
                   end
                end    
                #For likes, we want to scan all posts a week back from the search time
                if ((Time.now.to_i - t.to_i) < (searchTime.to_i + 604800) )
                   message['favorited_by'].each do | likedMembers |
                       if (database.execute("SELECT count(user_id) FROM likes WHERE message_id=#{message['id']} AND user_id=#{likedMembers}")[0][0] == 0 && database.execute("SELECT updated_at FROM groups WHERE group_id=#{message['group_id']}").empty?)
                           scraped_likes.push([message['id'], likedMembers])
                       end 
                   end
                end
            end

            t = messages['messages'].last['created_at']
            id = messages['messages'].last['id'] 
        end

        database.transaction
        scraped_messages.each do | key, value |
            database.execute(  "INSERT INTO messages(message_id, created_at, user_id, name, group_id, avatar_url, text, image) VALUES (?, datetime('#{value[0]}', 'unixepoch'), ?, ?, ?, ?, ?, ?)",
                key,
                value[1],
                value[2],
                value[3],
                value[4],
                value[5],
                value[6] )
        end  
        scraped_likes.each do | likes |
            database.execute("INSERT INTO likes(message_id, user_id) VALUES (?, ?)",
                likes[0],
                likes[1] )
        end 
        database.commit
        
        t2 = Time.new
        @logger.info "Scrape time for group id #{group_id} was: #{(t2-t1).to_s} seconds"
    end

    private :scrapeMessages
end
