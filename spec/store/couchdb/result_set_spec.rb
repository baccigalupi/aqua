require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace

# Conveniences for typing with tests ... 
CouchDB =   Aqua::Store::CouchDB unless defined?( CouchDB ) 
Database =  CouchDB::Database unless defined?( Database )
Design =    CouchDB::DesignDocument unless defined?( Design )
ResultSet =    CouchDB::ResultSet unless defined?( ResultSet )

require File.dirname(__FILE__) + '/fixtures_and_data/document_fixture' # Document ... a Mash with the collection of methods
class Docintalk < Document 
  def talk 
    'Hello, I am a Docintalk'
  end  
end  

describe ResultSet do
  before(:each) do
    ResultSet.document_class = nil # resets for all theses tests
    # These are sample returns from couchdb for a view query
    # the first is when the include_document=true is omitted
    # the next is when it is included
    @no_docs = {
      "rows"=>[
        {"id"=>"b7e4623f506c437bae2b517d169b3c88", "value"=>nil, "key"=>1}, 
        {"id"=>"43d650760fdda785a3bd20056d53b3e0", "value"=>nil, "key"=>2}, 
        {"id"=>"b638586d7d71267e54af9420ee803a7c", "value"=>nil, "key"=>3}, 
        {"id"=>"c0f8a9d683fb1576dc1da943d9bf2251", "value"=>nil, "key"=>4}, 
        {"id"=>"11d12976059170f360df222bc097834c", "value"=>nil, "key"=>5}, 
        {"id"=>"d9270a9bdc7128f02c4b9ccdc10e6b18", "value"=>nil, "key"=>6}, 
        {"id"=>"c85c7d08e240c1798a7db11b0756581c", "value"=>nil, "key"=>7}, 
        {"id"=>"721ec0ec55c5d16719ae438855528575", "value"=>nil, "key"=>8}, 
        {"id"=>"13d2140c707196af4b4e53fe73a0ab0b", "value"=>nil, "key"=>9}, 
        {"id"=>"b139683cf575446edb4245eba245d907", "value"=>nil, "key"=>10}
      ], 
      "offset"=>0, 
      "total_rows"=>10
    }
    @with_docs = {
      "rows"=>[
        {"doc"=>{"_id"=>"9d749a8a532294c22ccbf16873f50ead", "_rev"=>"1-567432465", "index"=>2}, "id"=>"9d749a8a532294c22ccbf16873f50ead", "value"=>nil, "key"=>1}, 
        {"doc"=>{"_id"=>"b1394da1469eae862cca661da238b951", "_rev"=>"1-2128259075", "index"=>3}, "id"=>"b1394da1469eae862cca661da238b951", "value"=>nil, "key"=>2}, 
        {"doc"=>{"_id"=>"a1b7b978b20649cb5fd648cd510e0243", "_rev"=>"1-3326711422", "index"=>4}, "id"=>"a1b7b978b20649cb5fd648cd510e0243", "value"=>nil, "key"=>3}, 
        {"doc"=>{"_id"=>"92b69da432d658da6dc69a5c611065ca", "_rev"=>"1-2590331142", "index"=>5}, "id"=>"92b69da432d658da6dc69a5c611065ca", "value"=>nil, "key"=>4}, 
        {"doc"=>{"_id"=>"f3b257b6d9bc60062147db98175a809b", "_rev"=>"1-2121844908", "index"=>6}, "id"=>"f3b257b6d9bc60062147db98175a809b", "value"=>nil, "key"=>5}, 
       ], 
       "offset"=>1, 
       "total_rows"=>5
     }
     @docless = ResultSet.new( @no_docs )
     @docfull = ResultSet.new( @with_docs )     
  end
  
  it 'should have a default document class accessor' do
    ResultSet.should respond_to(:document_class)
    ResultSet.should respond_to(:document_class=)
  end    
  
  it 'should have an offset' do
    @docless.offset.should == 0
    @docfull.offset.should == 1
  end 
   
  it 'should have a total' do 
    @docless.total.should == 10
    @docfull.total.should == 5
  end
    
  it 'should have rows' do
    @docless.rows.should == @no_docs['rows']
    @docfull.rows.should == @with_docs['rows']
  end
  
  it 'keys should be the array accessible content of the set when docs are not included' do
    @docless.first.should == @no_docs['rows'].first['key']
  end  
  
  it 'docs should be the array accessible content of the set, when available' do
    @docfull.first.should == @with_docs['rows'].first['doc']
  end
  
  it 'it should convert docs to the default document class if no instance level document class is available' do 
    ResultSet.document_class = Document
    docs = ResultSet.new( @with_docs )
    docs.first.class.should == Document
  end
  
  it 'should use instance level document class when available' do
    docs = ResultSet.new( @with_docs, Docintalk )
    docs.document_class.should == Docintalk
    docs.first.class.should == Docintalk
  end      
    
end