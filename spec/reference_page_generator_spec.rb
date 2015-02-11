require_relative './spec_helper.rb'

describe 'ReferencePageGenerator', fakefs:true do
  before(:all) do
    FakeFS.activate!
    Pry.config.history.should_save = false;
    Pry.config.history.should_load = false;

    FileUtils.mkdir_p('_layouts')
    File.open('_layouts/default.html', 'w') { |f| f << "{{ content }}" }

    File.open('api.json', 'w') do |f|
      f << JSON.pretty_generate(load_simple_raml)
    end
  end

  before(:each) do
    @site = Jekyll::Site.new(Jekyll.configuration({
      "skip_config_files" => true,
      "json_schema_schema_uri" => "http://json-schema.org/draft-04/schema#"
    }))
  end

  after(:all) do
    FakeFS.deactivate!
  end

  context 'Generating Pages from RAML' do

    it 'generates a resource page for each resource in the RAML' do
      rpg = Jekyll::ReferencePageGenerator.new
      rpg.generate(@site)

      raml_hash = load_simple_raml
      passed = recursive_resource_search(raml_hash, @site)
      
      expect(passed).to be true
    end
    it 'generates an overview page for each security or documentation item in the RAML'
    it 'transforms descriptions via Markdown'
    it 'inserts trait properties into resources that have traits'
    it 'inserts security properties into resoruces that are secured'
    it 'creates downloadable RAML and JSON of the API descriptor'
  end
end
