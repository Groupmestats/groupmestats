#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'time'

require_relative 'groupme'
require_relative 'elasticsearch'

class Scraper

    #Constructor that takes a path to the sqlite database and a groupme oauth token
    def initialize(token, logging_path)
        @token = token

        $logger = Logger.new(logging_path)
        $gm = Groupme.new(logging_path)
        $elk = Elasticsearch.new
    end

    #Returns the user_id
    def getUser
        return $gm.get("/users/me", @token)['response']['id']
    end

    def scrapeNewMessages(group_id)
        scrapeMessages(group_id)

        group = $gm.get("groups/#{group_id}", @token)['response']
        $logger.info "Scraped messages from #{group['name']}"
    end

    def scrapeMessages(searchTime = Time.now.to_i, group_id)

        id = 0
        t = Time.now.to_i

        scraped_messages = Hash.new
        scraped_likes = Array.new

        t1 = Time.new

        members = $gm.get("groups/#{group_id}", @token)['response']['members']

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
                       if !message['favorited_by'].nil?
                           if message['favorited_by'].length != 0
                               message['favorited_by'].each do | user |
                                   scraped_likes.push([message['id'], user])
                               end
                           end
                       end
                       name = members.detect { |u| u['user_id'] == message['user_id'] }
                       if name.nil?
                           name = Hash.new
                           name['nickname'] = 'none'
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
                           :avatar_url => message['avatar_url'],
                           :message => message['text'],
                           :image => image
                       }

                       $elk.indexDocument("group-#{message['group_id']}", 'message', document)
                   end

            t = messages['messages'].last['created_at']
            id = messages['messages'].last['id']
        end


        t2 = Time.new
        $logger.info "Scrape time for group id #{group_id} was: #{(t2-t1).to_s} seconds"
        end
    end
end

scraper = Scraper.new('3ee22b60c1830131a29f12c45db03ee6', 'log.log')
scraper.scrapeNewMessages('8348761')
