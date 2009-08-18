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


Spec::Runner.configure do |config|
end
