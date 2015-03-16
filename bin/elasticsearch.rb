#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'time'

require_relative 'groupme'

class Elasticsearch

    include HTTParty
    
    def initialize
    end

    base_uri 'http://localhost:9200//'
    format :json

    # Indexes a document into Elasticsearch
    def indexDocument(index, type, document, id)
        self.class.post("#{index}/#{type}/#{id}", :body => document.to_json)
    end

    # Returns the newest message in a group
    def getNewestDocument(index, type, group_id)

        # Elasticsearch query to find the newest document, based of 'timestamp'
        query = { 
            "query" => { 
                "term" => { 
                    "group_id" => "#{group_id}" 
                } 
            },
            "size" => 1,
            "sort" => [ {
                "timestamp" => {
                    "order" => "desc"
                }
           }]
        }

        return self.class.get("#{index}/#{type}/_search", :body => query.to_json)
    end

    # Returns the oldest message in a group
    def getOldestDocument(index, type, group_id)

        # Elasticsearch query to find the oldest document, based of 'timestamp'
        query = {
            "query" => {
                "term" => {
                    "group_id" => "#{group_id}"
                }
            },
            "size" => 1,
            "sort" => [ {
                "timestamp" => {
                    "order" => "asc"
                }
           }]
        }

        return self.class.get("#{index}/#{type}/_search", :body => query.to_json)
    end

    # Initialization of the group index
    def createGroupIndex(index)
        self.class.put(index)

        # A 'mapping' of property values for our message data
        mapping = { 
            'message' => { 
                'properties' => { 
                    'user' => { 
                        'type' => 'string', 
                        'index' => 'not_analyzed' 
                    },
                    'image' => {
                        'type' => 'string',
                        'index' => 'not_analyzed'
                    },
                    'avatar_url' => {
                        'type' => 'string',
                        'index' => 'not_analyzed'
                    },
                } 
            } 
        }

        self.class.put("#{index}/_mapping/message", :body => mapping.to_json)
    end
end
