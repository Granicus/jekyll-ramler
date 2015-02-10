require 'deep_clone'
require 'jekyll'
require 'rspec'
require 'rspec/expectations'
require_relative '../lib/jekyll-ramler.rb'

RSpec.configure do |config|
end

def pretty_json(json)
  JSON.pretty_generate(JSON.parse(json))
end

RSpec::Matchers.define :dereference do |expected_json|
    match do |referenced_json|
      !expected_json.include?('$ref') and referenced_json.all? {|k, v| expected_json[k] == v }
    end
end
