class Persistent 
  include Aqua::Tank
  
  # for testing class level configuration options
  def self.aquatic_options
    _aqua_opts
  end
  
end  
  