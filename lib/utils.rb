require 'json'
require 'deep_clone'

module Jekyll
  def self.get_dir(page_type, config)
    config.fetch('ramler_generated_sub_dirs', {}).fetch(page_type, page_type)
  end

  def self.sanatize_json_string(s)
      # This use to do something. Hopefully someday it will do something again
      # See strip_newlines
      s
  end

  def self.strip_newlines(s)
    # Assuming Markdown, so do NOT remove consecutive newlines
    # TODO Also do not remove newlines at end of list items
    regex = /([^\n])\n([^\n])/
    s.gsub(regex, '\1 \2').strip
  end

  # Utility class for creating schema (current JSON, perhaps XML someday) based
  # on existing RAML formParameters 
  class RamlSchemaGenerator


    def initialize(site, title=nil)
      @site = site
      @title = title
      @current_method = nil
    end

    # Creates a schema attribute sibling of any formParameter attribute found, 
    # based on the found formParameters attribute.
    #
    # Existing schema siblings of formParameter attributes are not modified.
    #
    # Modifys obj, and returns the modified obj
    def insert_schemas(obj)
      if obj.is_a?(Array)
        obj.map!{|method| insert_schemas(method)}
      elsif obj.is_a?(Hash)
        @current_method = obj['method'] if obj.include?('method')
        
        obj.each { |k, v| obj[k] = insert_schemas(v)}

        if obj.include?('body')
          if obj['body'].fetch('application/x-www-form-urlencoded', {}).include?('formParameters')
            if insert_json_schema?(obj)
              insert_json_schema(obj, generate_json_schema(obj))
            end
          end
        end
      end

      obj
    end

    # Inserts provided JSON Schema into obj['body']['application/json']['schema'] 
    def insert_json_schema(obj, schema)
      obj['body']['application/json'] = {} if obj['body']['application/json'].nil?
      obj['body']['application/json']['schema'] = schema 
    end

    # Creates JSON Schema - as a string - based on obj['body']['application/x-www-form-urlencoded']['formParameters'] 
    def generate_json_schema(obj)

      # JSON Schema spec: http://json-schema.org/latest/json-schema-validation.html
      schema_hash = {}
      schema_hash['$schema'] = @site.config['json_schema_schema_uri']
      schema_hash['title'] = @title if @title
      schema_hash['description'] = Jekyll::sanatize_json_string(obj['description']) if obj.include?('description')
      schema_hash['type'] = 'object'

      required_properties = []
      schema_hash['properties'] = DeepClone.clone obj['body']['application/x-www-form-urlencoded']['formParameters']
      schema_hash['properties'].each do |name, param|
        if param.include?('required')
          required_properties << name if param['required'] == true
          param.delete('required')
        end

        if param.include?('description')
          param['description'] = Jekyll::sanatize_json_string(param['description']) 
        end

        # Repeat and displayName are not supported keywords in JSON Schema
        param.delete('repeat')
        param.delete('displayName')
      end
      schema_hash['required'] = required_properties if not required_properties.empty?
      
      JSON.pretty_generate(schema_hash)
    end

    def insert_json_schema?(obj)
      return false if !obj['body'].include?('application/json')
      json_hash = obj['body']['application/json']
      json_hash = {} if json_hash.nil?
      !(json_hash.include?('schema'))
    end
  end

  class JsonSchemaCompiler
    def compile(obj, obj_name=nil)
      if obj.is_a?(Array)
        obj.map!{|method| compile(method)}
      elsif obj.is_a?(Hash)
        if obj.include?('schema') and obj_name == 'application/json'
          schema_hash = JSON.parse(obj['schema']) 
          schema_hash = traverse_and_compile_schema(schema_hash)
          obj['schema'] = JSON.pretty_generate(schema_hash)
        end
        
        obj.each { |k, v| obj[k] = compile(v, k)}
      end

      obj
    end

    private
      def traverse_and_compile_schema(schema_hash)
        if schema_hash.is_a?(Array)
          schema_hash.map!{|method| traverse_and_compile_schema(method)}
        elsif schema_hash.is_a?(Hash)
          if schema_hash.include?('$ref')
            refed = JSON.parse(File.read(schema_hash['$ref']))
            schema_hash.delete('$ref')
            schema_hash.merge!(refed)
          end

          schema_hash.each { |k, v| schema_hash[k] = traverse_and_compile_schema(v)}

          # Merge allOfs into the parent object
          if schema_hash.include?('allOf')
            for item in schema_hash['allOf']
              merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
              schema_hash.merge!(item, &merger)
            end
            schema_hash.delete('allOf')
          end
        end
        schema_hash 
      end
  end
end
