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
      :log => @log 
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
  
  it 'aquatic objects should have packing instructions in the form of #_embed_me' do
    @user._embed_me.should == false
    Log.new._embed_me.should == true
    User.configure_aqua( :embed => {:stub =>  [:username, :name] } ) 
    @user._embed_me.should == { 'stub' => [:username, :name] }
    # reset for future tests
    User.configure_aqua( :embed => false )
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
         
        describe 'embeddable aquatic' do
          it 'should save their data correctly' do
          @pack[:data][:@log].keys.should == ['class', 'data']
          @pack[:data][:@log]['data'].keys.should == ['@created_at', '@message'] 
          @pack[:data][:@log]['data']['@message'].should == "Hello World! This is a log entry"
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
            
            it 'should store the array values' do
              @grab_bag[:initialization].should_not be_nil
            end  
                  
          end
          
          describe 'Classes inherited from Hash' do
          end    
                
        end
        
      end   
    end
    
  end
   
end  
