#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'httparty'

#Class that invokes HTTParty.
class Groupme
    include HTTParty

    base_uri 'https://api.groupme.com/v3//'
    format :json

    def get(query, token, args=nil)
        if args.nil?
            new_query = query + "?token=#{token}"
        else
            new_query = query + "?token=#{token}&#{args}"
        end

        response = self.class.get(new_query, :verify => false)

        retry_attempts = 0

        if response.code != 200
            if response.nil?
                abort('No more messages returned from groupme. Perhaps you have pulled all available messages?')
            end
            while retry_attempts < 3 do
                puts "Could not connect to groupme.com.  Will retry in 60 seconds"
                sleep(60)
                self.class.get(query)
                retry_attempts += 1
            end
            if retry_attempts >= 3
                abort('Could not connect to groupme')
            end
        end
        return response
    end
end
