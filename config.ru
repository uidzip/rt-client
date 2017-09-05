#\ -s puma -b 127.0.0.1 -p 8080

require "rack-timeout"
use Rack::Timeout
Rack::Timeout.timeout = 240

require "./rtxmlsrv2"

use Rack::RPC::Endpoint, TicketSrv.new, :path => '/'
run RTXMLApp.new
