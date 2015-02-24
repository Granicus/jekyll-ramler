[![Build Status](https://travis-ci.org/govdelivery/jekyll-ramler.svg?branch=master)](https://travis-ci.org/govdelivery/jekyll-ramler)
[![Gem Version](https://badge.fury.io/rb/jekyll-ramler.svg)](http://badge.fury.io/rb/jekyll-ramler)

jekyll-ramler
=============

Generates Jekyll pages for overview, security, and resource documentation 
specificed in a RAML file.

## Features

- Renders RAML into multi-page HTML views - one page per endpoint
- Supports rendering multiple RAML files into web pages
- Transforms description fields found in RAML via Markdown
- Auto-generation of JSON Schema based on existing formParamters of
  application/x-www-form-urlencoded
- Generation of complete RAML and JSON representations of API descriptors
- Supports Raw and Table based displays of JSON Schema included in your RAMLs
- Automatic insertion of inherited JSON Schema (via `$ref` and `allOf`)

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

  Behavior is undefined for cases in which jekyll-ramler is configured to 
  output generated content of multiple source files to the same web path.

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

- **ramler_downloadable_descriptor_basenames**

  A nested map defining the basename of the generated, downloadable descriptors
  (RAML and JSON). Format is similar to `ramler_api_paths`, where the *keys*
  are file system paths of files to be read, while *values* are the basenames 
  to use for generated descriptors. For example:

  ```
    ramler_downloadable_descriptor_basenames:
      ramls/api_v1.json: api_v1
      experimental/foo.json:  unstable
  ```

  will lead to the creation of `api_v1.raml`, `api_v1.json`, `unstable.raml`,
  and `unstable.json` downloadable files.

  If a basename is not defined, `api` is used as a basename. 

  Generated descriptor files will be placed in the web folder configured for a
  given source file.

### Markdown no_intra_emphasis

All description values found in a RAML file are transformed via Markdown, which
allows underscores (_) to be used as deliminators for emphasis and bold 
content. Default transformation behavior can lead to mis-transformed content, 
especially for words that contain underscores, such as variable names. As such,
it is recommended that you use the no_intra_emphasis extension of your choosen
Markdown engine. This extension can be enabled for *Redcarpet* by adding the
following to your _config.yml:

```
markdown: redcarpet
redcarpet:
  extensions: ["no_intra_emphasis"]
```

Refer to <http://jekyllrb.com/docs/configuration/#markdown-options> for more
information on the use of no_intra_emphasis in Jekyll.

## Markdown Descriptions

jekyll-ramler will transform any *description* value found in a RAML via
Markdown. This includes description values on endpoints, methods, security 
schemas, and in formParameters items. *body* values of `documentation` entires
will also be transformed via Markdown.

Note that in order to use Markdown in the description of a formParameter item,
you will need to use the pipe syntax (|) to avoid a RAML validation error.

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
