require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures
 
Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )  

describe Aqua::Unpack do
  before(:each) do
    User::Storage.database.delete_all
    build_user_ivars
    @file = File.new( File.dirname(__FILE__) + '/../store/couchdb/fixtures_and_data/image_attach.png' )
    @user.grab_bag = @file
    @user.commit!
  end 
  
  describe 'loading' do
    describe 'retreiving the storage document from the database' do
      it 'should work if the document exists' do
        document = User._get_store( @user.id )
        document.class.should == User::Storage
      end
    
      it 'should raise an error if the document does not exist' do
        lambda{ User._get_store( 'not_no_here' ) }.should raise_error
      end  
    end
    
    describe 'unpacking the document' do
      before(:each) do 
        @new_user = User.load( @user.id )
      end
      
      it 'should add the base_id to the translator' do 
        @new_user._translator.base_id.should == @user.id
      end  
        
      it 'should initiate the right kind of object' do 
        @new_user.class.should == User 
      end 
      
      it 'should have the right id' do
        @new_user.id.should == @user.id
      end 
      
      it 'should have a revision' do
        doc = User::Storage.get( @user.id )
        doc.rev.should_not be_nil
        doc.rev.should_not be_empty 
        @new_user._rev.should == doc.rev
      end  
      
      describe 'instance variables' do
        it 'should reinstantiate the simple types' do
          @new_user.created_at.class.should == Time
          @new_user.created_at.to_s.should == @time.to_s
          @new_user.dob.should == @date
          @new_user.name.should == ['Kane', 'Baccigalupi']
        end  
      
        it 'should reinstantiate embedded aquatic objects' do
          # todo: should add a method to log so that it isn't doing equality by object_id
          @new_user.log.class.should == Log
          @new_user.log.created_at.to_s.should == @log.created_at.to_s
          @new_user.log.message.should == @log.message
        end 
      
        it 'should have nil for hidden variables' do
          @new_user.password.should be_nil 
        end 
        
        describe 'that are external aquatic' do
          before(:each) do 
            @external = @new_user.other_user
          end
             
          it 'should be of class Aqua::Stub' do
            @external.class.should == Aqua::Stub
          end  
          
          it 'should respond to stubbed methods' do
            @external.methods.should include( 'username' )
          end
            
          it 'should retrieve external object when non-stubbed method is called' do 
            User.should_receive(:load).with( @other_user.id ).and_return( @other_user )
            @external.name 
            @external.delegate.should == @other_user
          end
            
          it 'should delegate non-stubbed methods to the external object' do
            @external.name.should == ['What', 'Ever']
          end  
        end  
      
        describe 'that are attachments' do
          before(:each) do 
            @attachment = @new_user.grab_bag
          end
            
          it 'should be of class Aqua::FileStub' do
            @attachment.class.should == Aqua::FileStub
          end
            
          it 'should have basic data about the file' do 
            @attachment.methods.should include( 'content_type', 'content_length' )
          end
            
          it 'should retrieve the attachment as a delegate when non-stubbed methods are called' do
            User::Storage.should_receive(:attachment).with( @new_user.id, 'image_attach.png' ).and_return( @file )
            @attachment.read
          end
            
          it 'should delegate to the loaded attachment' do
            @attachment.read.should == @file.read
          end  
        end
      end   
    end     
  end
  
  describe 'reloading' do 
    describe 'with no-initialization' do
      before(:each) do
        # dup the @user and change everything! but don't save
        @changed_user = @user.dup
        @changed_user.username = 'not kane'
        @changed_user.name = []
        @changed_user.dob = Date.parse('1/1/2001')
        @changed_user.created_at = Time.parse('1/1/2001')
        @changed_user.log = Log.new(:message => 'some other message')
        @changed_user.other_user = @user
      end 
      
      it 'should not raise an error' do  
        lambda{ @changed_user.reload }.should_not raise_error
      end  
      
      it 'should reset to saved instance variables' do 
        @changed_user.reload
        @changed_user.username.should == @user.username
        @changed_user.name.should == @user.name
        @changed_user.dob.should == @user.dob
        @changed_user.created_at.to_s.should == @user.created_at.to_s
        @changed_user.log.created_at.to_s.should == @user.log.created_at.to_s
        @changed_user.log.message.should == @user.log.message
        # since this is a stub, not the same object, lets test how it works 
        @changed_user.other_user.name.should == @user.other_user.name
      end   
    end
    
    describe 'with initialization and #replace methods' do
      class ArrayD < Array
        aquatic
        attr_accessor :bucket
      end
        
      before(:each) do
        @arrayd = ArrayD.new([1,2])
        @arrayd.bucket = 34
        @arrayd.commit!
        
        # change the instance, but don't commit
        @arrayd[0] = 'one'
        @arrayd[1] = 'two'
        @arrayd << 'and more'
        @arrayd.bucket = @arrayd.join(' ... ') 
      end
        
      it 'should not raise an error' do
        lambda{ @arrayd.reload }.should_not raise_error
      end 
      
      it 'should reset to saved initialization' do
        @arrayd.reload
        @arrayd[0].should == 1
        @arrayd[1].should == 2
        @arrayd[2].should == nil
      end  
      
      it 'should reset to saved instance variables' do
        @reloaded = @arrayd.reload 
        @reloaded.should == @arrayd
        @arrayd.bucket.should == 34
      end  
    end
    
    describe 'with initialization and no #replace methods' do 
      it 'should raise an exception' do 
        class Event < Range
          aquatic
          attr_accessor :name 
        end
        event = Event.new( Time.parse('11/19/2009'), Time.parse('11/21/2009') )
        event.name = 'RubyConf 09', 
        event.commit!
        
        lambda {event.reload}.should raise_error( NotImplementedError )  
      end  
    end     
  end         
  
end  
   
