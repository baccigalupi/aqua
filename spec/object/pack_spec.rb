require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )

describe Aqua::Pack do
  before(:each) do
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
    
    def pack_grab_bag( value )
      @user.grab_bag = value
      @user._pack[:ivars][:@grab_bag]
    end 
  end
  
  describe 'packing classes' do 
    it 'should pack class variables'
    it 'should pack class level instance variables'
    it 'should pack class definition'
    it 'should save all the class details to the design document'
    it 'should package views/finds in the class and save them to the design document\'s view attribute'
    it 'should be saved into the design document' 
  end 
  
  describe 'external saves and stubs' do
    before(:each) do
      CouchDB.server.delete_all
      @graeme = User.new(:username => 'graeme', :name => ['Graeme', 'Nelson'])
      @user.other_user = @graeme
      @pack = @user._pack
    end
      
    describe 'packing' do
      it 'should pack a stubbed object representation under __pack[:stubs]' do 
        @pack[:stubs].size.should == 1
        other_user_pack = @pack[:stubs].first 
        other_user_pack[:class].should == "User"
        other_user_pack[:id].should == @graeme
      end  
      
      it 'should pack the values of a stubbed methods' do
        other_user_pack = @pack[:stubs].first  
        other_user_pack[:methods].size.should == 1
        other_user_pack[:methods][:username].should == 'graeme'
      end 
      
      it "should pack a stub of an object with embed=>false" do
        suger = Suger.new
        suger.sweetness = Suger.new
        lambda {suger._pack}.should_not raise_error
      end
      
      it 'should pack an array of stubbed methods' do 
        User.configure_aqua( :embed => {:stub =>  [:username, :name] } )
        @user = User.new(
          :username => 'kane',
          :name => ['Kane', 'Baccigalupi'],
          :dob => @date,
          :created_at => @time,
          :log => @log,
          :password => 'my secret!',
          :other_user => @graeme 
        ) 
        
        @pack = @user._pack
        other_user_pack = @pack[:stubs].first  
        other_user_pack[:methods].size.should == 2
        other_user_pack[:methods][:username].should == 'graeme'
        other_user_pack[:methods][:name].should == ['Graeme', 'Nelson']
        
        # reseting the User model, and @user instance
        User.configure_aqua( :embed => {:stub =>  :username } )
      end   
      
      it 'should pack the object itself with the class "Aqua::Stub"' do 
        @pack[:ivars][:@other_user][:class].should == "Aqua::Stub"
      end  
        
      it 'should pack the object itself with a reference to the __pack[:stubs] object' do 
        @pack[:ivars][:@other_user][:init].should == "/STUB_0"
      end  
    end
    
    describe 'commiting' do
      it 'should commit external objects' do 
        @user.commit!
        db_docs = CouchDB::Database.new.documents
        db_docs['total_rows'].should == 2
      end
        
      it 'should save the id to the stub after commiting' do
        @user.commit!
        doc = CouchDB.get( "http://127.0.0.1:5984/aqua/#{@user.id}" )
        doc["stubs"].first["id"].class.should == String 
      end
        
      it 'should log a warning if an external object doesn\'t commit' do
        @graeme.should_receive(:commit).and_return(false)
        @user.commit!
        @user._warnings.size.should == 1
        @user._warnings.first.should match(/unable to save/i)
      end
      
      it 'should log a warning and save the id if an object has an id' do
        @graeme.commit!
        @graeme.should_receive(:commit).and_return(false)
        @user.commit!
        @user._warnings.size.should == 1
        @user._warnings.first.should match(/unable to save latest/i) 
        doc = CouchDB.get( "http://127.0.0.1:5984/aqua/#{@user.id}" )
        doc["stubs"].first["id"].class.should == String
      end  
        
      it 'should rollback external commits if the parent object doesn\'t save'
    end
    
  end     
  
  describe 'hiding attributes' do
    it 'should add a class method for designating hidden instance variables' do
      User.should respond_to( :hide_attributes )
    end
    
    it 'class method should hide instance variables designated by the user as hidden' do
      @user.visible_attr.should_not include('@password')
      @user.class._hidden_attributes.should include('@password')
    end 
      
    it 'should hide the @__pack variable' do
      @user.visible_attr.should_not include('@__pack') 
      @user.class._hidden_attributes.should include('@__pack')
    end    
  
    it 'should hide the @_store variable' do 
      @user.visible_attr.should_not include('@_store')
      @user.class._hidden_attributes.should include('@_store')
    end
    
    it 'should not pack hidden variables' do
      @pack = @user._pack
      @pack[:ivars].keys.should_not include("@password")
    end  
  end    
  
  describe 'packing up object instances:' do
    before(:each) do
      @pack = @user._pack
    end  
    
    it 'should save its class name as an attribute on the pack document' do
      @pack[:class].should == 'User'
    end
    
    it 'should add an :id accessor if :id is not already an instance method' do 
      @user.should respond_to(:id=)
    end
    
    it 'should pack an id if an id is present' # TODO
    
    it 'should not pack an id if an id is not present' do
      @pack.id.should be_nil
    end
    
    it 'should pack the _rev if it is present' do
      @user.instance_variable_set("@_rev", '1-2222222')
      pack = @user._pack 
      pack[:_rev].should == '1-2222222'
    end    
    
    describe 'instance variables, ' do
      describe 'hashes'
        it 'should be in a hash-like object with the key :ivars' do 
          @pack[:ivars].should_not be_nil
          @pack[:ivars].should respond_to(:keys)
        end
        
        it 'should save symbol keys differently that string keys' do
          @user.name = {:first => 'Kane', 'last' => 'Baccigalupi'}
          pack = @user._pack
          pack[:ivars][:@name][:init].keys.sort.should == [':first', 'last']
        end   
      
      describe 'basic ivars types' do
        it 'should pack strings as strings' do 
          @pack[:ivars][:@username].should == 'kane'
        end  
    
        it 'should pack an array of strings as a hash with the :class "Array" and :init as the original array' do
          @pack[:ivars][:@name].should == {'class' => 'Array', 'init' => ['Kane', 'Baccigalupi']}
        end  
      end
      
      describe 'objects: ' do
        # TODO: http://www.ruby-doc.org/core/
        # make sure all the basic types work 
        
        describe 'Time' do
          it 'should save as a hash with the class and to_s as the value' do
            time_hash = @pack[:ivars][:@created_at] 
            time_hash['class'].should == 'Time'
            time_hash['init'].class.should == String
          end
        
          it 'the value should be reconstitutable with Time.parse' do 
            # comparing times directly never works for me. It is probably a micro second issue or something
            @time.to_s.should == Time.parse( @pack[:ivars][:@created_at]['init'] ).to_s
          end 
        end
        
        describe 'true and false' do
          it 'should save as a hash with only the class' do 
            @user.grab_bag = true
            pack = @user._pack
            pack[:ivars][:@grab_bag].should == {'class' => 'TrueClass', 'init' => 'true'}
            
            @user.grab_bag = false
            pack = @user._pack
            pack[:ivars][:@grab_bag].should == {'class' => 'FalseClass', 'init' => 'false'}
          end  
        end    
        
        describe 'Date' do
          it 'should save as a hash with the class and to_s as the value' do
            time_hash = @pack[:ivars][:@dob] 
            time_hash['class'].should == 'Date'
            time_hash['init'].class.should == String
          end
        
          it 'the value should be reconstitutable with Date.parse' do 
            @date.should == Date.parse( @pack[:ivars][:@dob]['init'] )
          end 
        end      
        
        describe 'Numbers' do
          it 'should pack Fixnums with correct class and value' do 
            pack = pack_grab_bag( 42 )
            pack[:class].should == 'Fixnum'
            pack[:init].should == '42'
          end
          
          it 'should pack Bignums with correct class and value' do 
            pack = pack_grab_bag( 123456789123456789 )
            pack[:class].should == 'Bignum'
            pack[:init].should == '123456789123456789'
          end 
          
          it 'should pack Floats with correct class and value' do 
            pack = pack_grab_bag( 3.2 )
            pack[:class].should == 'Float'
            pack[:init].should == '3.2'
          end 
          
          it 'should pack Rationals with the correct class and values' do
            pack = pack_grab_bag( Rational( 1, 17 ) )
            pack[:class].should == 'Rational'
            pack[:init].should == ['1', '17']
          end    
          
        end
        
        describe 'hashes with object as keys' do 
          it 'should pack an hash containing only strings/symbols for keys and values, with an init value that is that hash and a class key' do
            @user.name = {'first' => 'Kane', 'last' => 'Baccigalupi'}
            pack = @user._pack
            pack[:ivars][:@name].should == {'class' => 'Hash', 'init' => {'first' => 'Kane', 'last' => 'Baccigalupi'} }
          end
           
          it 'should pack a numeric object key' do
            pack = pack_grab_bag( {1 => 'first', 2 => 'second'} )
            keys = pack[:init].keys
            keys.should include( '/OBJECT_0', '/OBJECT_1' )
            user_pack = @user.instance_variable_get("@__pack")
            user_pack[:keys].size.should == 2
            user_pack[:keys].first['class'].should == 'Fixnum'  
          end
          
          it 'should pack a more complex object as a key' do
            struct = OpenStruct.new( :gerbil => true ) 
            pack = pack_grab_bag( { struct => 'first'} )
            keys = pack[:init].keys
            keys.should include( '/OBJECT_0' )
            user_pack = @user.instance_variable_get("@__pack")
            user_pack[:keys].size.should == 1
            user_pack[:keys].first['class'].should == 'OpenStruct'
          end    
        end    
         
        describe 'embeddable aquatic' do
          it 'aquatic objects should have packing instructions in the form of #_embed_me' do
            @user._embed_me.should == {'stub' => :username }
            Log.new._embed_me.should == true
            User.configure_aqua( :embed => {:stub =>  [:username, :name] } ) 
            @user._embed_me.should == { 'stub' => [:username, :name] }
            # reset for future tests
            User.configure_aqua( :embed => {:stub => :username } )
          end   
  
          it 'should save their ivars correctly' do
            @pack[:ivars][:@log].keys.should include('ivars')
            @pack[:ivars][:@log]['ivars'].keys.should == ['@created_at', '@message'] 
            @pack[:ivars][:@log]['ivars']['@message'].should == "Hello World! This is a log entry"
          end 
        
          it 'should correctly pack Array derivatives' do 
            class Arrayed < Array
              aquatic
              attr_accessor :my_accessor
            end
            arrayish = Arrayed['a', 'b', 'c', 'd']
            arrayish.my_accessor = 'Newt'
            pack = arrayish._pack
            pack.keys.should include('class', 'init', 'ivars')
            pack['init'].class.should == Array
            pack['init'].should == ['a', 'b', 'c', 'd']
            pack['ivars']['@my_accessor'].should == 'Newt'   
          end
          
          it 'should correctly pack Hash derivative' do
            class Hashed < Hash
              aquatic
              attr_accessor :my_accessor
            end
            hashish = Hashed.new
            hashish['1'] = '2'
            hashish.my_accessor = 'Newt'
            pack = hashish._pack
            pack.keys.should include('class', 'init', 'ivars')
            pack['init'].class.should == HashWithIndifferentAccess
            pack['init'].should == {'1' => '2'}
            pack['ivars']['@my_accessor'].should == 'Newt'
          end    
        
        end
        
        describe 'non-aquatic' do
          before(:each) do 
            @struct = OpenStruct.new(
              :gerbil => true, 
              :cat => 'yup, that too!', 
              :disaster => ['pow', 'blame', 'chase', 'spew']
            )
            @grounded = Grounded.new(
              :openly_structured => @struct,
              :hash_up => {:this => 'that'},
              :arraynged => ['swimming', 'should', 'be easy', 'if you float']
            )
             
          end
            
          describe 'OpenStructs' do
            before(:each) do
              @user.grab_bag = @struct
              pack = @user._pack
              @grab_bag = pack[:ivars][:@grab_bag]
            end
              
            it 'the key "class" should map to "OpenStruct"' do
              @grab_bag['class'].should == 'OpenStruct'
            end
            
            it 'the key "ivars" should have the keys "@table"' do
              @grab_bag['ivars'].keys.should == ['@table'] 
            end
            
            it 'should initialize with the @table instance variable' do  
              init_keys = @grab_bag['init'].keys
              init_keys.should include(':cat')
              init_keys.should include(':disaster')
              init_keys.should include(':gerbil')
              @grab_bag['init'][':gerbil'].should == {'class' => 'TrueClass', 'init' => 'true'}
              @grab_bag['init'][':cat'].should == 'yup, that too!'
              @grab_bag['init'][':disaster'].should == {'class' => 'Array', 'init' => ['pow', 'blame', 'chase', 'spew']}
            end
          end
          
          describe 'Uninherited classes with deep nesting' do
            before(:each) do
              @user.grab_bag = @grounded
              pack = @user._pack
              @grab_bag = pack[:ivars][:@grab_bag]
            end
            
            it 'the key "class" should map correctly to the class name' do
              @grab_bag['class'].should == 'Grounded'
            end
            
            it 'should have ivars keys for all the ivars' do
              keys = @grab_bag[:ivars].keys
              keys.should include('@openly_structured')
              keys.should include('@hash_up')
              keys.should include('@arraynged')
            end  
            
            it 'should correctly display the nested OpenStruct' do 
              user_2 = User.new(:grab_bag => @struct) # this has already been tested in the set above
              user_2._pack[:ivars][:@grab_bag].should == @grab_bag[:ivars][:@openly_structured]
            end  
          end  
          
          describe 'Classes inherited from Array' do
            before(:each) do
              @struct = OpenStruct.new(
                :gerbil => true, 
                :cat => 'yup, that too!', 
                :disaster => ['pow', 'blame', 'chase', 'spew'],
                :nipples => 'yes'
              )  
              @strange_array = ArrayUdder['cat', 'octopus', @struct ]
              @strange_array.udder # sets an instance variable
              @user.grab_bag = @strange_array
              pack = @user._pack
              @grab_bag = pack[:ivars][:@grab_bag]
            end
            
            it 'should correctly map the class name' do
              @grab_bag[:class].should == 'ArrayUdder'
            end
            
            it 'should store the instance variables' do 
              @grab_bag[:ivars].keys.should == ['@udder'] 
            end
            
            it 'should store the simple array values' do
              @grab_bag[:init].should_not be_nil
              @grab_bag[:init].class.should == Array
              @grab_bag[:init].should include('cat')
              @grab_bag[:init].should include('octopus')
            end 
            
            it 'should store the more complex array values correctly' do
              user_2 = User.new(:grab_bag => @struct) # this has already been tested in the set above
              user_2._pack[:ivars][:@grab_bag].should == @grab_bag[:init].last
            end   
          end
          
          describe 'Classes inherited from Hash' do
            before(:each) do
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
              @hash_derivative.yum # sets an instance variable
              @user.grab_bag = @hash_derivative
              pack = @user._pack
              @grab_bag = pack[:ivars][:@grab_bag]
            end
            
            it 'should correctly map the class name' do
              @grab_bag[:class].should == 'CannedHash'
            end
            
            it 'should store the instance variables' do 
              @grab_bag[:ivars].keys.should == ['@yum'] 
            end
            
            it 'should store the simple hash values' do
              @grab_bag[:init].should_not be_nil
              @grab_bag[:init].class.should == HashWithIndifferentAccess
              
              @grab_bag[:init].keys.should include('ingredients')
              @grab_bag[:init].keys.should include('healthometer')
              @grab_bag[:init].keys.should include('random_struct')
            end 
            
            it 'should store the more complex hash values correctly' do
              user_2 = User.new(:grab_bag => @struct) # this has already been tested in the set above
              user_2._pack[:ivars][:@grab_bag].should == @grab_bag[:init][:random_struct]
            end
          end    
        end
      end   
    end
  end
  
  describe 'committing packed objects to the store' do 
    before(:each) do 
      CouchDB.server.delete_all
    end
      
    it 'commit! should not raise errors on successful save' do
      lambda{ @user.commit! }.should_not raise_error
    end 
    
    it 'commit! should raise error on failure' do
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      lambda{ @user.commit! }.should raise_error
    end  
    
    it 'commit! should assign an id back to the object' do
      @user.commit!
      @user.id.should_not be_nil
      @user.id.should_not == @user.object_id
    end
    
    it 'commit! should assign the _rev to the parent object' do
      @user.commit!
      @user.instance_variable_get('@_rev').should_not be_nil
    end    
    
    it 'commit! should save the record to CouchDB' do
      @user.commit!  
      lambda{ CouchDB.get( "http://127.0.0.1:5984/aqua/#{@user.id}") }.should_not raise_error
    end
    
    it 'commit should save the record and return self' do 
      @user.commit.should == @user
    end
    
    it 'commit should not raise an error on falure' do 
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      lambda{ @user.commit }.should_not raise_error
    end 
    
    it 'commit should return false on failure' do
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      @user.commit.should == false
    end
    
    it 'should be able to update and commit again' do 
      @user.commit!
      @user.grab_bag = {'1' => '2'}
      lambda{ @user.commit! }.should_not raise_error
    end        
  end  
   
end  
