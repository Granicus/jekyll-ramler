[![Build Status](https://travis-ci.org/govdelivery/jekyll-ramler.svg?branch=master)](https://travis-ci.org/govdelivery/jekyll-ramler)
[![Gem Version](https://badge.fury.io/rb/jekyll-ramler.svg)](http://badge.fury.io/rb/jekyll-ramler)

jekyll-ramler
=============

Generates Jekyll pages for overview, security, and resource documentation 
specificed in a RAML file.


## Installation

### Dependencies

jekyll-ramler relies on [raml-cop](https://www.npmjs.com/package/raml-cop), a 
Node.js script, to actually parse a RAML file. Thus, you will need to install
[Node.js](http://nodejs.org/), then perform `npm install raml-cop`.


## Configuration

Several options can be defined by your project's _config.yml:

- **ramler_api_paths**

  A nested mapping of the files that jekyll-ramler should read while generating
  content and the web folders where that content should be placed. *Keys* are
  the file system paths (relative to your project's root directory) of the
  files to be read. *Values* are the web paths (relative to web root) to place
  all content generated based on the read file into. Keys must end with a 
  forward slash. If no value is provided, web root (/) is used. 

  If *ramler_api_paths* is not defined, jekyll-ramler will default to reading
  `api.json` from your project's root and placing generated files into web 
  root.

  At this time, only JSON representations of RAML can be read.

  Example:

  ```
    ramler_api_paths:
      ramls/api_v1.json: /an_api/v1/
      ramls/api_v2.json: /an_api/v2/
      ramls/api_v3.json: /an_api/
      ramls/api_v3.json: /an_api/v3/
      experimental/foo.json: /unstable/
      ramls/popular.json: /
  ```

- **ramler_generated_sub_dirs**

  A nested map defining the web sub directories that jekyll-ramler will place
  generated pages into. Can have three mappings:

  - *resource* - web sub directory for resource pages. Defaults to `resource`.
  - *overview* - web sub directory for overview pages. Defaults to `overview`.
  - *security* - web sub directory for security pages. Defaults to `security`.

  Example:

  ```
    ramler_generated_sub_dirs:
      resource: resources_pages
      overview: general_documentation
      security: security_information
  ```

  The same value can be used in multiple mappings. For example, all three
  mappings could be set to `documentation`.


## JSON Schema Support

jekyll-ramler includes a few features for JSON Schema.

### Table and Raw views of JSON Schema

If a resource method defines `body:application/json:schema` item, then
jekyll-ramler will generate two views of the schema. One view will be an
easily copyable display of the raw schema. The other view will be a table-like
display of parameters, similar to what is generated for 
`body:application/x-www-form-urlencoded:formParamters`. 

### Generated JSON Schema from formParameters

Recognizing that Content-Type does not impact functionality or content for some
APIs, jekyll-ramler will generate JSON Schema for resource methods that include
a defined `body:application/x-www-form-urlencoded:formParamters` list, as well
as a `body:application/json` item **without** a `schema` item. If a resource
includes a `body:application/json/schema` item, then nothing will happen.

## $ref and allOf

[JSON Schema provides a semantic construct for schema inheritance](http://spacetelescope.github.io/understanding-json-schema/reference/combining.html)
via the **$ref** and **allOf** keywords. jekyll-ramler uses this construct to
allow for schema referred to in RAML to inherit from other schema, which allows
you to DRY your JSON schema bit.

When jekyll-ramler encounteres **$ref** and/or **allOf**, it pulls in and
merges the referred to schemas, creating a single schema object that includes
all attributes. Thus, while you might store your JSON schema across multiple
files, users of your site will only see fully de-referenced and merged JSON
schema on your site. This de-referencing and merging also allows jekyll-ramler
to generate complete, table-like views of your JSON schema, even if your schema
inherits from other schema.
