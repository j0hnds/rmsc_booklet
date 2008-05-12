require 'logger'
require 'singleton'
require 'show_booklet_config'

class Log
    include Singleton
    
    attr_reader :log
    
    def initialize
      # Get the name of the log file from the configuration
      log_file_name = Configuration.instance.get_value('/logging/log_file_name')
      # Get the path to the application
      app_path = File.dirname($0)
      # Path to log file
      log_file_path = File.join(app_path, log_file_name)
      file = open(log_file_path, File::WRONLY | File::APPEND | File::CREAT)
      @log = Logger.new(file)
      
      log_level = Configuration.instance.get_value('/logging/log_level')
      @log.level = log_level.to_i
    end
end
