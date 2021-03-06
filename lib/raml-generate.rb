require 'json'

module Jekyll
  class RawFile<StaticFile
    def initialize(site, base, dir, name, content)
      @content = content
      super(site, base, dir, name)
    end

    def write(dest)
      dest_path = File.join(dest, @dir, @name)
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.open(dest_path, 'w') do |f|
        f.write(@content)
      end
    end
  end

  class GeneratedPage<Page
    def initialize(site, base, web_root, dir, item, layout=nil)
      @site = site
      @base = base
      @dir = dir.gsub(/{(\w*)}/, '--\1--').gsub(/\s/, '_')
      @dir = File.join(web_root, @dir)
      @name = 'index.html'
      
      layout = get_layout("#{web_root}#{dir}") if layout.nil?
      layout = "#{layout}.html" if not layout.end_with?('.html')

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), layout)

      self.data['title'] = "#{item['title']}"
      if item.include?('description')
        self.data['description'] = transform_md(item['description'])
      end
    end

    private
      def transform_md(output)
        # Use the existing Jekyll Markdown converters
        md_converters = site.converters.select{|c| c.matches('.md')}
        md_converters.reduce(output) do |output_to_convert, converter|
          converter.convert output_to_convert
        end
      end

      def get_layout(dir, site=@site)
        defaults = site.config.fetch('defaults', []).sort_by { |x| -(x.fetch('scope', {}).fetch('path', '').length) }

        default = defaults.detect { |x| dir.include?(x['scope']['path'])}

        default = {"values" => {}} if default.nil?

        default['values'].fetch('layout', 'default')
      end

  end

  class SecuritySchemePage<GeneratedPage
    def initialize(site, base, web_root, dir, securityScheme)
        super(site, base, web_root, dir, securityScheme, get_layout("#{web_root}resource", site))
    end
  end

  class DocumentationPage<GeneratedPage
    def initialize(site, base, web_root, dir, documentation)
      super(site, base, web_root, dir, documentation)

      output = documentation['content']
      self.data['body'] = transform_md(output)
    end
  end

  class ResourcePage<GeneratedPage 
    def initialize(site, base, web_root, dir, resource, traits, securitySchemes)
      # Sandbox our resource, and do nothing with child resources
      resource = resource.dup
      resource.delete('resources')

      resource['title'] = dir.sub('resource', '') if not resource.include?('title')
      super(site, base, web_root, dir, resource)

      # Add security data to the resource
      resource.fetch('methods', []).each do |method|
        if method.include?('securedBy')
          for scheme in method['securedBy']
            for attr in ['headers', 'queryParameters', 'responses']
              method[attr] = {} if not method.include?(attr)
              method[attr].merge!(securitySchemes[scheme].fetch('describedBy', {}).fetch(attr, {}))
            end
          end
        end
      end

      # Add trait data to the resource
      resource.fetch('methods', []).each do |method|
        if method.include?('is')
          for trait in method['is']
            merge_method_trait(method, traits[trait])
          end
        end
      end

      # Compile JSON Schema that use $ref references
      jsc = Jekyll::JsonSchemaCompiler.new
      jsc.compile(resource['methods'])

      # Generate new schema based on existing formParameters
      schema_generator = Jekyll::RamlSchemaGenerator.new(site, resource['title'])
      schema_generator.insert_schemas(resource['methods'])

      # Support a better presentation of the schema
      resource = add_schema_hashes(resource) 

      # Transform descriptions via Markdown
      resource = transform_resource_descriptions(resource)

      # Make all this available to Liquid templates
      self.data['methods'] = resource['methods']
    end

    private
      def merge_method_trait(method, trait)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        method.merge(trait, &merger)

        if method.include?('description')
          method['description'] = "#{method['description']}\n\n#{trait['description']}"
        else
          method['description'] = trait['description']
        end
        method
      end

      def transform_resource_descriptions(resource)
        if resource.include?('description')
            resource['description'] = transform_md(resource['description'])
        end

        resource.each_key do |key|
          if resource[key].is_a?(Hash)
            resource[key] = transform_resource_descriptions(resource[key])
          end
          if resource[key].is_a?(Array)
            resource[key].map!{|h| h.is_a?(Hash) ? transform_resource_descriptions(h) : h }
          end
        end

        resource
      end

      # Adds a 'schema_hash' attribute to bodies with 'schema', which allows for the generation of schema table views
      def add_schema_hashes(obj, key=nil)
        if obj.is_a?(Array)
          obj.map! { |method| add_schema_hashes(method) }
        elsif obj.is_a?(Hash)
          obj.each { |k, v| obj[k] = add_schema_hashes(v, k)}

          if obj.include?("schema")
            
            case key
              when 'application/json'
                obj['schema_hash'] = JSON.parse(obj['schema'])

                refactor_object = lambda do |lam_obj|
                  lam_obj['properties'].each do |name, param|
                    param['displayName'] = name
                    param['required'] = true if lam_obj.fetch('required', []).include?(name)

                    if param.include?('example') and ['object', 'array'].include?(param['type'])
                      param['example'] = JSON.pretty_generate(JSON.parse(param['example']))
                    elsif param.include?('properties')
                      param['properties'] = JSON.pretty_generate(param['properties'])
                    elsif param.include?('items')
                      param['items'] = JSON.pretty_generate(param['items'])
                    end

                    lam_obj['properties'][name] = param
                  end
                  lam_obj
                end

                if obj['schema_hash'].include?('properties')
                  obj['schema_hash'] = refactor_object.call(obj['schema_hash'])
                end

                if obj['schema_hash'].include?('items') and obj['schema_hash']['items'].include?('properties')
                  obj['schema_hash']['items'] = refactor_object.call(obj['schema_hash']['items'])
                end
            end
          end
        end

        obj
      end
  end

  class ReferencePageGenerator < Generator
    safe true

    def generate(site)
      @site = site

      site.config.fetch('ramler_api_paths', {'api.json' => '/'}).each do |file_path, web_root|
        web_root = '/' if web_root.nil? or web_root.empty?
        raise 'raml_api_paths web paths must end with "/"' if web_root[-1] != '/'
        generate_api_pages(file_path, web_root)
      end
    end

    def generate_api_pages(raml_path, web_root)
      @web_root = web_root 
      raml_js = File.open(raml_path).read
      raml_hash = JSON.parse(raml_js)

      # BETTER THE DATASTRUCTURES!
      @traits = {}
      @securitySchemes = {}
      if raml_hash.has_key?('traits')
        raml_hash['traits'].each {|obj| obj.each_pair {|k, v| @traits[k] = v}}
      end
      if raml_hash.has_key?('securitySchemes')
        raml_hash['securitySchemes'].each do |obj| 
          obj.each_pair do |k, v| 
            v.fetch('describedBy', {}).fetch('headers', {}).each_pair{ |hn, hv| hv['displayName'] = hn if not hv.nil?}
            v.fetch('describedBy', {}).fetch('queryParameters', {}).each_pair{ |hn, hv| hv['displayName'] = hn if not hv.nil?}
            @securitySchemes[k] = v
          end
        end
      end

      # Create a page for each resource
      if raml_hash.has_key?('resources')
        generate_resource_pages(raml_hash['resources'])
      end

      dir = Jekyll::get_dir('security', @site.config) 
      @securitySchemes.each do |scheme_name, scheme|
        scheme_dir = File.join(dir, scheme_name)
        scheme['title'] = scheme_name
        @site.pages << SecuritySchemePage.new(@site, @site.source, @web_root, scheme_dir, scheme) 
      end

      dir = Jekyll::get_dir('overview', @site.config) 
      raml_hash.fetch('documentation', []).each do |documentation|
        documentation_dir = File.join(dir, documentation['title'])
        @site.pages << DocumentationPage.new(@site, @site.source, @web_root, documentation_dir, documentation)
      end

      generate_downloadable_descriptors(raml_hash, raml_path)
    end

    private
    def generate_resource_pages(resources, parent_dir=nil)

      if parent_dir
        dir = parent_dir
      else 
        dir = Jekyll::get_dir('resource', @site.config)
      end

      resources.each do |resource|
        resource_name = resource["relativeUri"]
        resource_dir = File.join(dir, resource_name)
        @site.pages << ResourcePage.new(@site, @site.source, @web_root, resource_dir, resource, @traits, @securitySchemes)
        generate_resource_pages(resource['resources'], resource_dir) if resource.has_key?('resources')
      end
    end

    def generate_downloadable_descriptors(raml_hash, raml_path)
      # Allow users to download descriptor as RAML and JSON, which may be modified since it was read
      raml_hash = DeepClone.clone raml_hash 

      # Get rid of 'title' attribute added to security schemes
      # securitySchemes will be an array of hashes containing one key (Name) value (a hash of properties) pairing
      raml_hash.fetch('securitySchemes', []).each {|el| el.each_value { |scheme| scheme.delete('title') }}

      # replace "resources" with the associated "relativeUri" of each resource
      fix_resources(raml_hash)

      download_basename = @site.config.fetch('ramler_downloadable_descriptor_basenames', {}).fetch(raml_path, 'api') 
      raml_download_filename = download_basename + '.raml'
      json_download_filename = download_basename + '.json'

      raml_yaml = raml_hash.to_yaml
      raml_yaml.sub!('---', '#%RAML 0.8')
      @site.static_files << RawFile.new(@site, @site.source, @web_root, raml_download_filename, raml_yaml)

      raml_json = JSON.pretty_generate(raml_hash)
      @site.static_files << RawFile.new(@site, @site.source, @web_root, json_download_filename, raml_json) 
    end

    def fix_resources(raml_hash) 
      # DFS FTW
      raml_hash.fetch('resources', []).each do |resource_hash|
        raml_hash[resource_hash.delete('relativeUri')] = resource_hash
        fix_resources(resource_hash)
      end

      raml_hash.fetch('methods', []).each do |method_hash|
        raml_hash[method_hash.delete('method')] = method_hash
        fix_body(method_hash)
      end
      raml_hash.delete('methods')
      raml_hash.delete('schema_hash') 
      raml_hash.delete('relativeUriPathSegments')
      raml_hash.delete('resources')
      raml_hash
    end

    def fix_body(method_hash)
        method_hash.fetch('body', {}).each {|content_type, definition| definition.delete('schema_hash')} 
        method_hash.fetch('responses', {}).each {|response_code, response_hash| fix_body(response_hash) if response_hash}
    end
  end
end
