require 'rubygems'
require 'logger'

module OurStage
  module Rack
    class Logger
      class << self
        attr_accessor :environment, :log
      end

      def self.logger
        unless @log
          @log = ::Logger.new("log/#{environment}.log", File::WRONLY | File::APPEND)
          case environment
          when 'development'
            @log.level = ::Logger::DEBUG
          when 'test'
            @log.level = ::Logger::DEBUG
          when 'production'
            @log.level = ::Logger::INFO
          else
            raise ArgumentError.new("Invalid environment #{environment}, must be #{valid_environments.join(' OR ')}") 
          end
        end
        @log
      end
    end
  end
end
