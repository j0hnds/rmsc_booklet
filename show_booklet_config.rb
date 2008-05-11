require 'yaml'
require 'singleton'

class Configuration
  include Singleton
  
  CONFIG_FILE = 'show_booklet_gen.yaml'
  
  def initialize
    @tree = YAML::parse(File.open(CONFIG_FILE))
  end
  
  def get_value(property_path)
    element = @tree.select(property_path)[0]
    element.nil? ? nil : element.value
  end
end
