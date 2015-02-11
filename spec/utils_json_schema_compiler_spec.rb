require_relative './spec_helper.rb'

describe 'Utils' do
  context 'JSON Schema Compiler' do

    before(:each) do
      @jsc = Jekyll::JsonSchemaCompiler.new
      @raml_hash = example_raml_hash
    end

    it 'does not modify an object that does not include a schema item for application/json' do
      orig_raml_hash = DeepClone.clone @raml_hash
      @raml_hash = @jsc.compile(@raml_hash)
      expect(@raml_hash).to eq orig_raml_hash
      
      @raml_hash['/test_resource']['post']['body']['application/json'] = {
        'example' => "{ 'bar' => {} }"
      }
      orig_raml_hash = DeepClone.clone @raml_hash
      @raml_hash = @jsc.compile(@raml_hash)
      expect(@raml_hash).to eq orig_raml_hash 
    end

    it 'does not modify an object with a schema item for application/json that does not include $ref or allOf' do
      @raml_hash['/test_resource']['post']['body']['application/json'] = {
        'schema' => simple_schema
      }
      orig_raml_hash = DeepClone.clone @raml_hash
      @raml_hash = @jsc.compile(@raml_hash)
      expect(@raml_hash).to eq orig_raml_hash
    end


    it 'replaces $ref items in application/json schema with the referred to content' do
      @raml_hash['/test_resource']['post']['body']['application/json'] = {
        'schema' => ref_schema
      }
      orig_raml_hash = DeepClone.clone @raml_hash

      @raml_hash = @jsc.compile(@raml_hash)
      orig_schema = orig_raml_hash['/test_resource']['post']['body']['application/json'].delete('schema')
      orig_schema = JSON.parse(orig_schema)
      new_schema = @raml_hash['/test_resource']['post']['body']['application/json'].delete('schema')
      new_schema = JSON.parse(new_schema)

      # The rest of the raml object should be identical
      expect(@raml_hash).to eq(orig_raml_hash)

      # Compiled, new_schema should include referred to properties
      referenced_json = JSON.parse(foo_bit)
      expect(new_schema['properties']).to dereference(referenced_json)

      # The rest of the schema should be unchanged
      referenced_json.each { |k, v| new_schema['properties'].delete(k) }
      orig_schema['properties'].delete('$ref')
      expect(new_schema).to eq(orig_schema)
      
    end

    it 'merges allOf items into the parent object in application/json schema items' do
      @raml_hash['/test_resource']['post']['body']['application/json'] = {
        'schema' => allOf_schema
      }
      orig_raml_hash = DeepClone.clone @raml_hash

      @raml_hash = @jsc.compile(@raml_hash)
      orig_schema = orig_raml_hash['/test_resource']['post']['body']['application/json'].delete('schema')
      orig_schema = JSON.parse(orig_schema)
      new_schema = @raml_hash['/test_resource']['post']['body']['application/json'].delete('schema')
      new_schema = JSON.parse(new_schema)

      # The rest of the raml object should be identical
      expect(@raml_hash).to eq(orig_raml_hash)

      # Compiled, new_schema should have merged all of the allOf items
      # allOf_schema properties *should* compile to be equal to *simple_schema* properties
      expect(new_schema).not_to include('allOf')
      expect(new_schema['properties']).to eq(JSON.parse(simple_schema)['properties'])

      # The rest of the schema should be unchanged
      orig_schema.delete('properties')
      orig_schema.delete('allOf')
      new_schema.delete('properties')
      expect(new_schema).to eq(orig_schema)
    end
  end
end
