require_relative './spec_helper.rb'

describe 'ReferencePageGenerator', fakefs:true do

  before(:each) do
    @site = Jekyll::Site.new(Jekyll.configuration({
      "skip_config_files" => true,
      "json_schema_schema_uri" => "http://json-schema.org/draft-04/schema#",
      "ramler_api_paths" => {
        'api.json' => '',
        'productA/api.json' => '/productA/',
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

    it 'reads "api.json" if no ramler_api_paths is provided' do
      @site.config.delete('ramler_api_paths')
      expect(File).to receive(:open).with('api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      @rpg.generate(@site)
    end

    it 'reads ramls listed in the ramler_api_paths configuration mapping' do
      expect(File).to receive(:open).with('api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      expect(File).to receive(:open).with('productA/api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      expect(File).to receive(:open).with('service.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      @rpg.generate(@site)
    end

    it 'places generated content into folders based on the ramler_api_paths configuration mapping' do
      # Relying on some default values in this test
        
      @site.config['ramler_api_paths'].delete('api.json')
      @rpg.generate(@site)
      @site.process

      # Look for files generated from service.json
      expect(File.file?('_site/api.raml')).to be true
      expect(File.directory?('_site/resource')).to be true

      # Look for files generated from 
      expect(File.directory?('_site/productA')).to be true
      expect(File.file?('_site/productA/api.raml')).to be true
      expect(File.directory?('_site/productA/resource')).to be true
    end

    it 'defaults to web root for any unconfigured ramls' do
      # Only generate content for api.json, which does not define a web root
      @site.config['ramler_api_paths'].delete('/productA/api.json')
      @site.config['ramler_api_paths'].delete('service.json')
      @rpg.generate(@site)
      @site.process

      expect(File.file?('_site/api.raml')).to be true
      expect(File.directory?('_site/resource')).to be true
    end

    it 'throws an error if ramler_api_paths includes a value without a trailing slash' do
      @site.config['ramler_api_paths'].delete('/productA/api.json')
      @site.config['ramler_api_paths'].delete('service.json')
      @site.config['ramler_api_paths']['api.json'] = 'api/v1'
      expect {@rpg.generate(@site)}.to raise_error 
    end

    it 'defaults to "resource", "overview", and "security" for generated folders' do
      @site.config['ramler_api_paths'].delete('/productA/api.json')
      @site.config['ramler_api_paths'].delete('service.json')
      @rpg.generate(@site)
      @site.process

      expect(File.directory?('_site/resource')).to be true
      expect(File.directory?('_site/overview')).to be true
      expect(File.directory?('_site/security')).to be true
    end

    it 'places generated content into folders based on ramler_generated_sub_dirs configuration mapping' do
      @site.config['ramler_generated_sub_dirs'] = {
        'resource' => 'endpoints',
        'overview' => 'info',
        'security' => 'auth'
      }
      @rpg.generate(@site)
      @site.process

      expect(File.directory?('_site/endpoints')).to be true
      expect(File.directory?('_site/info')).to be true
      expect(File.directory?('_site/auth')).to be true

      expect(File.directory?('_site/productA/endpoints')).to be true
      expect(File.directory?('_site/productA/info')).to be true
      expect(File.directory?('_site/productA/auth')).to be true
    end

    it 'names downloadable descriptors "api.raml" and "api.json" by default' do
      @site.config['ramler_api_paths'].delete('service.json')
      @rpg.generate(@site)
      @site.process

      expect(File.file?('_site/api.json')).to be true
      expect(File.file?('_site/api.raml')).to be true
      expect(File.file?('_site/productA/api.json')).to be true
      expect(File.file?('_site/productA/api.raml')).to be true
    end

    it 'names downloadable descriptors based on ramler_downloadable_descriptor_basenames' do
      @site.config['ramler_api_paths'].delete('service.json')
      @site.config['ramler_downloadable_descriptor_basenames'] = {
        'productA/api.json' => 'productA_api'
      }
      @rpg.generate(@site)
      @site.process

      expect(File.file?('_site/api.json')).to be true
      expect(File.file?('_site/api.raml')).to be true
      expect(File.file?('_site/productA/productA_api.json')).to be true
      expect(File.file?('_site/productA/productA_api.raml')).to be true
    end
  end
end
