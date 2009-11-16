require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )
Unpacker = Aqua::Unpacker unless defined?( Unpacker ) 
Packer = Aqua::Packer unless defined?( Packer ) 

describe Unpacker do
  before(:each) do 
    build_user_ivars
    Unpacker.instance_eval "@classes = {}"
  end
    
  describe 'finding a documents class' do 
    it 'should return a class' do 
      Unpacker.get_class( 'User' ).should == User
    end
      
    it 'should cache the mapping of class name to class' do 
      Unpacker.classes.should == {}
      Unpacker.get_class( 'User' )
      Unpacker.classes.should == {'User' => User}
    end  
  end
  
  describe 'class methods should unpack' do 
    def round_trip( obj, debug=false ) 
      @pack = Packer.pack_object(obj).pack
      if debug
        puts obj.inspect 
        puts @pack.inspect
      end  
      @result = Unpacker.unpack_object(@pack)
    end
      
    it 'string' do
      round_trip( 'string' ).should == 'string'
    end
      
    it 'true' do 
      round_trip( true ).should == true
    end
      
    it 'false' do
      round_trip( false ).should == false
    end
    
    it 'nil' do
      round_trip( nil ).should == nil
    end
    
    it 'Symbols' do 
      round_trip( :symbol ).should == :symbol
    end  
          
    it 'times' do
      time = Time.now  
      round_trip( time ).to_s.should == time.to_s
    end
      
    it 'dates' do
      date = Date.today
      round_trip( date ).should == date 
    end

    it 'Fixnums' do 
      round_trip( 3 ).should == 3
    end
      
    it 'Bignums' do
      round_trip( 12345678901234567890 ).should == 12345678901234567890 
    end
      
    it 'Floats' do
      round_trip( 1.68 ).should == 1.68
    end
      
    it 'Rationals' do 
      round_trip( Rational( 1,17 ) ).should == Rational( 1,17 )
    end
    
    it 'Ranges' do 
      round_trip( (1..3) ).should == (1..3)
    end
      
    it 'arrays of string' do 
      array = ['one', 'two', 'three']
      round_trip( array ).should == array
    end
    
    it 'mixed arrays' do
      array = [1, 2, 3.4]
      round_trip( array ).should == array
    end
    
    it 'array derivatives' do 
      array_udder = ArrayUdder.new([1,2,3])
      array_udder.udder 
      array_udder.instance_variables.should_not be_empty
      unpacked = round_trip( array_udder )
      unpacked.class.should == ArrayUdder
      unpacked.should == array_udder # array values match
      unpacked.instance_variables.should_not be_empty
      unpacked.instance_variable_get('@udder').should == array_udder.instance_variable_get('@udder')
    end  
      
    it 'simple hashes' do
      hash = {'one' => 'two'} 
      round_trip( hash ).should == hash
    end
    
    it 'mixed hashes with string keys' do 
      hash = {'one' => 1} 
      round_trip( hash ).should == hash
    end  
      
    it 'hashes with object keys' do 
      hash = { 1 => 'one' }
      round_trip( hash ).should == hash
    end
      
    it 'hash derivatives' do 
      canned_hash = CannedHash.new( :one => 'one', 1 => 'one' )
      canned_hash.yum
      canned_hash.instance_variables.should_not be_empty
      unpacked = round_trip( canned_hash )
      unpacked.class.should == CannedHash
      unpacked.should == canned_hash
      unpacked.instance_variables.should_not be_empty 
      unpacked.instance_variable_get('@yum').should == canned_hash.instance_variable_get('@yum')
    end  
    
    it 'open structs' do
      struct = OpenStruct.new(:cots => 3, :beds => 'none') 
      round_trip( struct ).should == struct
    end  
  end 

  describe 'unpacking aquatic objects' do
    before(:each) do 
      @pack = Packer.pack_object( @user ).pack
    end
    
    it 'embedable objects' do 
      log = Unpacker.unpack_object( @pack['ivars']['@log'] ) 
      log.class.should == Log
      log.instance_variables.each do |ivar_name|
        log.instance_variable_get(ivar_name).to_s.should == 
          @log.instance_variable_get(ivar_name).to_s
      end  
    end
  
    describe 'external objects' do 
      before(:each) do  
        @sub_pack = @pack['ivars']['@other_user']
        @sub_pack['init']['id'] = 'other_user_id' 
        @returned_user = Unpacker.unpack_object( @sub_pack ) 
      end
        
      it 'should reconstitute as an Aqua::Stub object' do 
        @returned_user.class.should == Aqua::Stub
      end 
      
      it 'should respond to stubbed methods' do
        @returned_user.methods.should include( 'username' )
      end
      
      it 'should request the delegate object when a non-stubbed method is requested' do 
        User.should_receive(:load).with( 'other_user_id' ).and_return( @other_user )
        @returned_user.name
        @returned_user.delegate.should == @other_user
      end       
    end  
  end  
  
  describe 'unpacking file-like things' do  
    # Files have to be stored within an aquatic object, since they are handled as attachments
    # Since attachments require the base object information in order to be retrieved,
    # instance information (the base object) has to be passed in with the opts
       
    class Attachment 
      aquatic
      attr_accessor :file, :tempfile, :id
    end
    
    before(:each) do
      @file = File.new(File.dirname(__FILE__) + '/../store/couchdb/fixtures_and_data/image_attach.png')
      
      @tempfile = Tempfile.new('temp.txt')
      @tempfile.write('I am a tempfile!')
      @tempfile.rewind          
      
      @attachment = Attachment.new
      @attachment.id = 'my_base_object_id' 
      @attachment.file = @file 
      @attachment.tempfile = @tempfile
      
      @pack = Packer.pack_object( @attachment ).pack 
      @opts = Unpacker::Opts.new
      @opts.base_object = @attachment
    end  
    
    describe 'files' do
      before(:each) do
        @stub = Unpacker.unpack_object( @pack['ivars']['@file'], @opts )
      end  
      
      it 'should be reconstituted as Aqua::FileStub objects' do 
        @stub.class.should == Aqua::FileStub
      end
    
      it 'should have stubbed methods' do
        @stub.methods.should include( 'content_type', 'content_length' )
      end
      
      it 'should have a base_object' do 
        @stub.base_object.should == @attachment
      end  
      
      it 'should get retrieved when other file methods are called' do
        Attachment::Storage.should_receive(:attachment).with( 'my_base_object_id', 'image_attach.png' ).and_return( @file )
        @stub.read
        @stub.delegate.should == @file
      end  
    end    
    
    describe "tempfiles" do
      before(:each) do
        @stub = Unpacker.unpack_object( @pack['ivars']['@tempfile'], @opts )
      end  
      
      it 'should be reconstituted as Aqua::FileStub objects' do 
        @stub.class.should == Aqua::FileStub
      end
    
      it 'should have stubbed methods' do
        @stub.methods.should include( 'content_type', 'content_length' )
      end
      
      it 'should have a base_object' do 
        @stub.base_object.should == @attachment
      end  
      
      it 'should get retrieved when other file methods are called' do
        Attachment::Storage.should_receive(:attachment).with( 'my_base_object_id', 'temp.txt' ).and_return( @tempfile )
        @stub.read
      end 
    end
  end     
end  
