#!/usr/local/bin/ruby

## XML RPC service to provide a cross-platform API for
## RT ticket creation/maintenance.  Essentially just a wrapper
## around the rt/client library.

require "rubygems"             # so we can load gems
require "./rt_client"  # rt-client REST library
require "builder"
require "rack/rpc"
require "date"                 # for parsing arbitrary date formats

# extend the Hash class to 
# translate string keys into symbol keys
class Hash # :nodoc:
  def remapkeys!
    n = Hash.new
    self.each_key do |key|
      n[key.to_sym] = self[key]
    end
    self.replace(n)
    n = nil
    $stderr.puts self.map { |k,v| "#{k} => #{v}" }
    self
  end
end

class TicketSrv < Rack::RPC::Server

  # Allows watchers to be added via RT_Client::add_watcher
  # You need to pass :id, :addr, and optionally :type
  def add_watcher(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.add_watcher(struct)
    rt = nil
    val
  end

  # Gets a list of attachments via RT_Client::attachments
  # You need to pass :id, and optionally :unnamed
  def attachments(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    rt = RT_Client.new
    val = rt.attachments(struct)
    rt = nil
    val
  end

  # Adds comments to tickets via RT_Client::comment
  def comment(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.comment(struct)
    rt = nil
    val
  end

  # Allows new tickets to be created via RT_Client::correspond
  def correspond(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.correspond(struct)
    rt = nil
    val
  end

  # Allows new tickets to be created via RT_Client::create
  def create(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.create(struct)
    rt = nil
    val
  end

  # Allows new users to be created via RT_Client::create_user
  def create_user(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.create_user(struct)
    rt = nil
    val
  end

  # Find RT user details from email address via RT_Cleint::usersearch
  def usersearch(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.usersearch(struct)
    rt = nil
    val
  end

  # Allows new users to be edited or created if they don't exist
  def edit_or_create_user(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.edit_or_create_user(struct)
    rt = nil
    val
  end

  # Allows existing ticket to be modified via RT_Client::edit
  def edit(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.edit(struct)
    rt = nil
    val
  end

  # Retrieves attachments via RT_Client::get_attachment
  def get_attachment(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.get_attachment(struct)
    rt = nil
    val
  end

  # Gets the history of a ticket via RT_Client::history
  def history(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.history(struct)
    rt = nil
    val
  end

  # Gets a single history item via RT_Client::history_item
  def history_item(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.history_item(struct)
    rt = nil
    val
  end

  # Gets a list of tickets via RT_Client::list
  def list(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.list(struct)
    rt = nil
    val
  end

  # Gets a list of tickets via RT_Client::query
  def query(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.query(struct)
    rt = nil
    val
  end

  # Gets detail (minus history/attachments) via RT_Client::show
  def show(struct)
    struct.remapkeys!
    if struct.has_key? :user and struct.has_key? :pass
      rt = RT_Client.new(:user => struct[:user], :pass => struct[:pass])
      struct.delete(:user)
      struct.delete(:pass)
    else
      rt = RT_Client.new
    end
    val = rt.show(struct)
    rt = nil
    val
  end
  
  interface = [ 'add_watcher', 'attachments', 'comment', 'correspond', 'create', 'create_user',
    'edit', 'edit_or_create_user', 'get_attachment', 'history', 'history_item', 'list', 'query',
    'show', 'usersearch' ]
    
  interface.each do |meth|
#    rpc meth => meth.to_sym
    rpc "rt.#{meth}" => meth.to_sym
  end
  
  
end # class TicketSrv

#######################################################

class RTXMLApp
  def call(env)
    [200, {'Content-Type' => 'text/xml'}, ['RT XML-RPC Service']]
  end
end

