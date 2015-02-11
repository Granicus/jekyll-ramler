require 'deep_clone'
require 'jekyll'
require 'pry'
require 'rspec'
require 'rspec/expectations'
require_relative '../lib/jekyll-ramler.rb'


RSpec.configure do |config|
end

def pretty_json(json)
  JSON.pretty_generate(JSON.parse(json))
end

def spec_pwd
  spec_pwd = File.dirname(__FILE__)
end

def example_raml_hash
  raml_hash = {
    'title' => 'Test!',
    '/test_resource' => {
      'post' => {
        'description' => 'An example of a schema with no inheritance',
        'body' => {
          'application/x-www-form-urlencoded' => {
            'formParameters' => {
              'foo' => {
                'description' => 'Fooing',
                'type' => 'string',
                'example' => 'Foo'
              },
              'bar' => {
                'description' => 'A place to get a drink',
                'type' => 'object'
              }
            }
          }
        }
      }
    }
  }
end

def simple_schema
  pretty_json(File.read(File.join(spec_pwd, 'spec_assets/json/schema/simple_schema.schema.json')))
end

def ref_schema
  pretty_json(File.read(File.join(spec_pwd, 'spec_assets/json/schema/ref_schema.schema.json')))
end

def foo_bit
  pretty_json(File.read(File.join(spec_pwd, 'spec_assets/json/schema/foo.include.schema.json')))
end

def allOf_schema
  pretty_json(File.read(File.join(spec_pwd, 'spec_assets/json/schema/allOf_schema.schema.json')))
end

RSpec::Matchers.define :dereference do |expected_json|
    match do |referenced_json|
      !expected_json.include?('$ref') and referenced_json.all? {|k, v| expected_json[k] == v }
    end
end
