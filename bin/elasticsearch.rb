#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'time'
require 'erb'

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

    def getFirstPostTime(index, type, group_id)
	query = {
  	    "sort" => [
		{ "created_at" => {"order" => "sac"}}
   	    ],
  	    "query" => {
    		"term" => { "group_id" => "#{group_id}" }
  	    },
  	    "size" => 1
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
    def createGroupIndex(index, group_id)
	ids = self.class.get(".kibana/_search?size=1000000", :body => { "query" => { "match_all" => {}}})['hits']['hits']
        ids.each do | source |
	    if source['_id'].include? "master"
		source['_id'] = source['_id'].sub('master:', "#{group_id}")
		document = source['_source']
		if source['_type'] != 'index-pattern'		
                    document['kibanaSavedObjectMeta']['searchSourceJSON'] = document['kibanaSavedObjectMeta']['searchSourceJSON'].sub('group-messages', "group-messages-#{group_id}")
		end
		if source['_type'].include? 'dashboard'
		    document['title'] = group_id
		    document['panelsJSON'] = document['panelsJSON'].gsub('master:', "#{group_id}")
		end
		response = self.class.put(".kibana/#{source['_type']}/#{source['_id']}", :body => document.to_json)
	    end
	end
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
                    'imagei_avatar' => {
                        'type' => 'string',
                        'index' => 'not_analyzed'
                    },
                    'avatar_url' => {
                        'type' => 'string',
                        'index' => 'not_analyzed'
                    },
		    'timestamp' => {
           		'type' => 'date',
            		'format' => 'dateOptionalTime'
           	    },
                } 
            } 
        }

        self.class.put("#{index}/_mapping/message", :body => mapping.to_json)
    end

    # Given a group_id, searches for all users in a group
    def getUsersForGroup(group_id)
        self.class.get("users/user/_search?q=group_id:#{group_id}")
    end

    # Given an index, group_id, and a useR_id, return all messages a user
    # has posted in a group
    def getAllMessagesForUser(index, group_id, user_id)
        query = {
            "size" => 100000,
            "query" => {
                "bool" => {
                    "must" => [
                        { 
                            "term" => { 
                                "user_id" => "#{user_id}" 
                            }
                        },
                        {
                            "term" => { 
                                "group_id" => "#{group_id}" 
                            }
                        }
                    ]
                }
            }
        }
        self.class.get("#{index}/message/_search", :body => query.to_json)
    end
end
