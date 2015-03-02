require 'deep_clone'
require 'fakefs/spec_helpers'
require 'jekyll'
require 'pry'
require 'rspec/expectations'
require 'rspec/mocks'
require_relative '../lib/jekyll-ramler.rb'


RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs:true
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
    'resources' => {
      '/test_resource' => {
        'post' => {
          'description' => 'An example of a schema with no inheritance',
          'body' => {
            'application/x-www-form-urlencoded' => {
              'formParameters' => {
                'foo' => {
                  'displayName' => 'foo',
                  'description' => 'Fooing',
                  'type' => 'string',
                  'example' => 'Foo'
                },
                'bar' => {
                  'displayName' => 'bar',
                  'description' => 'A place to get a drink',
                  'type' => 'object'
                }
              }
            }
          }
        }
      }
    }
  }
end

def load_simple_raml
  JSON.parse(`raml-cop #{File.join(spec_pwd, 'spec_assets/raml/simple.raml')} -j`)
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

def recursive_resource_search(raml_hash, site, parent='')
  passed = raml_hash['resources'].all? do |resource_hash|
    site.pages.any? do |page|
      page.data['title'] == "#{parent}#{resource_hash['relativeUri']}"
    end
  end

  if passed
    raml_hash['resources'].each do |resource_hash|
      if resource_hash.include?('resources')
        passed = recursive_resource_search(resource_hash, site, resource_hash['relativeUri'])
      end
    end
  end

  passed
end

def documentation_search(raml_hash, site)
  raml_hash['documentation'].all? do |resource_hash|
    site.pages.any? do |page|
      page.data['title'] == resource_hash['title']
    end
  end
end

def security_search(raml_hash, site)
  raml_hash['securitySchemes'].all? do |security_hash|
    security_hash.all? do |name, hash|
      site.pages.any? do |page|
        page.data['title'] == name  
      end
    end
  end
end

RSpec::Matchers.define :dereference do |expected_json|
    match do |referenced_json|
      !expected_json.include?('$ref') and referenced_json.all? {|k, v| expected_json[k] == v }
    end
end
