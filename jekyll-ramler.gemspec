Gem::Specification.new do |s|
  s.name        = 'jekyll-ramler'
  s.version     = '0.0.1'
  s.date        = '2015-02-09'
  s.authors     = ['GovDelivery']
  s.email       = 'support@govdelivery.com'
  s.homepage    = 'https://github.com/govdelivery/jekyll-ramler'
  s.license     = 'BSD-3-Cluase'
  s.summary     = 'Jekyll plugin that generates API documentation pages based on RAML'
  s.description = %q{Generates Jekyll pages for overview, security, and 
                     resource documentation specificed in a RAML file.}

  s.add_runtime_dependency  'jekyll'

  s.files       = `git ls-files`.split($\)
  s.require_paths = ['lib']
end
