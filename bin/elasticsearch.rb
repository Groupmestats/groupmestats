#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'time'

require_relative 'groupme'

class Elasticsearch

    include HTTParty
    
    #Constructor that takes a path to the sqlite database and a groupme oauth token
    def initialize
    end

    base_uri 'http://localhost:9200//'
    format :json

    def indexDocument(index, type, document)
        self.class.put("#{index}/#{type}/#{document[:created_at]}/", :body => document.to_json)
    end
end
