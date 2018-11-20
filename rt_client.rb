#!/usr/bin/ruby

require "rubygems"
require "rest_client"
if (RUBY_VERSION.to_f < 1.9)
  require 'iconv'
end

require 'pp'

## Author:: Tom Lahti
## Copyright:: Copyright (c) 2013 Tom Lahti
## License:: Apache 2.0

#{<img src="https://badge.fury.io/rb/rt-client.png" alt="Gem Version" />}[http://badge.fury.io/rb/rt-client]
##A ruby library API to Request Tracker's REST interface. Requires the
##rubygem rest-client be installed.  You can
##create a file name .rtclientrc in the same directory as client.rb with a
##default server/user/pass to connect to RT as, so that you don't have to
##specify it/update it in lots of different scripts.
##
##Thanks to the following members of the RT community for patches:
##Brian McArdle for patch dealing with spaces in Custom Fields (use '_')
##Steven Craig for a bug fix and feature additions to the usersearch() method.
##Rafael Abdo for fixing a broken regex.
##
##Extra Special Thanks to Robert Vinson for 1.9.x compatibility when I
##couldn't be buggered and refactoring the old mess into something with much fewer
##dependencies.
##
##
##
##TODO: Streaming, chunking attachments in compose method
#
# See each method for sample usage.  To use this, "gem install rt-client" and
#
#  require "rt_client"

class RT_Client

  UA = "Mozilla/5.0 ruby RT Client Interface 1.0.2"
  attr_reader :status, :site, :version, :cookies, :server, :user, :cookie

  # Create a new RT_Client object. Load up our stored cookie and check it.
  # Log into RT again if needed and store the new cookie.  You can specify
  # login and cookie storage directories in 3 different ways:
  # 1. Explicity during object creation
  # 2. From a .rtclientrc file in the working directory of your ruby program
  # 3. From a .rtclientrc file in the same directory as the library itself
  #
  # These are listed in order of priority; if you have explicit parameters,
  # they are always used, even if you have .rtclientrc files.  If there
  # is both an .rtclientrc in your program's working directory and
  # in the library directory, the one from your program's working directory
  # is used.  If no parameters are specified either explicity or by use
  # of a .rtclientrc, then the defaults of "rt_user", "rt_pass" are used
  # with a default server of "http://localhost", and cookies are stored
  # in the directory where the library resides. Default timeout is 240
  # seconds and SSL certificate validation is disabled by default.
  #
  #  rt= RT_Client.new( :server  => "https://tickets.ambulance.com/",
  #                     :user    => "rt_user",
  #                     :pass    => "rt_pass",
  #                     :cookies => "/my/cookie/dir",
  #                     :timeout => 240,
  #                     :verify_ssl => false )
  #
  #  rt= RT_Client.new # use defaults from .rtclientrc
  #
  # .rtclientrc format:
  #  server=<RT server>
  #  user=<RT user>
  #  pass=<RT password>
  #  cookies=<directory>
  #  timeout=<integer in seconds>
  #  verify_ssl=<true or false>
  def initialize(*params)
    @version = "1.0.2"
    @status = "Not connected"
    @server = "http://localhost/"
    @user = "rt_user"
    @pass = "rt_pass"
    @cookies = Dir.pwd
    @timeout = 240
    @verify_ssl = false
    config_file = Dir.pwd + "/.rtclientrc"
    config = ""
    if File.file?(config_file)
      config = File.read(config_file)
    else
      config_file = File.dirname(__FILE__) + "/.rtclientrc"
      config = File.read(config_file) if File.file?(config_file)
    end
    @server = $~[1] if config =~ /\s*server\s*=\s*(.*)$/i
    @user = $~[1] if config =~ /^\s*user\s*=\s*(.*)$/i
    @pass = $~[1] if config =~ /^\s*pass\s*=\s*(.*)$/i
    @cookies = $~[1] if config =~ /\s*cookies\s*=\s*(.*)$/i
    @timeout = $~[1] if config =~ /\s*timeout\s*=\s*(.*)$/i
    @verify_ssl = $~[1] if config =~ /\s*verify_ssl\s*=\s*(.*)$/i
    @resource = "#{@server}REST/1.0/"
    if params.class == Array && params[0].class == Hash
      param = params[0]
      @user = param[:user] if param.has_key? :user
      @pass = param[:pass] if param.has_key? :pass
      if param.has_key? :server
        @server = param[:server]
        @server += "/" if @server !~ /\/$/
        @resource = "#{@server}REST/1.0/"
      end
      @cookies  = param[:cookies] if param.has_key? :cookies
      @timeout = param[:timeout] if param.has_key? :timeout
      @verify_ssl = param[:verify_ssl] if param.has_key? :verify_ssl
    end
    @login = { :user => @user, :pass => @pass }
    cookiejar = "#{@cookies}/RT_Client.#{@user}.cookie" # cookie location
    cookiejar.untaint
    if File.file? cookiejar
      @cookie = File.read(cookiejar).chomp
      headers = { 'User-Agent' => UA,
      'Content-Type' => "application/x-www-form-urlencoded",
      'Cookie'       => @cookie }
    else
      headers = { 'User-Agent' => UA,
      'Content-Type' => "application/x-www-form-urlencoded" }
      @cookie = ""
    end

    if @verify_ssl.casecmp('true') == 0
      @verify_ssl = true
    else
      @verify_ssl = false
    end

    site = RestClient::Resource.new(@resource, :headers => headers, :timeout => @timeout.to_i, :verify_ssl => @verify_ssl)
    data = site.post "" # a null post just to check that we are logged in

    if @cookie.length == 0 or data =~ /401/ # we're not logged in
      data = site.post @login, :headers => headers
      # puts data
      if data.headers[:set_cookie].class == String
        @cookie = data.headers[:set_cookie].split('; ')[0]
      elsif data.headers[:set_cookie].class == Array
        @cookie = data.headers[:set_cookie][0].split('; ')[0]
      else
        puts "Don't know how to handle set_cookie header, RestClient gave me a #{data.headers[:set_cookie].class}"
        exit
      end
      # write the new cookie
      if @cookie !~ /nil/
        f = File.new(cookiejar,"w")
        f.puts @cookie
        f.close
      end
    end

    headers = { 'User-Agent'   => UA,
                'Cookie'       => @cookie }
    @site = RestClient::Resource.new(@resource, :headers => headers, :timeout => @timeout.to_i, :verify_ssl => @verify_ssl)
    @status = data
    self.untaint

  end

  # gets the detail for a single ticket/user.  If its a ticket, its without
  # history or attachments (to get those use the history method) .  If no
  # type is specified, ticket is assumed.  takes a single parameter
  # containing the ticket/user id, and returns a hash of RT Fields => values
  #
  #  hash = rt.show(822)
  #  hash = rt.show("822")
  #  hash = rt.show("ticket/822")
  #  hash = rt.show(:id => 822)
  #  hash = rt.show(:id => "822")
  #  hash = rt.show(:id => "ticket/822")
  #  hash = rt.show("user/#{login}")
  #  email = rt.show("user/somebody")["emailaddress"]
  def show(id)
    id = id[:id] if id.class == Hash
    id = id.to_s
    type = "ticket"
    sid = id
    if id =~ /(\w+)\/(.+)/
      type = $~[1]
      sid = $~[2]
    end
    reply = {}
    sid.gsub!(/\@.*/,'') if sid =~ /dmsolutions\.com$/
    if type.downcase == 'user' and sid =~ /\@/
      resp = @site["#{type}/#{sid}"].get
    else
      resp = @site["#{type}/#{sid}/show"].get
    end
    reply = response_to_h(resp)
  end

  # gets a list of ticket links for a ticket.
  # takes a single parameter containing the ticket id,
  # and returns a hash of RT Fields => values
  #
  #  hash = rt.links(822)
  #  hash = rt.links("822")
  #  hash = rt.links("ticket/822")
  #  hash = rt.links(:id => 822)
  #  hash = rt.links(:id => "822")
  #  hash = rt.links(:id => "ticket/822")
  def links(id)
    id = id[:id] if id.class == Hash
    id = id.to_s
    type = "ticket"
    sid = id
    if id =~ /(\w+)\/(.+)/
      type = $~[1]
      sid = $~[2]
    end
    reply = {}
    resp = @site["ticket/#{sid}/links/show"].get
    return {:error => resp, }  if resp =~ /does not exist\.$/
    reply = response_to_h(resp)
  end

  # Creates a new ticket.  Requires a hash that contains RT form fields as
  # the keys.  Capitalization is important; use :Queue, not :queue.  You
  # will need at least :Queue to create a ticket.  For a full list of fields
  # you can use, try "/opt/rt3/bin/rt edit ticket/1". Returns the newly
  # created ticket number, or a complete REST response.
  #
  #  id = rt.create( :Queue   => "Customer Service",
  #                  :Cc      => "somebody\@email.com",
  #                  :Subject => "I've fallen and I can't get up",
  #                  :Text    => "I think my hip is broken.\nPlease help.",
  #                  :"CF.{CustomField}" => "Urgent",
  def create(field_hash)
    field_hash[:id] = "ticket/new"
    payload = compose(field_hash)
    resp = @site['ticket/new/edit'].post payload
    new_id = resp.match(/Ticket\s*(\d+)/)
    if new_id.class == MatchData
      new_ticket = new_id[1]
    else
      new_ticket = resp
    end
    new_ticket # return the ticket number, or the full REST response
  end

  # create a new user.  Requires a hash of RT fields => values. Returns
  # the newly created user ID, or the full REST response if there is an error.
  # For a full list of possible parameters that you can specify, look at
  # "/opt/rt/bin/rt edit user/1"
  #
  #  new_id = rt.create_user(:Name => "Joe_Smith", :EmailAddress => "joes\@here.com")
  def create_user(field_hash)
    field_hash[:id] = "user/new"
    payload = compose(field_hash)
    resp = @site['user/new/edit'].post payload
    new_id = resp.match(/User\s*(\d+)/)
    if new_id.class == MatchData
      new_user = new_id[1]
    else
      new_user = resp
    end
    new_user # return the new user id or the full REST response
  end

  # edit or create a user.  If the user exists, edits the user as "edit" would.
  # If the user doesn't exist, creates it as "create_user" would.
  def edit_or_create_user(field_hash)
    if field_hash.has_key? :id
      id = field_hash[:id]
      if id !~ /^user\//
        id = "user/#{id}"
        field_hash[:id] = id
      end
    else
      raise "RT_Client.edit_or_create_user require a user id in the 'id' key."
    end
    resp1 =  "not called"
    resp2 =  "not called"
    resp1 = edit(field_hash)
    resp2 = create_user(field_hash) if resp1 =~ /does not exist\.$/
    resp = "Edit: #{resp1}\nCreate:#{resp2}"
    resp
  end

  # edit an existing ticket/user. Requires a hash containing RT
  # form fields as keys.  the key :id is required.
  # returns the complete REST response, whatever it is.  If the
  # id supplied contains "user/", it edits a user, otherwise
  # it edits a ticket.  For a full list of fields you can edit,
  # try "/opt/rt3/bin/rt edit ticket/1"
  #
  #  resp = rt.edit(:id => 822, :Status => "resolved")
  #  resp = rt.edit(:id => ticket_id, :"CF.{CustomField}" => var)
  #  resp = rt.edit(:id => "user/someone", :EMailAddress => "something@here.com")
  #  resp = rt.edit(:id => "user/bossman", :Password => "mypass")
  #  resp = rt.edit(:id => "user/4306", :Disabled => "1")
  def edit(field_hash)
    if field_hash.has_key? :id
      id = field_hash[:id]
    else
      raise "RT_Client.edit requires a user or ticket id in the 'id' key."
    end
    type = "ticket"
    sid = id
    if id =~ /(\w+)\/(.+)/
      type = $~[1]
      sid = $~[2]
    end
    payload = compose(field_hash)
    resp = @site["#{type}/#{sid}/edit"].post payload
    resp
  end

  # Comment on a ticket.  Requires a hash, which must have an :id key
  # containing the ticket number.  Returns the REST response.  For a list of
  # fields you can use in a comment, try "/opt/rt3/bin/rt comment ticket/1"
  #
  #  rt.comment( :id   => id,
  #              :Text => "Oh dear, I wonder if the hip smells like almonds?",
  #              :Attachment => "/tmp/almonds.gif" )
  def comment(field_hash)
    if field_hash.has_key? :id
      id = field_hash[:id]
    else
      raise "RT_Client.comment requires a Ticket number in the 'id' key."
    end
    field_hash[:Action] = "comment"
    payload = compose(field_hash)
    @site["ticket/#{id}/comment"].post payload
  end

  # Find RT user details from an email address or a name
  #
  # rt.usersearch(:EmailAddress => 'some@email.com')
  # rt.usersearch(:Name => username)
  # -> {"name"=>"rtlogin", "realname"=>"John Smith", "address1"=>"123 Main", etc }
  def usersearch(field_hash)
    key = nil
    key = field_hash[:EmailAddress] if field_hash.has_key? :EmailAddress
    key = field_hash[:Name] if field_hash.has_key? :Name
    if key == nil
      raise "RT_Client.usersearch requires an RT user email in the 'EmailAddress' key or an RT username in the 'Name' key"
    end
    reply = {}
    resp = @site["user/#{key}"].get
    return reply if resp =~ /No user named/
    reply = response_to_h(resp)
  end

  # An alias for usersearch()
  def usernamesearch(field_hash)
    usersearch(field_hash)
  end

  # correspond on a ticket.  Requires a hash, which must have an :id key
  # containing the ticket number.  Returns the REST response.  For a list of
  # fields you can use in correspondence, try "/opt/rt3/bin/rt correspond
  # ticket/1"
  #
  #  rt.correspond( :id   => id,
  #                 :Text => "We're sending help right away.",
  #                 :Attachment => "/tmp/admittance.doc" )
  def correspond(field_hash)
    if field_hash.has_key? :id
      if field_hash[:id] =~ /ticket\/(\d+)/
        id = $~[1]
      else
        id = field_hash[:id]
      end
    else
      raise "RT_Client.correspond requires a Ticket number in the 'id' key."
    end
    field_hash[:Action] = "correspond"
    payload = compose(field_hash)
    @site["ticket/#{id}/comment"].post payload
  end

  # Get a list of tickets matching some criteria.
  # Takes a string Ticket-SQL query and an optional "order by" parameter.
  # The order by is an RT field, prefix it with + for ascending
  # or - for descending.
  # Returns a nested array of arrays containing [ticket number, subject]
  # The outer array is in the order requested.
  #
  #  hash = rt.list(:query => "Queue = 'Sales'")
  #  hash = rt.list("Queue='Sales'")
  #  hash = rt.list(:query => "Queue = 'Sales'", :order => "-Id")
  #  hash = rt.list("Queue='Sales'","-Id")
  def list(*params)
    query = params[0]
    order = ""
    if params.size > 1
      order = params[1]
    end
    if params[0].class == Hash
      params = params[0]
      query = params[:query] if params.has_key? :query
      order = params[:order] if params.has_key? :order
    end
    reply = []
    resp = @site["search/ticket/?query=#{URI.escape(query)}&orderby=#{order}&format=s"].get
    raise "Invalid query (#{query})" if resp =~ /Invalid query/
    resp = resp.split("\n") # convert to array of lines
    resp.each do |line|
      f = line.match(/^(\d+):\s*(.*)/)
      reply.push [f[1],f[2]] if f.class == MatchData
    end
    reply
  end

  # A more extensive(expensive) query then the list method.  Takes the same
  # parameters as the list method; a string Ticket-SQL query and optional
  # order, but returns a lot more information.  Instead of just the ID and
  # subject, you get back an array of hashes, where each hash represents
  # one ticket, indentical to what you get from the show method (which only
  # acts on one ticket).  Use with caution; this can take a long time to
  # execute.
  #
  #  array = rt.query("Queue='Sales'")
  #  array = rt.query(:query => "Queue='Sales'",:order => "+Id")
  #  array = rt.query("Queue='Sales'","+Id")
  #  => array[0] = { "id" => "123", "requestors" => "someone@..", etc etc }
  #  => array[1] = { "id" => "126", "requestors" => "someone@else..", etc etc }
  #  => array[0]["id"] = "123"
  def query(*params)
    query = params[0]
    order = ""
    if params.size > 1
      order = params[1]
    end
    if params[0].class == Hash
      params = params[0]
      query = params[:query] if params.has_key? :query
      order = params[:order] if params.has_key? :order
    end
    replies = []
    resp = @site["search/ticket/?query=#{URI.escape(query)}&orderby=#{order}&format=l"].get
    return replies if resp =~/No matching results./
    raise "Invalid query (#{query})" if resp =~ /Invalid query/
    resp.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n\n/,"") # strip HTTP response
    tickets = resp.split("\n--\n") # -- occurs between each ticket
    tickets.each do |ticket|
      ticket_h = response_to_h(ticket)
      reply = {}
      ticket_h.each do |k,v|
        case k
        when 'created','due','told','lastupdated','started'
          begin
            vv = DateTime.parse(v.to_s)
            reply["#{k}"] = vv.strftime("%Y-%m-%d %H:%M:%S")
          rescue ArgumentError
            reply["#{k}"] = v.to_s
          end
        else
          reply["#{k}"] = v.to_s
        end
      end
      replies.push reply
    end
    replies
  end

  # Get a list of history transactions for a ticket.  Takes a ticket ID,
  # an optional format parameter, and a optional comments parameter.  If
  # the format is ommitted, the short  format is assumed.  If the short
  # format is requested, it returns an array of 2 element arrays, where
  # each 2-element array is [ticket_id, description].  If the long format
  # is requested, it returns an array of hashes, where each hash contains
  # the keys listed below.  If the optional 'comments' parameter is supplied
  # and set to 'true', comments are included in the list of history items.
  # If 'comments' is omitted, it is assumed to be 'false' and all history
  # items related to comments are stripped from the response.
  #
  # id::           (history-id)
  # Ticket::       (Ticket this history item belongs to)
  # TimeTaken::    (time entered by the actor that generated this item)
  # Type::         (what type of history item this is)
  # Field::        (what field is affected by this item, if any)
  # OldValue::     (the old value of the Field)
  # NewValue::     (the new value of the Field)
  # Data::         (Additional data about the item)
  # Description::  (Description of this item; same as short format)
  # Content::      (The content of this item)
  # Creator::      (the RT user that created this item)
  # Created::      (Date/time this item was created)
  # Attachments::  (a hash describing attachments to this item)
  #
  #  history = rt.history(881)
  #  history = rt.history(881,"short")
  #  => [["10501"," Ticket created by blah"],["10510"," Comments added by userX"]]
  #  history = rt.history(881,"long")
  #  history = rt.history(:id => 881, :format => "long")
  #  => [{"id" => "6171", "ticket" => "881" ....}, {"id" => "6180", ...} ]
  def history(*params)
    id = params[0]
    format = "short"
    format = params[1].downcase if params.size > 1
    comments = false
    comments = params[2] if params.size > 2
    if params[0].class == Hash
       params = params[0]
       id = params[:id] if params.has_key? :id
       format = params[:format].downcase if params.has_key? :format
       comments = params[:comments] if params.has_key? :comments
    end
    id = id.to_s
    id = $~[1] if id =~ /ticket\/(\d+)/
    resp = @site["ticket/#{id}/history?format=#{format[0,1]}"].get
    resp = sterilize(resp)

    if format[0,1] == "s"
        h = resp.split("\n")
        h.select!{ |l| l =~ /^\d+:/ }
      if not comments
        h.select!{ |l| l !~ /^\d+: Comments/ }
        h.select!{ |l| l !~ /Outgoing email about a comment/ }
      end
      list = h.map { |l| l.split(":") }
    else
      resp.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n\n/,"") # toss the HTTP response
      resp.gsub!(/^#.*?\n\n/,"") # toss the 'total" line
      resp.gsub!(/^\n/m,"") # toss blank lines
      while resp.match(/CF\.\{[\w_ ]*[ ]+[\w ]*\}/) #replace CF spaces with underscores
        resp.gsub!(/CF\.\{([\w_ ]*)([ ]+)([\w ]*)\}/, 'CF.{\1_\3}')
      end

      items = resp.split("\n--\n")
      list = []
      items.each do |item|
        th = response_to_h(item)
        next if not comments and th["type"].to_s =~ /Comment/ # skip comments
        reply = {}
        th.each do |k,v|
          attachments = []
          case k
            when "attachments"
              temp = item.match(/Attachments:\s*(.*)/m)
              if temp.class != NilClass
                atarr = temp[1].scan(/(\d+):\s*(\w+)\s*\((\w+)\)/)
                atarr.each do |a|
                  s={}
                  s[:id] = a[0].to_s
                  s[:name] = a[1].to_s
                  s[:size] = a[2].to_s
                  attachments.push s
                  if s[:name] == 'untitled' and s[:size].to_i > 0 # this is the content in HTML, I hope
                    unt_att = get_attachment(id,s[:id])
                    if (['text/html','text/plain'].include? unt_att["contenttype"]) # hurray
                      reply["content_html"] = sterilize(unt_att["content"])
                    end
                  end
                end
                reply["attachments"] = attachments
              end
            when "content"
              reply["content"] = v.to_s
              temp = item.match(/^Content: (.*?)^\w+:/m)
              reply["content"] = temp[1] if temp.class != NilClass
            else
              reply["#{k}"] = v.to_s
          end
        end
        list.push reply
      end
    end
    list
  end

  # Get the detail for a single history item.  Needs a ticket ID and a
  # history item ID, returns a hash of RT Fields => values.  The hash
  # also contains a special key named "attachments", whose value is
  # an array of hashes, where each hash represents an attachment.  The hash
  # keys are :id, :name, and :size.
  #
  #  x = rt.history_item(21, 6692)
  #  x = rt.history_item(:id => 21, :history => 6692)
  #  => x = {"ticket" => "21", "creator" => "somebody", "description" =>
  #  =>      "something happened", "attachments" => [{:name=>"file.txt",
  #  =>      :id=>"3289", size=>"651b"}, {:name=>"another.doc"... }]}
  def history_item(*params)
    id = params[0]
    history = params[1]
    if params[0].class == Hash
      params = params[0]
      id = params[:id] if params.has_key? :id
      history = params[:history] if params.has_key? :history
    end
    reply = {}
    resp = @site["ticket/#{id}/history/id/#{history}"].get
    resp = sterilize(resp)
    return reply if resp =~ /not related/ # history id must be related to the ticket id
    resp.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n\n/,"") # toss the HTTP response
    resp.gsub!(/^#.*?\n\n/,"") # toss the 'total" line
    resp.gsub!(/^\n/m,"") # toss blank lines
    while resp.match(/CF\.\{[\w_ ]*[ ]+[\w ]*\}/) #replace CF spaces with underscores
      resp.gsub!(/CF\.\{([\w_ ]*)([ ]+)([\w ]*)\}/, 'CF.{\1_\3}')
    end
    th = response_to_h(resp)
    attachments = []
    th.each do |k,v|
      case k
        when "attachments"
          temp = resp.match(/Attachments:\s*(.*)[^\w|$]/m)
          if temp.class != NilClass
            atarr = temp[1].split("\n")
            atarr.map { |a| a.gsub!(/^\s*/,"") }
            atarr.each do |a|
              i = a.match(/(\d+):\s*(.*)/)
              s={}
              s[:id] = i[1]
              s[:name] = i[2]
              sz = i[2].match(/(.*?)\s*\((.*?)\)/)
              if sz.class == MatchData
                s[:name] = sz[1]
                s[:size] = sz[2]
              end
              attachments.push s
              if s[:name] == 'untitled' and s[:size].to_i > 0 # this is the content in HTML, I hope
                unt_att = get_attachment(id,s[:id])
                if (['text/html','text/plain'].include? unt_att["contenttype"]) # hurray
                  reply["content_html"] = sterilize(unt_att["content"])
                end
              end
            end
            reply["#{k}"] = attachments
          end
        when "content"
          reply["content"] = v.to_s
          temp = resp.match(/^Content: (.*?)^\w+:/m)
          reply["content"] = temp[1] if temp.class != NilClass
        else
          reply["#{k}"] = v.to_s
      end
    end
    reply
  end

  # Get a list of attachments related to a ticket.
  # Requires a ticket id, returns an array of hashes where each hash
  # represents one attachment.  Hash keys are :id, :name, :type, :size.
  # You can optionally request that unnamed attachments be included,
  # the default is to not include them.
  def attachments(*params)
    id = params[0]
    unnamed = params[1]
    if params[0].class == Hash
      params = params[0]
      id = params[:id] if params.has_key? :id
      unnamed = params[:unnamed] if params.has_key? :unnamed
    end
    unnamed = false if unnamed.to_s == "0"
    id = $~[1] if id =~ /ticket\/(\d+)/
    resp = @site["ticket/#{id}/attachments"].get
    resp.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n\n/,"") # toss the HTTP response
    resp.gsub!(/^\n/m,"") # toss blank lines
    while resp.match(/CF\.\{[\w_ ]*[ ]+[\w ]*\}/) #replace CF spaces with underscores
      resp.gsub!(/CF\.\{([\w_ ]*)([ ]+)([\w ]*)\}/, 'CF.{\1_\3}')
    end
    th = response_to_h(resp)
    list = []
    pattern = /(\d+:\s.*?\))(?:,|$)/
    match = pattern.match(th['attachments'].to_s)
    while match != nil
      list.push match[0]
      s = match.post_match
      match = pattern.match(s)
    end
    attachments = []
    list.each do |v|
      attachment = {}
      m=v.match(/(\d+):\s+(.*?)\s+\((.*?)\s+\/\s+(.*?)\)/)
      if m.class == MatchData
        next if m[2] == "(Unnamed)" and !unnamed
        attachment[:id] = m[1]
        attachment[:name] = m[2]
        attachment[:type] = m[3]
        attachment[:size] = m[4]
        attachments.push attachment
      end
    end
    attachments
  end

  # Get attachment content for single attachment.  Requires a ticket ID
  # and an attachment ID, which must be related.  If a directory parameter
  # is supplied, the attachment is written to that directory.  If not,
  # the attachment content is returned in the hash returned by the
  # function as the key 'content', along with some other keys you always get:
  #
  # transaction:: the transaction id
  # creator::     the user id number who attached it
  # id::          the attachment id
  # filename::    the name of the file
  # contenttype:: MIME content type of the attachment
  # created::     date of the attachment
  # parent::      an attachment id if this was an embedded MIME attachment
  #
  #  x = get_attachment(21,3879)
  #  x = get_attachment(:ticket => 21, :attachment => 3879)
  #  x = get_attachment(:ticket => 21, :attachment => 3879, :dir = "/some/dir")
  def get_attachment(*params)
    tid = params[0]
    aid = params[1]
    dir = nil
    dir = params[2] if params.size > 2
    if params[0].class == Hash
      params = params[0]
      tid = params[:ticket] if params.has_key? :ticket
      aid = params[:attachment] if params.has_key? :attachment
      dir = params[:dir] if params.has_key? :dir
    end
    tid = $~[1] if tid =~ /ticket\/(\d+)/
    resp = @site["ticket/#{tid}/attachments/#{aid}"].get
    resp.gsub!(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n\n/,"") # toss HTTP response
    while resp.match(/CF\.\{[\w_ ]*[ ]+[\w ]*\}/) #replace CF spaces with underscores
      resp.gsub!(/CF\.\{([\w_ ]*)([ ]+)([\w ]*)\}/, 'CF.{\1_\3}')
    end
    headers = response_to_h(resp)
    reply = {}
    headers.each do |k,v|
      reply["#{k}"] = v.to_s
    end
    content = resp.match(/Content:\s+(.*)/m)[1]
    content.gsub!(/\n\s{9}/,"\n") # strip leading spaces on each line
    content.chomp!
    content.chomp!
    content.chomp! # 3 carriage returns at the end
    if (RUBY_VERSION.to_f >= 1.9)
      binary = content.encode("ISO-8859-1","UTF-8", { :invalid => :replace, :undef => :replace })
    else
      binary = Iconv.conv("ISO-8859-1","UTF-8",content) # convert encoding
    end
    if dir
      fh = File.new("#{dir}/#{headers['Filename'].to_s}","wb")
      fh.write binary
      fh.close
    else
      reply["content"] = binary
    end
    reply
  end

  # Add a watcher to a ticket, but only if not already a watcher.  Takes a
  # ticket ID, an email address (or array of email addresses), and an
  # optional watcher type.  If no watcher type is specified, its assumed to
  # be "Cc".  Possible watcher types are 'Requestors', 'Cc', and 'AdminCc'.
  #
  #  rt.add_watcher(123,"someone@here.com")
  #  rt.add_watcher(123,["someone@here.com","another@there.com"])
  #  rt.add_watcher(123,"someone@here.com","Requestors")
  #  rt.add_watcher(:id => 123, :addr => "someone@here.com")
  #  rt.add_watcher(:id => 123, :addr => ["someone@here.com","another@there.com"])
  #  rt.add_watcher(:id => 123, :addr => "someone@here.com", :type => "AdminCc")
  def add_watcher(*params)
    tid = params[0]
    addr = []
    type = "cc"
    addr = params[1] if params.size > 1
    type = params[2] if params.size > 2
    if params[0].class == Hash
      params = params[0]
      tid = params[:id] if params.has_key? :id
      addr = params[:addr] if params.has_key? :addr
      type = params[:type] if params.has_key? :type
    end
    addr = addr.lines.to_a.uniq # make it array if its just a string, and remove dups
    type.downcase!
    tobj = show(tid) # get current watchers
    ccs = tobj["cc"].split(", ")
    accs = tobj["admincc"].split(", ")
    reqs = tobj["requestors"].split(", ")
    watchers = ccs | accs | reqs # union of all watchers
    addr.each do |e|
      case type
        when "cc"
          ccs.push(e) if not watchers.include?(e)
        when "admincc"
          accs.push(e) if not watchers.include?(e)
        when "requestors"
          reqs.push(e) if not watchers.include?(e)
      end
    end
    case type
      when "cc"
        edit(:id => tid, :Cc => ccs.join(","))
      when "admincc"
        edit(:id => tid, :AdminCc => accs.join(","))
      when "requestors"
        edit(:id => tid, :Requestors => reqs.join(","))
    end
  end

  # don't give up the password when the object is inspected
  def inspect # :nodoc:
    mystr = super()
    mystr.gsub!(/(.)pass=.*?([,\}])/,"\\1pass=<hidden>\\2")
    mystr
  end

  # helper to convert responses from RT REST to a hash
  def response_to_h(resp) # :nodoc:
    resp = resp.body.gsub(/RT\/\d+\.\d+\.\d+\s\d{3}\s.*\n\n/,"") # toss the HTTP response

    # unfold folded fields
    # A newline followed by one or more spaces is treated as a
    # single space
    resp.gsub!(/\n +/, " ")

    #replace CF spaces with underscores
    while resp.match(/CF\.\{[\w_ ]*[ ]+[\w ]*\}/)
      resp.gsub!(/CF\.\{([\w_ ]*)([ ]+)([\w ]*)\}/, 'CF.{\1_\3}')
    end
    return {:error => resp }  if (resp =~ /^#/ and resp =~/does not exist\.$/) or (resp =~ /Transaction \d+ is not related to Ticket/)

    # convert fields to key value pairs
    ret = {}
    resp.each_line do |ln|
      next unless ln =~ /^.+?:/
      ln_a = ln.split(/:/,2)
      ln_a.map! {|item| item.strip}
      ln_a[0].downcase!
      ret[ln_a[0]] = ln_a[1]
    end

    return ret
  end

  # Helper for composing RT's "forms".  Requires a hash where the
  # keys are field names for an RT form.  If there's a :Text key, the value
  # is modified to insert whitespace on continuation lines.  If there's an
  # :Attachment key, the value is assumed to be a comma-separated list of
  # filenames to attach.  It returns a hash to be used with rest-client's
  # payload class
  def compose(fields) # :nodoc:
    if fields.class != Hash
      raise "RT_Client.compose requires parameters as a hash."
    end

    payload = { :multipart => true }

    # attachments
    if fields.has_key? :Attachments
      fields[:Attachment] = fields[:Attachments]
      fields.delete :Attachments
    end
    if fields.has_key? :Attachment
      filenames = fields[:Attachment].split(',')
      attachment_num = 1
      filenames.each do |f|
        payload["attachment_#{attachment_num.to_s}"] = File.new(f)
        attachment_num += 1
      end
      # strip paths from filenames
      fields[:Attachment] = filenames.map {|f| File.basename(f)}.join(',')
    end

    # fixup Text field for RT's quasi-RFC822 form
    if fields.has_key? :Text
      fields[:Text].gsub!(/\n/,"\n ") # insert a space on continuation lines.
    end

    field_array = fields.map { |k,v| "#{k}: #{v}" }
    content = field_array.join("\n") # our form
    payload["content"] = content

    return payload
  end

  # Helper to replace control characters with string representations
  # When some XML libraries hit these in an XML response, bad things happen.
  def sterilize(str)
      str.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      str.gsub!(0x00.chr,'[NUL]')
      str.gsub!(0x01.chr,'[SOH]')
      str.gsub!(0x02.chr,'[STX]')
      str.gsub!(0x03.chr,'[ETX]')
      str.gsub!(0x04.chr,'[EOT]')
      str.gsub!(0x05.chr,'[ENQ]')
      str.gsub!(0x06.chr,'[ACK]')
      str.gsub!(0x07.chr,'[BEL]')
      # 0x08 is backspace
      # 0x09 is TAB
      # 0x10 is line feed
      str.gsub!(0x0B.chr,'[VT]')
      # 0x0c is form feed
      # 0x0d is carriage return
      str.gsub!(0x0E.chr,'[SO]')
      str.gsub!(0x0F.chr,'[SI]')
      str.gsub!(0x10.chr,'[DLE]')
      str.gsub!(0x11.chr,'[DC1]')
      str.gsub!(0x12.chr,'[DC2]')
      str.gsub!(0x13.chr,'[DC3]')
      str.gsub!(0x14.chr,'[DC4]')
      str.gsub!(0x15.chr,'[NAK]')
      str.gsub!(0x16.chr,'[SYN]')
      str.gsub!(0x17.chr,'[ETB]')
      str.gsub!(0x18.chr,'[CAN]')
      str.gsub!(0x19.chr,'[EM]')
      str.gsub!(0x1a.chr,'[SUB]')
      str.gsub!(0x1C.chr,'[FS]')
      str.gsub!(0x1D.chr,'[GS]')
      str.gsub!(0x1E.chr,'[RS]')
      str.gsub!(0x1F.chr,'[US]')
      str
  end

end
