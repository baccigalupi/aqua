$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'aqua'
require 'spec'
require 'spec/autorun'
                    
 
def require_fixtures
  Dir[ File.dirname(__FILE__) + "/object/object_fixtures/**/*.rb" ].each do |file|
    require file
  end
end

def build_user_ivars 
  @time = Time.now
  @date = Date.parse('12/23/1969')
  @message = "Hello World! This is a log entry"
  @log = Log.new( :message => @message, :created_at => @time ) # embedded object
  @other_user = User.new( :username => 'strictnine', :name => ['What', 'Ever'] ) # stubbed objects
  @user = User.new(
    :username => 'kane',
    :name => ['Kane', 'Baccigalupi'],
    :dob => @date,
    :created_at => @time,
    :log => @log,
    :password => 'my secret!',
    :other_user => @other_user 
  )
  @pack = @user._pack  
end  


Spec::Runner.configure do |config|
end
