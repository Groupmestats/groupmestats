#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'httparty'
require 'persistent_http'
require 'persistent_httparty'
require 'logger'

#Class that invokes HTTParty.
class Groupme
    include HTTParty
    persistent_connection_adapter( :name => 'my_cool_rest_client',
                                  :pool_size => 1000,
                                  :idle_timeout => 10,
                                  :keep_alive => 30 )

    base_uri 'https://api.groupme.com/v3'
    format :json

    def initialize(logging_path)
        #$logger = Logger.new(logging_path)
    end

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
                return 'nil'
            end
            while retry_attempts < 3 do
                #$logger.error "Could not connect to groupme.com.  Will retry in 60 seconds"
                sleep(60)
                self.class.get(query)
                retry_attempts += 1
            end
            if retry_attempts >= 3
                #$logger.error "Could not connect to groupme"
                abort('Could not connect to groupme')
            end
        end
        return response
    end
end
