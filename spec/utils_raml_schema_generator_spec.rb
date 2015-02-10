require_relative './spec_helper.rb'

spec_pwd = File.dirname(__FILE__)

describe 'Utils' do
  context 'RAML Schema Generator' do

    context '.generate_json_schema' do
      it 'creates a JSON Schema string that includes all properties from ' 
    end

    context '.insert_json_schema' do
      it 'inserts a string into application/json:schema'
    end

    context '.insert_schema' do
      it 'inserts an appropriate JSON Schema string in application/json:schema'
      it 'does nothing if application/json:schema already exists'
      it 'does nothing if there is no application/x-www-form-urlencoded:formParameters'
    end
  end
end
