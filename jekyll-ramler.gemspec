Gem::Specification.new do |s|
  s.name        = 'jekyll-ramler'
  s.version     = '1.0.0'
  s.date        = '2020-09-01'
  s.authors     = ['Granicus']
  s.email       = 'support@granicus.com'
  s.homepage    = 'https://github.com/granicus/jekyll-ramler'
  s.license     = 'BSD-3-Cluase'
  s.summary     = 'Jekyll plugin that generates API documentation pages based on RAML'
  s.description = %q{Generates Jekyll pages for overview, security, and 
                     resource documentation specificed in a RAML file.}

  s.add_runtime_dependency  'jekyll', '~> 3.9.0'
  s.add_runtime_dependency  'kramdown-parser-gfm', '~> 1.1.0'
  s.add_runtime_dependency  'ruby_deep_clone'

  s.files       = `git ls-files`.split($\)
  s.require_paths = ['lib']
end
