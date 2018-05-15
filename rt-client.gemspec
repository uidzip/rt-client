# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rt-client"
  s.version = "1.0.1"

  s.files = ['rt_client.rb','rtxmlsrv.rb','rtxmlsrv2.rb','rt/client.rb','.yardopts']
  s.authors = ["Tom Lahti"]
  s.email = 'uidzip@gmail.com'
  s.date = "2018-05-18"
  s.description = "RT_Client is a ruby object that accesses the REST interface version 1.0\n    of a Request Tracker instance.  See http://www.bestpractical.com/ for\n    Request Tracker.\n"
  s.homepage = "https://github.com/uidzip/rt-client"
  s.licenses = ["APSL-2.0"]
  s.rdoc_options = ["--inline-source", "--main", "RT_Client"]
  s.require_paths = ["."]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.requirements = ["A working installation of RT with the REST 1.0 interface"]
  s.rubygems_version = "2.6.14.1"
  s.summary = "Ruby object for RT access via REST"
  s.add_runtime_dependency 'rest-client', '~> 2.0', '>= 2.0.0'
 end
