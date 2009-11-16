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
    
    it 'files' do
      # Files have to be stored within an aquatic object right now
      file = File.new(File.dirname(__FILE__) + '/../store/couchdb/fixtures_and_data/image_attach.png')
      round_trip( file, true ).first.read.should == file.read
    end
    
    it 'tempfiles' do 
    pending 
    end  
    
    it 'sets' do 
    pending 
    end 
    
    it 'embedable objects' do 
    pending 
    end
    
    it 'external objects'
      
  end    
end  
