require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

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
    @pack = @user._pack
  end
  
  describe 'packing classes' do 
    it 'should pack class variables'
    it 'should pack class level instance variables'
    it 'should pack class definition'
    it 'should save all the class details to the design document'
    it 'should package views/finds in the class and save them to the design document\'s view attribute'
    it 'should be saved into the design document' 
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
  end    
  
  describe 'packing up object instances:' do
    it 'should save its class name as an attribute on the pack document' do
      @pack[:class].should == 'User'
    end
    
    describe 'instance variables, ' do
      it 'should be in a hash-like object with the key :data' do 
        @pack[:data].should_not be_nil
        @pack[:data].should respond_to(:keys)
      end 
      
      describe 'basic data types' do
        it 'should pack strings as strings' do 
          @pack[:data][:@username].should == 'kane'
        end  
    
        it 'should pack an array of strings as a hash with the :class "Array" and :initialization as the original array' do
          @pack[:data][:@name].should == {'class' => 'Array', 'initialization' => ['Kane', 'Baccigalupi']}
        end  
    
        it 'should pack an hash containing only strings/symbols for keys and values, with an initialization value that is that hash and a class key' do
          @user.name = {:first => 'Kane', :last => 'Baccigalupi'}
          pack = @user._pack
          pack[:data][:@name].should == {'class' => 'Hash', 'initialization' => {'first' => 'Kane', 'last' => 'Baccigalupi'} }
        end   
      end
      
      describe 'objects: ' do
        # TODO: http://www.ruby-doc.org/core/
        # make sure all the basic types work 
        
        describe 'Time' do
          it 'should save as a hash with the class and to_s as the value' do
            time_hash = @pack[:data][:@created_at] 
            time_hash['class'].should == 'Time'
            time_hash['data'].class.should == String
          end
        
          it 'the value should be reconstitutable with Time.parse' do 
            # comparing times directly never works for me. It is probably a micro second issue or something
            @time.to_s.should == Time.parse( @pack[:data][:@created_at]['data'] ).to_s
          end 
        end
        
        describe 'true and false' do
          it 'should save as a hash with only the class' do 
            @user.grab_bag = true
            pack = @user._pack
            pack[:data][:@grab_bag].should == {'class' => 'TrueClass'}
            
            @user.grab_bag = false
            pack = @user._pack
            pack[:data][:@grab_bag].should == {'class' => 'FalseClass'}
          end  
        end    
        
        describe 'Date' do
          it 'should save as a hash with the class and to_s as the value' do
            time_hash = @pack[:data][:@dob] 
            time_hash['class'].should == 'Date'
            time_hash['data'].class.should == String
          end
        
          it 'the value should be reconstitutable with Date.parse' do 
            @date.should == Date.parse( @pack[:data][:@dob]['data'] )
          end 
        end      
        
        describe 'Numbers' do
          def pack_grab_bag( value )
            @user.grab_bag = value
            @user._pack[:data][:@grab_bag]
          end 
          
          it 'should pack Fixnums with correct class and value' do 
            pack = pack_grab_bag( 42 )
            pack[:class].should == 'Fixnum'
            pack[:data].should == '42'
          end
          
          it 'should pack Bignums with correct class and value' do 
            pack = pack_grab_bag( 123456789123456789 )
            pack[:class].should == 'Bignum'
            pack[:data].should == '123456789123456789'
          end 
          
          it 'should pack Floats with correct class and value' do 
            pack = pack_grab_bag( 3.2 )
            pack[:class].should == 'Float'
            pack[:data].should == '3.2'
          end 
          
          it 'should pack Rationals with the correct class and values' do
            pack = pack_grab_bag( Rational( 1, 17 ) )
            pack[:class].should == 'Rational'
            pack[:data].should == ['1', '17']
          end    
          
        end  
         
        describe 'embeddable aquatic' do
          it 'aquatic objects should have packing instructions in the form of #_embed_me' do
            @user._embed_me.should == false
            Log.new._embed_me.should == true
            User.configure_aqua( :embed => {:stub =>  [:username, :name] } ) 
            @user._embed_me.should == { 'stub' => [:username, :name] }
            # reset for future tests
            User.configure_aqua( :embed => false )
          end   
  
          it 'should save their data correctly' do
            @pack[:data][:@log].keys.should == ['class', 'data']
            @pack[:data][:@log]['data'].keys.should == ['@created_at', '@message'] 
            @pack[:data][:@log]['data']['@message'].should == "Hello World! This is a log entry"
          end 
        
          it 'should correctly pack Array derivatives' do 
            class Arrayed < Array
              aquatic
              attr_accessor :my_accessor
            end
            arrayish = Arrayed['a', 'b', 'c', 'd']
            arrayish.my_accessor = 'Newt'
            pack = arrayish._pack
            pack.keys.sort.should == ['class', 'data', 'initialization']
            pack['initialization'].class.should == Array
            pack['initialization'].should == ['a', 'b', 'c', 'd']
            pack['data']['@my_accessor'].should == 'Newt'   
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
            pack.keys.sort.should == ['class', 'data', 'initialization']
            pack['initialization'].class.should == HashWithIndifferentAccess
            pack['initialization'].should == {'1' => '2'}
            pack['data']['@my_accessor'].should == 'Newt'
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
              @grab_bag = pack[:data][:@grab_bag]
            end
              
            it 'the key "class" should map to "OpenStruct"' do
              @grab_bag['class'].should == 'OpenStruct'
            end
            
            it 'the key "data" should have the keys "@table"' do
              @grab_bag['data'].keys.should == ['@table'] 
            end
            
            it 'the @table variable should describe the data input' do  
              meta_keys = @grab_bag['data']['@table'].keys
              # metadata
              meta_keys.should include('class')
              meta_keys.should include('initialization')
              # actual hash representation of the data 
              initialization_keys = @grab_bag['data']['@table']['initialization'].keys
              initialization_keys.should include('cat')
              initialization_keys.should include('disaster')
              initialization_keys.should include('gerbil')
              @grab_bag['data']['@table']['initialization']['gerbil'].should == {'class' => 'TrueClass'}
              @grab_bag['data']['@table']['initialization']['cat'].should == 'yup, that too!'
              @grab_bag['data']['@table']['initialization']['disaster'].should == {'class' => 'Array', 'initialization' => ['pow', 'blame', 'chase', 'spew']}
            end
          end
          
          describe 'Uninherited classes with deep nesting' do
            before(:each) do
              @user.grab_bag = @grounded
              pack = @user._pack
              @grab_bag = pack[:data][:@grab_bag]
            end
            
            it 'the key "class" should map correctly to the class name' do
              @grab_bag['class'].should == 'Grounded'
            end
            
            it 'should have data keys for all the ivars' do
              keys = @grab_bag[:data].keys
              keys.should include('@openly_structured')
              keys.should include('@hash_up')
              keys.should include('@arraynged')
            end  
            
            it 'should correctly display the nested OpenStruct' do 
              user_2 = User.new(:grab_bag => @struct) # this has already been tested in the set above
              user_2._pack[:data][:@grab_bag].should == @grab_bag[:data][:@openly_structured]
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
              @grab_bag = pack[:data][:@grab_bag]
            end
            
            it 'should correctly map the class name' do
              @grab_bag[:class].should == 'ArrayUdder'
            end
            
            it 'should store the instance variables' do 
              @grab_bag[:data].keys.should == ['@udder'] 
            end
            
            it 'should store the simple array values' do
              @grab_bag[:initialization].should_not be_nil
              @grab_bag[:initialization].class.should == Array
              @grab_bag[:initialization].should include('cat')
              @grab_bag[:initialization].should include('octopus')
            end 
            
            it 'should store the more complex array values correctly' do
              user_2 = User.new(:grab_bag => @struct) # this has already been tested in the set above
              user_2._pack[:data][:@grab_bag].should == @grab_bag[:initialization].last
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
              @grab_bag = pack[:data][:@grab_bag]
            end
            
            it 'should correctly map the class name' do
              @grab_bag[:class].should == 'CannedHash'
            end
            
            it 'should store the instance variables' do 
              @grab_bag[:data].keys.should == ['@yum'] 
            end
            
            it 'should store the simple hash values' do
              @grab_bag[:initialization].should_not be_nil
              @grab_bag[:initialization].class.should == HashWithIndifferentAccess
              
              @grab_bag[:initialization].keys.should include('ingredients')
              @grab_bag[:initialization].keys.should include('healthometer')
              @grab_bag[:initialization].keys.should include('random_struct')
            end 
            
            it 'should store the more complex hash values correctly' do
              user_2 = User.new(:grab_bag => @struct) # this has already been tested in the set above
              user_2._pack[:data][:@grab_bag].should == @grab_bag[:initialization][:random_struct]
            end
          end    
                
        end
        
      end   
    
    
    end
    
  end
   
end  
