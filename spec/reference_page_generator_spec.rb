require_relative './spec_helper.rb'

describe 'ReferencePageGenerator', fakefs:true do

  before(:each) do
    @site = Jekyll::Site.new(Jekyll.configuration({
      "skip_config_files" => true,
      "json_schema_schema_uri" => "http://json-schema.org/draft-04/schema#"
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

  end

  after(:each) do
    FakeFS.deactivate!
  end

  context 'Generating Pages from RAML' do

    it 'generates a resource page for each resource in the RAML' do
      @rpg.generate(@site)

      raml_hash = load_simple_raml
      passed = recursive_resource_search(raml_hash, @site)
      
      expect(passed).to be true
    end

    it 'generates an overview page for each security or documentation item in the RAML' do
      @rpg.generate(@site)
      raml_hash = load_simple_raml

      passed = documentation_search(raml_hash, @site)
      expect(passed).to be true


      passed = security_search(raml_hash, @site)
      expect(passed).to be true

    end

    it 'transforms descriptions via Markdown' do 
      @rpg.generate(@site)
      super_security = @site.pages.select {|p| p.data['title'] == 'Super Security'}.first

      expect(super_security.data['description']).to match /<p>.*<\/p>/m
      expect(super_security.data['description']).to include "<em>secured</em>"

      test_doc = @site.pages.select {|p| p.data['title'] == 'Some Test Content'}.first
      expect(test_doc.data['body']).to match /<p>.*<\/p>\n\n<h1.*>.*<\/h1>\n\n<p>.*<\/p>/m
      expect(test_doc.data['body']).to include "<strong>Hello</strong>"
      
      test_resource = @site.pages.select {|p| p.data['title'] == '/test_resource'}.first
      test_post = test_resource.data['methods'].select {|r| r['method'] == 'post' }.first
      test_post['body']['application/x-www-form-urlencoded']['formParameters'].each do |param|
        expect(param[1]['description']).to match /<p>.*<\/p>/m
      end
    end

    it 'inserts trait properties into resources that have traits' do
      @rpg.generate(@site)

      test_resource = @site.pages.select {|p| p.data['title'] == '/test_resource'}.first
      test_post = test_resource.data['methods'].select {|r| r['method'] == 'post' }.first
      expect(test_post['responses']).to include "418"
      expect(test_post['responses']['418']['body']['application/json']['example']).to include "I'm a teapot"

      # Should not insert a traits properties into pages that do not have that trait
      @site.pages.delete(test_resource)
      @site.pages.each do |page|
        expect(page.data.to_s).not_to include "418"
      end

    end

    it 'inserts security properties into resoruces that are secured' do
      @rpg.generate(@site)

      test_resource = @site.pages.select {|p| p.data['title'] == '/test_resource'}.first
      test_post = test_resource.data['methods'].select {|r| r['method'] == 'post' }.first

      expect(test_post['responses']).to include "401"
      expect(test_post['responses']['401']['body']['application/json']['example']).to include "Whatcha doin' here?"
      expect(test_post).to include "queryParameters"
      expect(test_post['queryParameters']).to include "auth"
      expect(test_post).to include "headers"
      expect(test_post['headers']).to include "X-SUPER-SECURE"
      expect(test_post['headers']['X-SUPER-SECURE']).to include "displayName"
      expect(test_post['headers']['X-SUPER-SECURE']).to include "type"
      expect(test_post['headers']['X-SUPER-SECURE']).to include "description"
      expect(test_post['headers']['X-SUPER-SECURE']).to include "required"


      # Should not insert security properties into pages that are not secured
      @site.pages.delete(test_resource)
      @site.pages.each do |page|
        expect(page.data.to_s).not_to include "401"
      end

    end

    it 'creates downloadable RAML and JSON of the API descriptor' do
      @rpg.generate(@site)
      @site.process
      expect(File.file?(File.join('_site', 'api', 'api.raml'))).to be true
      api_raml = File.read(File.join('_site', 'api', 'api.raml'))
      expect(api_raml).to start_with "#%RAML 0.8"

      expect(File.file?(File.join('_site', 'api.json'))).to be true
      api_json = File.read(File.join('_site', 'api.json')) 
      expect{JSON.parse(api_json)}.not_to raise_error 
    end
  end
end
