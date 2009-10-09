require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

describe Aqua::Query do
  before(:each) do
    User::Storage.database.delete_all
    @time = Time.now
    @date = Date.parse('12/23/1969')
    @log = Log.new( :message => "Hello World! This is a log entry", :created_at => Time.now )
    @user = User.new(
      :username => 'kane',
      :name => ['Kane', 'Baccigalupi'],
      :dob => @date,
      :created_at => @time,
      :log => @log,
      :password => 'my secret!' 
    ) 
    @user.commit!
  end
  
  describe 'query_index' do 
    it 'should be a class method' do
      User.should respond_to(:query_index)
    end   
  end   
end  
   
