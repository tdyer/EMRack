require 'yaml'
require 'erb'
require 'em-postgres'

module OurStage
  module Rack
    class DBConn
      class << self
        attr_accessor :environment
      end

      # get the non-blocking Postgres connection for the ourstage DB
      def self.ourstage_dbconn
        unless @conn
          # open the database config file
          db_config = YAML.load(ERB.new(File.read("config/ourstage_database.yml")).result )
          database = db_config[environment]['database']
          @conn = EventMachine::Postgres.new(:database => database)
          @conn.setnonblocking(true) # may not be needed?     
        end
        @conn
      end

      # get the non-blocking Postgres connection for the stats DB
      def self.stats_dbconn
        unless @stats_conn
          # open the database config file
          db_config = YAML.load(ERB.new(File.read("config/stats_database.yml")).result )
          database = db_config[environment]['database']
          @stats_conn = EventMachine::Postgres.new(:database => database)
          @stats_conn.setnonblocking(true) # may not be needed?     
        end
        @stats_conn
      end
    end
  end
end
