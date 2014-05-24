#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'time'
require 'sqlite3'
require_relative 'groupme'

#Scraper class.  This is initialized with a path to the sqlite database and a groupme oauth token
class Scraper
    $time = Time.now.to_i

    #Constructor that takes a path to the sqlite database and a groupme oauth token
    def initialize(database, token)
        @database = database
        @token = token

        begin
            database = SQLite3::Database.new( database_path )
        rescue
            abort('Invalid database file')
        end

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
            database.execute('CREATE TABLE messages(message_id INT PRIMARY KEY, created_at DATETIME, user_id INT, group_id INT, avatar_url TEXT, text TEXT, image TEXT, FOREIGN KEY(user_id) REFERENCES users(user_id), FOREIGN KEY(group_id) REFERENCES groups(group_id));')
        end

        if database.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='likes';").empty?
            database.execute('CREATE TABLE likes(message_id INT, user_id INT, FOREIGN KEY(message_id) REFERENCES messages(message_id), FOREIGN KEY(user_id) REFERENCES users(user_id))' )
        end        
    end

    #Returns the user_id
    def getUser
        gm = Groupme.new
        return gm.get("/users/me/", @token)['response']['id']
    end

    #Returns an array of hashes, containing the name and group_id of each group the user belongs to
    def getGroups
        gm = Groupme.new
        groups = gm.get("/groups/", @token)
        group_ids = Array.new

        groups['response'].each do |group|
            group_ids.push({
                :name => group['name'],
                :group_id => group['id']})
        end

        return group_ids
    end

    #Returns the last time the group was updated
    def getLastUpdate(group_id)
        gm = Groupme.new
        database = SQLite3::Database.new( @database )
        group = gm.get("/groups/#{group_id}/", @token)['response']

        return group['updated_at']
    end

    #For a given group, it adds the group and users, if new.  Otherwise, it just updates them
    def populateGroup(group_id)
        gm = Groupme.new
        database = SQLite3::Database.new( @database )
        group = gm.get("/groups/#{group_id}/", @token)['response']
      
        #Adds new group if they don't exist, and updates the group if they do 
        if database.execute( "SELECT * FROM groups WHERE group_id='#{group['group_id']}'").empty? 
            database.execute( "INSERT INTO groups(group_id, name, image, creator, created_at, updated_at) VALUES (?, ?, ?, ?, datetime('#{group['created_at']}','unixepoch'), datetime('#{group['updated_at']}','unixepoch'))",
                group['group_id'],
                group['name'],
                group['image_url'],
                group['creator_user_id'] )
        else
            database.execute( "UPDATE groups SET name=?, image=?, creator=?, created_at=datetime('#{group['created_at']}','unixepoch'), updated_at=datetime('#{group['updated_at']}','unixepoch') WHERE group_id='#{group['group_id']}'",
                group['name'],
                group['image_url'],
                group['creator_user_id'] )
        end
       
        #Adds any new members to the group, and updates any members who have made changes 
        group['members'].each do | member |
            if database.execute( "SELECT * FROM users WHERE user_id='#{member['user_id']}'").empty?
                database.execute( "INSERT INTO users(user_id, avatar_url) VALUES (?, ?)", 
                    member['user_id'],
                    member['image_url'] )
            else
                database.execute( "UPDATE users SET avatar_url=? WHERE user_id='#{member['user_id']}'",
                    member['image_url'] )
            end
            if database.execute( "SELECT * FROM user_groups WHERE user_id='#{member['user_id']}' AND group_id='#{group['group_id']}'").empty?
                database.execute( "INSERT INTO user_groups(user_id, group_id, name) VALUES (?, ?, ?)",
                    member['user_id'],
                    group['group_id'],
                    member['nickname'] )
            else
                database.execute( "UPDATE user_groups SET name=? WHERE user_id='#{member['user_id']}' AND group_id='#{group['group_id']}'",
                    member['nickname'] )
            end
        end
    end

    def scrapeNewMessages(group_id)
        gm = Groupme.new
        database = SQLite3::Database.new( @database )

        if database.execute( "SELECT * FROM groups WHERE group_id='#{group_id}'").empty?
            populateGroup(group_id)
            scrapeMessages(group_id)
        else
            update_time = database.execute( "SELECT strftime('%s', updated_at) FROM groups WHERE group_id='#{group_id}'" )        
            scrapeMessages(Time.now.to_i - update_time[0][0].to_i, group_id)
        end
    end

    #This will pull all messages for a given period of time and group, and store it in the messages table.  Takes in a time, in epoch seconds.  To search for all messages, entire the current epoch time.
    def scrapeMessages(searchTime = Time.now.to_i, group_id)
        gm = Groupme.new
        database = SQLite3::Database.new( @database ) 
        
        id = 0
        t = Time.now.to_i
        while (Time.now.to_i - t.to_i) < (searchTime + 604800) do

            if id == 0
                messages = gm.get("groups/#{group_id}/messages", @token)['response']
            else
                messages = gm.get("groups/#{group_id}/messages", @token, "before_id=#{id}")['response']
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
                                   database.execute( "INSERT INTO likes(message_id, user_id) VALUES (?, ?)",
                                   message['id'], 
                                   user )
                               end
                           end 
                       end
                       if !message['text'].nil?
                           database.execute( "INSERT INTO messages(message_id, created_at, user_id, group_id, avatar_url, text, image) VALUES (?, datetime('#{message['created_at']}', 'unixepoch'), ?, ?, ?, ?, ?)",
                           message['id'],
                           message['user_id'],
                           message['group_id'],
                           message['avatar_url'], 
                           message['text'], 
                           image )
                       else
                           database.execute( "INSERT INTO messages(message_id, created_at, user_id, group_id, avatar_url, text, image) VALUES (?, datetime('#{message['created_at']}', 'unixepoch'), ?, ?, ?, ?, ?)",
                           message['id'],
                           message['user_id'],
                           message['group_id'],
                           message['avatar_url'], 
                           'none', 
                           image )
                       end
                   end
                end    
                #For likes, we want to scan all posts a week back from the search time
                if ((Time.now.to_i - t.to_i) < (searchTime.to_i + 604800) )
                   message['favorited_by'].each do | likedMembers |
                       if database.execute("SELECT count(user_id) FROM likes WHERE message_id=#{message['id']} AND user_id=#{likedMembers}")[0][0] == 0
                           database.execute("INSERT INTO likes(message_id, user_id) VALUES (?, ?)",
                           message['id'], 
                           likedMembers ) 
                       end 
                   end
                end
            end

            t = messages['messages'].last['created_at']
            id = messages['messages'].last['id'] 
        end
    end
end
