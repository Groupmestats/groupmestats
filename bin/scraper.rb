#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'time'
require 'pp'

require_relative 'groupme'
require_relative 'elasticsearch'

class Scraper

    # Constructor that takes a path to the sqlite database and a groupme oauth token
    def initialize(token, logging_path)
        @token = token

        $logger = Logger.new(logging_path)
        $gm = Groupme.new(logging_path)
        $elk = Elasticsearch.new

        #Create group index, if not already created
#        $elk.createGroupIndex('group-messages')
    end

    # Returns the user_id
    def getUser
        return $gm.get("users/me", @token)['response']['id']
    end

    # Returns the user's current groups
    def getGroups
	return_result = []
	groups = $gm.get("groups", @token)['response']
	groups.each do | group |
	    image = group['image_url'] + '.avatar'
	    hash = { 'name' => group['name'], 'group_id' => group['group_id'], 'image' => image }
	    return_result.push(hash)
	end
	return return_result
    end

    def getGroup(group_id)
	group = $gm.get("groups/#{group_id}", @token)['response']
        image = group['image_url'] + '.avatar'
	return_result = { 'name' => group['name'], 'group_id' => group['group_id'], 'image' => image }
	return return_result
    end

    # Pulls only new messages from the last 'scrape' from groupme, and 
    # indexes them into elasticsearch
    def scrapeNewMessages(group_id)
        #Calculate the time delta between the present and the last seen document

        if $elk.getNewestDocument('group-messages', 'message', group_id)['status'] == 400
            scrapeMessages(group_id)
        else
            last_message_time = $elk.getNewestDocument('group-messages', 'message', group_id)['hits']['hits']

            if last_message_time.empty?
                scrapeMessages(group_id)
            else
                searchTime = Time.now.to_i - last_message_time[0]['_id'].to_i
                scrapeMessages(searchTime, group_id)
            end
        end

        group = $gm.get("groups/#{group_id}", @token)['response']
        $logger.info "Scraped messages from #{group['name']}"
    end

    # Given a group_id, pull users from groupme and index them into elasticsearch
    def scrapeUsersForGroup(group_id)
        members = $gm.get("groups/#{group_id}", @token)['response']['members']

        if $elk.getUsersForGroup(group_id)['status'] != 404
            indexed_members = $elk.getUsersForGroup(group_id)['hits']['hits']
        end

        members.each do | member |
            if !indexed_members.nil?
                indexed_members.each do | index_member |
                    if index_member['_source']['user_id'] ==
                        member['user_id']
                        if member['nickname'] != index_member['_source']['nickname']
                            updateNameInGroup(group_id, member['user_id'], member['nickname'])
                        end
                    end
                end
            end
            document = {
                :id => member['id'],
                :user_id => member['user_id'],
                :nickname => member['nickname'],
                :muted => member['muted'],
                :image_url => member['image_url'],
                :autokicked => member['autokicked'],
                :app_installed => member['app_installed'],
                :guid => member['guid'],
                :group_id => group_id
            }

            $elk.indexDocument('users', 'user', document, member['id'])
        end
    end

    # Updated every message in a group to reflect a user's name change
    def updateNameInGroup(group_id, user_id, nickname)
        messages = $elk.getAllMessagesForUser('group-messages', group_id, user_id)['hits']['hits']

        messages.each do | message |
            message['_source']['user'] = nickname
            $elk.indexDocument('group-messages', 'message', message['_source'], message['_id']).response
        end
    end

    # Scrapes all messages for a time interval.  Default is all messages
    # Indexes them into elasticsearch
    def scrapeMessages(searchTime = Time.now.to_i, group_id)
        id = 0
        t = Time.now.to_i
        t1 = Time.new

        group = $gm.get("groups/#{group_id}", @token)['response']
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
                   image = "none"
                   liked_users = ""
                   num_likes = 0

                   if !message['attachments'].empty?
                       if message['attachments'][0]['type'] == "image"
                          image = message['attachments'][0]['url']
                       end
                   end

                   name = group['members'].detect { |u| u['user_id'] == message['user_id'] }
                   if name.nil?
                       name = Hash.new
                       name['nickname'] = 'system'
                   end

                   if message['text'].nil?
                       message['test'] = ''
                   end
                   document = {
                       :timestamp => Time.at(message['created_at']).to_datetime,
                       :created_at => message['created_at'],
                       :user_id => message['user_id'],
                       :user => name['nickname'],
                       :group_id => message['group_id'],
                       :group_name => group['name'],
                       :avatar_url => message['avatar_url'],
                       :message => message['text'],
                       :image => image,
                       :favorited_by => message['favorited_by'],
                       :number_of_likes => message['favorited_by'].size
                   }

                   $elk.indexDocument('group-messages', 'message', document, message['id'])
               end

                t = messages['messages'].last['created_at']
                id = messages['messages'].last['id']
            end
        end

        t2 = Time.new
        $logger.info "Scrape time for group id #{group_id} was: #{(t2-t1).to_s} seconds"
    end
end
