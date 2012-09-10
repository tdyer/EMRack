require_relative 'db_connection'

module OurStage
  module Rack
    class Onliner

      BUFFER_TIME = 60
      FADEOUT_TIME = 300

      attr_accessor :user_id, :user_level, :activity, :channel, :target_user,
      :parameters, :ip_addr, :updated_at
      
      def initialize(opts = { })
        opts.each{ |k, v| send("#{k}=", v) if respond_to?("#{k}=")}
      end

      def to_s
        vars = self.instance_variables.map{ |v| "#{ v}=#{instance_variable_get(v).inspect}"}.join(", ")
        "<#{self.class}: #{vars}>"
      end

      # Start out by buffering the user updates by BUFFER_TIME
      # we collect all users info for that time and then batch update.
      # Warning, it should be shorter than the online timeout or the buffer
      # time becomes the new online timeout.
      def self.process(onliner)
        logger.debug "Onliner.process: "
        fail ArgumentError.new("Onliner.process: no user_id for onliner") unless onliner && onliner.user_id
        
        @@users ||= {}
        @@last_update_time ||= Time.now.utc         # Initialize last update time

        # Update the buffer user info if there was a message
        @@users[onliner.user_id] = onliner
        logger.debug "Onliner.process: adding onliner for user #{onliner.user_id}"
        logger.debug "Onliner.process: users =  #{@@users.inspect}"        

        # Capture the time so that we have regular intervals not affected by time to process the update
        time_now = Time.now.utc

        if time_now > @@last_update_time + BUFFER_TIME
          # if the process 
          # Onliner.affirm_operational(Onliner.fadeout_time)
          Onliner.delete_old do
            Onliner.insert_new
            run_time = Time.now.utc - time_now
            # Onliner.affirm_operational(BUFFER_TIME + 5.seconds)
            @@users = {}
            @@last_update_time = time_now
            if run_time > Onliner::FADEOUT_TIME
              logger.error 'Onliner.process: processing took longer than the fadeout time!! Contact Adam or Kevin.'
            end
          end
        end
      end

      def self.delete_old(&blk)
        # Onliner.delete_all(["updated_at < CAST (? AS timestamp) - INTERVAL '300 seconds'", Time.now.utc])
        # Onliner.delete_all(["user_id IN (?)", users.keys]) if
        # users.keys.length > 0

        # delete all onliners older than 5 minutes
        sql = %Q(DELETE FROM onliners where updated_at < CAST ('#{Time.now.utc}' AS timestamp) - INTERVAL '300 seconds';)
        logger.debug "Onliner.delete_old: SQL = #{sql.inspect}"
        df1 = ourstage_dbconn.execute(sql)

        df1.callback do
          logger.info "Onliner.delete_old: success deleting old onliners"

          # delete all onliners for users that are to be updated
          sql2 = %Q(DELETE FROM onliners where user_id IN (#{@@users.keys.join(',')});)
          logger.debug "Onliner.delete_old: SQL2 = #{sql2.inspect}"
          df2 = ourstage_dbconn.execute(sql2)

          df2.callback do
            logger.info "Onliner.delete_old: success deleting by user_id"
            blk.call if block_given?
          end
          
          df2.errback do |ex|
            if ex.is_a?(PG::Result)
              logger.error "Onliner.delete_old: deleting by user_id, Exception = #{ex.error_message}"
            else
              logger.error "Onliner.delete_old.: deleting by user_id, Exception = #{ex.inspect}"
            end
            raise ex
          end
        end

        # error callback
        df1.errback do |ex|
          logger.error "Onliner.delete_old: Exception for deleting old onliners"
          if ex.is_a?(PG::Result)
            logger.error "Onliner.delete_old: Exception = #{ex.error_message}"
          else
            logger.error "Onliner.delete_old: Exception = #{ex.inspect}"
          end
          raise ex
        end
      end

      # This method take a hash of users and updates the Onliners table based on that
      def self.insert_new
        @@users.values.each do |onliner|          
          begin
            # Extract act_channel, act_user, act_whatever into the parameters field and marshal it
            parameters = {}
            for key in [:channel, :target_user]
              parameters[key] = onliner.send(key)
            end
            onliner.parameters = Marshal.dump(parameters) if parameters.keys.length > 0
            #
            # Merge in the extra params marshalled into text
            Onliner.create!(onliner)
          rescue Exception => ex
            logger.error "Onliner.insert_new: Exception = #{ex.to_s}, failed to create onliner record for #{onliner.inspect}"
          end
        end
      end

      def self.create!(onliner)
        sql = %Q(INSERT INTO onliners (user_id, user_level, activity, parameters, ip_addr, updated_at) VALUES ('#{onliner.user_id}', '#{onliner.user_level}', '#{onliner.activity.to_i}', '#{onliner.parameters}', '#{onliner.ip_addr}', '#{onliner.updated_at}') )
        logger.debug "Onliner.create!: SQL = #{sql.inspect}"
        df = ourstage_dbconn.execute(sql)

        df.callback do |result|
          logger.info "Onliner.create!: success creating an onliner"
        end

        df.errback do |ex|
          logger.error "Onliner.create!: Exception for creating onliner"
          if ex.is_a?(PG::Result)
            logger.error "Onliner.create!: Exception = #{ex.error_message}"
          else
            logger.error "Onliner.create!: Exception = #{ex.inspect}"
          end
          raise ex
        end
      end

      # get the non-blocking Postgres connection for the ourstage DB
      def self.ourstage_dbconn
        OurStage::Rack::DBConn.ourstage_dbconn
      end

      def self.logger
        @log ||= OurStage::Rack::Logger.logger        
      end
      
    end
  end
end
