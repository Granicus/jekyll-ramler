require_relative './spec_helper.rb'

describe 'ReferencePageGenerator', fakefs:true do

  before(:each) do
    @site = Jekyll::Site.new(Jekyll.configuration({
      "skip_config_files" => true,
      "json_schema_schema_uri" => "http://json-schema.org/draft-04/schema#",
      "ramler_api_paths" => {
        'api.json' => '',
        '/productA/api.json' => '/productA/',
        'service.json' => '/'}
    }))
    @rpg = Jekyll::ReferencePageGenerator.new

    FakeFS.activate!
    Pry.config.history.should_save = false;
    Pry.config.history.should_load = false;

    FileUtils.mkdir_p('_layouts')
    File.open('_layouts/default.html', 'w') { |f| f << "{{ content }}" }

    File.open('api.json', 'w') do |f|
      f << JSON.pretty_generate(load_simple_raml)
    end

    FileUtils.mkdir_p('productA')
    File.open('productA/api.json', 'w') do |f|
      f << JSON.pretty_generate(load_simple_raml)
    end

    File.open('service.json', 'w') do |f|
      f << JSON.pretty_generate(load_simple_raml)
    end
  end

  after(:each) do
    FakeFS.deactivate!
  end

  context 'Configuration' do

    it 'reads ramls listed in the ramler_api_paths configuration mapping' do
      expect(File).to receive(:open).with('api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      expect(File).to receive(:open).with('/productA/api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      expect(File).to receive(:open).with('service.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      @rpg.generate(@site)
    end

    it 'places generated content into folders based on the ramler_api_paths configuration mapping'
    it 'defaults to web root for any unconfigured ramls'
    it 'throws an error if ramler_api_paths includes a value without a trailing slash'
    it 'defaults to "resource", "overview", and "security" for generated folders'
    it 'places generated content into folders based oon ramler_generated_sub_dirs configuration mapping'
  end
end
