jekyll-ramler
=============

Generates Jekyll pages for overview, security, and resource documentation 
specificed in a RAML file.


## Installation

### Dependencies

jekyll-ramler relies on [raml-cop](https://www.npmjs.com/package/raml-cop), a 
Node.js script, to actually parse a RAML file. Thus, you will need to install
[Node.js](http://nodejs.org/), then perform `npm install raml-cop`.


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
