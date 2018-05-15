# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rt-client"
  s.version = "1.0.0"

  s.files = ['rt_client.rb','rtxmlsrv.rb','rtxmlsrv2.rb','rt/client.rb','.yardopts']
  s.authors = ["Tom Lahti"]
  s.email = 'uidzip@gmail.com'
  s.date = "2016-10-31"
  s.description = "RT_Client is a ruby object that accesses the REST interface version 1.0\n    of a Request Tracker instance.  See http://www.bestpractical.com/ for\n    Request Tracker.\n"
  s.email = "tlahti@dmsolutions.com"
  s.homepage = "http://rubygems.org/gems/rt-client"
  s.licenses = ["APACHE-2.0"]
  s.rdoc_options = ["--inline-source", "--main", "RT_Client"]
  s.require_paths = ["."]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.requirements = ["A working installation of RT with the REST 1.0 interface"]
  s.rubygems_version = "1.8.24"
  s.summary = "Ruby object for RT access via REST"
  s.add_runtime_dependency 'rest-client', '>= 0.9'
end
