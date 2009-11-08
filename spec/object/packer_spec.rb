require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )
Packer = Aqua::Packer unless defined?( Packer )

describe Packer do
  describe 'instances' do
    it 'should be itialized with the base object' do   
      pending
      @user._packer.base.should == @user
    end
    it 'should have externals'
    it 'should have attachments' 
  end  
  
  def pack( obj )
    Packer.pack_object( obj )
  end  
  
  describe 'class methods should pack' do
    it 'string' do 
      pack('string').should == ["string", [], []]
    end
      
    it 'times' do 
      time = Time.parse("12/23/69")
      pack(time).should == [{"class" => "Time", "init" => time.to_s}, [], []]
    end
      
    it 'dates' do 
      date = Date.parse("12/23/69")
      pack(date).should == [{"class" => "Date", "init" => date.to_s}, [], []]
    end
      
    it 'true' do 
      pack( true ).should == [true, [], []]
    end
      
    it 'false' do
      pack( false ).should == [false, [], []]
    end
    
    it 'Symbols' do 
      pack( :symbol ).should == [{"class" => "Symbol", "init" => "symbol"}, [], []]
    end  
     
    it 'Fixnums' do
      pack( 1234 ).should == [{"class" => "Fixnum", 'init' => '1234'}, [], []]
    end
      
    it 'Bignums' do
      pack( 12345678901234567890 ).should == [
       { "class" => 'Bignum', 'init' => '12345678901234567890' }, 
      [],[]]
    end
      
    it 'Floats' do
      pack( 1.681 ).should == [
       { "class" => 'Float', 'init' => '1.681' }, 
      [],[]] 
    end
      
    it 'Rationals' do
      pack( Rational( 1, 17 ) ).should == [
       { "class" => 'Rational', 'init' => ['1','17'] }, 
      [],[]]
    end
    
    it 'stubs' do
      user = User.new(:username => 'Kane') 
      p = pack( user )
      p.should == [
       {"class" => "Aqua::Stub", "init"=>{ "methods"=>{"username"=>"Kane"}, "class"=>"User", "id"=>nil}}, 
      [user],[]]  
      puts p.inspect
    end  
      
    it 'arrays of string' do 
      pack( ['one', 'two'] ).should == [ 
        {"class" => 'Array', 'init' => ['one', 'two'] },
      [],[]]
    end
    
    it 'mixed arrays' do
      pack( [1, :two] ).should == [ 
        {"class" => 'Array', 'init' => [{"class"=>"Fixnum", "init"=>"1"}, {"class"=>"Symbol", "init"=>"two"} ]},
      [],[]]
    end  
    
    it 'arrays with externals' do 
      pending
    end  
    
    it 'arrays with attachments'
      
    it 'array derivatives'
    it 'hashes'
    it 'hashes with object keys'
    it 'structs'
    it 'ranges'
    it 'sets'
  end   
end   