require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures
 
Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )

describe Aqua::Unpack do
  before(:each) do
    CouchDB.server.delete_all 
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
  
  describe 'loading from storage' do
    
    it 'should raise in error if the id doesn\' exist in the data store' do 
      user = User.new(:id => 'gerbil_farts')
      user.id.should == 'gerbil_farts'
      lambda{ user.reload! }.should raise_error
    end  
    
    it 'should raise an error if the id is nil' do
      lambda{ User.new.reload! }.should raise_error
    end  
  
  end
  
  describe 'unpacking to a new object' do 
    describe 'initialization' do
      it 'should initialize an Aquatic object' do
        user = User.load( @user.id )
        user.class.should == User
      end  
      
      describe 'Array derivatives' do
        before(:each) do 
          class Arrayed < Array
            aquatic
            attr_accessor :my_accessor
          end
          arrayish = Arrayed['a', 'b', 'c', 'd']
          arrayish.my_accessor = 'Newt'
          arrayish.commit!
          @id = arrayish.id
        end
           
        it 'should create an aquatic Array derivative' do 
          arrayish_2 = Arrayed.load( @id )
          arrayish_2.class.should == Arrayed 
        end
      
        it 'should load initialization values into an aquatic Array derivative' do
          arrayish_2 = Arrayed.load( @id )
          arrayish_2.first.should == 'a'
        end 
      end   
      
      describe 'Hash derivatives' do
        before(:each) do 
          class Hashed < Hash
            aquatic
            attr_accessor :my_accessor
          end
          hashish = Hashed.new
          hashish['1'] = '2'
          hashish.my_accessor = 'Newt'
          hashish.commit!
          @id = hashish.id
        end 
           
        it 'should create an aquatic Hash derivative' do 
          Hashed.load( @id ).class.should == Hashed
        end
           
        it 'should load initialization values into an aquatic Hash derivative' do
          hashish = Hashed.load( @id )
          hashish['1'].should == '2'  
        end  
      end  
    end 
    
    describe 'unpacking the instance variables' do
      it 'should reinstantiate all the instance variables' do 
        user = User.load(@user.id) 
        ['@created_at', '@dob', '@log', '@name', '@username'].each do |ivar|
          user.instance_variables.should include( ivar )
        end   
      end 
      
      it 'should unpack Dates' do
        user = User.load(@user.id)
        user.dob.should == @user.dob
      end 
      
      it 'should unpack Times' do
        user = User.load(@user.id)
        user.created_at.to_s.should == @user.created_at.to_s
      end    
      
      it 'should unpack Strings' do
        user = User.load(@user.id)
        user.username.should == @user.username
      end
      
      it 'should unpack true and false' do 
        # true
        @user.grab_bag = true
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == true
        # false
        @user.grab_bag = false
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == false
      end    
      
      it 'should unpack Fixnums' do
        @user.grab_bag = 3
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == 3
      end
      
      it 'should unpack Bignums' do
        @user.grab_bag = 12345678901234567890
        @user.grab_bag.class.should == Bignum
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == 12345678901234567890
      end 
      
      it 'should unpack Floats' do 
        @user.grab_bag = 1.681
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == 1.681
      end 
      
      it 'should unpack Rationals' do 
        @user.grab_bag = Rational( 1, 17 )
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == Rational( 1, 17 )
      end
      
      it 'should unpack an Array' do 
        user = User.load(@user.id)
        user.name.should == @user.name
      end
      
      it 'should unpace an Array with non-string objects' do 
        @user.grab_bag = ['1', 2]
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == @user.grab_bag
      end  
      
      it 'should unpack a deeply nested Array' do
        @user.grab_bag = ['1','1','1', ['2','2', ['3']]]
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == @user.grab_bag
      end        
      
        
      it 'should unpack an Array derivative' do
        array_udder = ArrayUdder['1','2','3']
        array_udder.udder
        @user.grab_bag = array_udder
        @user.commit! 
        user = User.load( @user.id )
        user.grab_bag.should == @user.grab_bag
      end
        
      it 'should unpack a Hash' do 
        @user.grab_bag = {'1' => '2'}
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == @user.grab_bag
      end
      
      it 'should unpack symbol keys differently than unpacking string keys' do  
        @user.grab_bag = {'first' => '1', :second => '2'}
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.keys.should include('first', :second)
      end    
      
      it 'should unpack a Hash with non-string values' do 
        @user.grab_bag = {'1' => 2}
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == @user.grab_bag
      end  
      
      it 'should unpack a deeply nested Hash' do
        @user.grab_bag = {'1' => {'2' => {'3' => 4}}}
        @user.commit!
        user = User.load(@user.id)
        user.grab_bag.should == @user.grab_bag 
      end  
      
      it 'should unpack a Struct' do 
        @struct = OpenStruct.new(
          :gerbil => true, 
          :cat => 'yup, that too!', 
          :disaster => ['pow', 'blame', 'chase', 'spew'],
          :nipples => 'yes'
        ) 
        
        @user.grab_bag = @struct
        @user.commit!
        user = User.load(@user.id)
        
        user.grab_bag.should == @user.grab_bag
      end 
      
      it 'should unpack a Hash derivative' do
        @struct = OpenStruct.new(
          :gerbil => true, 
          :cat => 'yup, that too!', 
          :disaster => ['pow', 'blame', 'chase', 'spew'],
          :nipples => 'yes'
        )
        
        @hash_derivative = CannedHash.new( 
          :ingredients => ['Corned Beef', 'Potatoes', 'Tin Can'],
          :healthometer => false,
          :random_struct => @struct 
        )
        
        @user.grab_bag = @hash_derivative
        @user.commit! 
        
        user = User.load(@user.id)
        user.grab_bag.should == @user.grab_bag 
      end
         
      
      it 'should unpack an aquatic object' do 
        @user.commit!
        @user.log.should == @log
      end  
      
    end  
  end
  
  # object.reload is used by Object.load(id), so there isn't any need right now to test both since
  # Object.load tests both at once.
      
end  
   
