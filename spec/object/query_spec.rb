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
    
    @user_2 = User.new( 
      :username => 'B',
      :name => ['Burny', 'Tierney'],
      :dob => Date.parse('12/28/1921'),
      :created_at => Time.now + 3600,
      :log => Log.new,
      :password => 'my secret!'
    )
    @user_2.commit!
    
  end
  
  it 'should be have a class method for #index_on' do
    User.should respond_to(:index_on)
  end
  
  it 'should create indexes on the storage class' do 
    User.index_on(:created_at)  
    User::Storage.indexes.should include('created_at')
  end  
  
  it 'should query on a time' do
    User.index_on(:created_at)
    users = User.query( :created_at, :equals => Time.now )
    users.size.should == 1
    users.first.should == @user
  end  
   
end  
   
