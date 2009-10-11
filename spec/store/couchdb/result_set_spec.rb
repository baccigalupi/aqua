require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace

# Conveniences for typing with tests ... 
CouchDB =   Aqua::Store::CouchDB unless defined?( CouchDB ) 
Database =  CouchDB::Database unless defined?( Database )
Design =    CouchDB::DesignDocument unless defined?( Design )

require File.dirname(__FILE__) + '/fixtures_and_data/document_fixture' # Document ... a Mash with the collection of methods

describe CouchDB::ResultSet do
  describe 'initialization' do
  end   
end