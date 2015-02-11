require_relative './spec_helper.rb'

describe 'Utils' do
  context 'RAML Schema Generator' do

    before(:each) do 
      @raml_hash = example_raml_hash
      @site = Jekyll::Site.new(Jekyll.configuration({
        "skip_config_files" => true,
        "json_schema_schema_uri" => "http://json-schema.org/draft-04/schema#"
      }))
      @rsg = Jekyll::RamlSchemaGenerator.new(@site, 'Simple Schema')
    end
    context '.generate_json_schema' do
      it 'creates a JSON Schema string that includes all properties from application/x-www-form-urlencoded:formParameters' do
        json_schema = JSON.parse(@rsg.generate_json_schema(@raml_hash['/test_resource']['post']) )
        expect(json_schema['properties']).to eq(JSON.parse(simple_schema)['properties'])
      end

      it 'creates a JSON Schema with a required attribute if application/x-www-form-urlencoded:formParameters includes a required parameter' do
        @raml_hash['/test_resource']['post']['body']['application/x-www-form-urlencoded']['formParameters']['bar']['required'] = true
        json_schema = JSON.parse(@rsg.generate_json_schema(@raml_hash['/test_resource']['post']))
        expect(json_schema).to include('required')
        expect(json_schema['required']).to include('bar')
        expect(json_schema['properties']).to eq(JSON.parse(simple_schema)['properties'])

      end

      it 'throws an error if provided RAML does not include body:application/x-www-form-urlencoded:formParameters' do
        body = @raml_hash['/test_resource']['post'].delete('body')
        expect{@rsg.generate_json_schema(@raml_hash)}.to raise_error(NoMethodError)
        @raml_hash['/test_resource']['post']['body'] = body
        form = @raml_hash['/test_resource']['post']['body'].delete('application/x-www-form-urlencoded')
        expect{@rsg.generate_json_schema(@raml_hash)}.to raise_error
        @raml_hash['/test_resource']['post']['body']['application/x-www-form-urlencoded'] = form 
        formParameters = @raml_hash['/test_resource']['post']['body']['application/x-www-form-urlencoded'].delete('formParameters') 
        expect{@rsg.generate_json_schema(@raml_hash)}.to raise_error
      end
    end

    context '.insert_json_schema' do
      it 'inserts an appropriate string into application/json:schema' do
        @raml_hash['/test_resource']['post']['body']['application/json'] = {}
        orig_raml_hash = DeepClone.clone @raml_hash

        json_schema = @rsg.generate_json_schema(@raml_hash['/test_resource']['post'])
        @rsg.insert_json_schema(@raml_hash['/test_resource']['post'], json_schema)

        expect(@raml_hash['/test_resource']['post']['body']['application/json']).to include('schema')
        expect(@raml_hash['/test_resource']['post']['body']['application/json']['schema']).to eq(json_schema)
        @raml_hash['/test_resource']['post']['body']['application/json'].delete('schema')
        expect(@raml_hash).to eq(orig_raml_hash)
      end

      it 'throws an error if provided object does not have expected properties' do
        expect{@rsg.insert_json_schema(@raml_hash, 'foobar')}.to raise_error
      end
    end

    context '.insert_schemas' do
      it 'inserts an appropriate JSON Schema string in application/json:schema' do
        @raml_hash['/test_resource']['post']['body']['application/json'] = {}
        orig_raml_hash = DeepClone.clone @raml_hash
        @raml_hash = @rsg.insert_schemas(@raml_hash)
        expect(@raml_hash['/test_resource']['post']['body']['application/json']).to include('schema')
        expect(@raml_hash['/test_resource']['post']['body']['application/json']['schema']).to eq(pretty_json(simple_schema))

        @raml_hash['/test_resource']['post']['body']['application/json'].delete('schema')
        expect(@raml_hash).to eq(orig_raml_hash)
      end

      it 'does nothing if application/json:schema already exists' do
        orig_schema = 'foobar'
        @raml_hash['/test_resource']['post']['body']['application/json'] = { 'schema' => orig_schema }
        orig_raml_hash = DeepClone.clone @raml_hash
        @rsg.insert_schemas(@raml_hash) 

        expect(@raml_hash).to eq(orig_raml_hash)
        expect(@raml_hash['/test_resource']['post']['body']['application/json']['schema']).to eq(orig_schema)
      end

      it 'does nothing if there is no application/x-www-form-urlencoded:formParameters' do
        @raml_hash['/test_resource']['post']['body']['application/x-www-form-urlencoded'].delete('formParameters')
        orig_raml_hash = DeepClone.clone @raml_hash
        @rsg.insert_schemas(@raml_hash) 

        expect(@raml_hash).to eq(orig_raml_hash)
      end
    end
  end
end
