class Log
  aquatic :embed => true
  
  attr_accessor :created_at, :message
  
  
  # convenience methods for inspection during testing
  # ------------------------------------------------- 
  # for testing class level configuration options
  def self.aquatic_options
    _aqua_opts
  end
   
end