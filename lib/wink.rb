require 'sinatra'
require 'wink/core_extensions'

# Tell Sinatra to not automatically start a server.
set :run, false

unless reloading?

  # The site's root URL. Note: the trailing slash should be 
  # omitted when setting this option.
  set :url, 'http://localhost:4567'

  # A regular expression that matches URLs to your site's content. Used
  # to detect bookmarks and external content referencing the current site.
  set :url_regex, /http\:/

  # The full name of the site's author.
  set :author, 'Anonymous Coward'

  # The administrator username. You will be prompted to authenticate with
  # this username before modifying entries and comments or providing other
  # administrative activities. Default: "admin".
  set :username, 'admin'

  # The administrator password (see #username). The password is +nil+ by
  # default, disabling administrative access; you must set the password
  # explicitly.
  set :password, nil

  # The site's Akismet key, if spam detection should be performed.
  set :akismet, nil

  # Where to write log messages.
  set :log_stream, STDERR

  # The site's title. Defaults to the author's name.
  set :title, nil

  # Title of area that lists Article entries.
  set :writings, 'Writings'

  # Title of area that lists Bookmark entries.
  set :linkings, 'Linkings'

  # Start date for archives + copyright notice.
  set :begin_date, Date.today.year

end


module Wink
  extend self

  VERSION = '0.2'

  # Application level options.
  def options
    Sinatra.application.options
  end

  # Get an option value.
  def [](option_name)
    options.send(option_name)
  end

  # Set an option value.
  def []=(option_name, value)
    options.send("#{option_name}=", value)
  end

  # Load configuration from the file specified and/or by executing the block. If
  # both a file and block are given, the config file is loaded first and then
  # the block is executed.
  #
  # Database configuration must be in place once the config file and block are
  # processed.
  def configure(file=nil)
    Kernel::load(file) if file
    yield options if block_given?
    require 'wink/models'
    self
  end

  # Load configuration from the file and/or block as specified in Wink#configure
  # and setup Sinatra to start a server instance.
  def run!(config_file=nil, &block)
    configure(config_file, &block)
    require 'wink/web'
    Sinatra.application.options.run = true
  end

  # Rackup compatible constructor. Use in Rackup files as follows:
  #
  #   require 'wink'
  #   run Wink do |config|
  #     config.env = :production
  #     config.url = 'http://example.com'
  #   end
  #
  # If neither a config_file or a block is given, load the default
  # config file: 'wink.conf'.
  def new(config_file=nil, &block)
    config_file ||= 'wink.conf' unless block_given?
    configure(config_file, &block)
    require 'wink/web'
    Sinatra.application
  end

end


class Entry #:nodoc:
end

class Bookmark < Entry
  @delicious = nil
  def self.configure
    require 'delicious'
    @delicious ||= Delicious::Synchronization.new
    yield @delicious if block_given?
    @delicious
  end
end

# DEPRECATED: Weblog will be removed next-release-ish. Use +set+ or
# Wink::options to access configuration variables.
module Weblog
  extend self
  def configure(&block)
    yield Wink.options
  end
  def method_missing(name, *args, &block)
    Wink.options.__send__(name, *args, &block)
  end
end
