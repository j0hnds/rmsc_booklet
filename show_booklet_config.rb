require 'yaml'
require 'singleton'

#
# This class manages the YAML configuration for the Show Booklet generator.
# This class is a singleton.
#
class Configuration
  include Singleton
  
  # The configuration file for the application
  CONFIG_FILE = 'show_booklet_gen.yaml'
  
  #
  # Constructs a new Configuration object. A side-effect of this constructor
  # is that the YAML tree is loaded.
  #
  def initialize
    @tree = YAML::parse(File.open(CONFIG_FILE))
  end
  
  #
  # Returns the value of the specified path. The paths expected are for YAML
  # objects. Example, '/db/db_pass'.
  #
  # +property_path+: the path to the value to return
  #
  # Returns the value of the property. If the path is non-existent, nil is
  # returned.
  #
  def get_value(property_path)
    element = @tree.select(property_path)[0]
    element.nil? ? nil : element.value
  end
  
end
