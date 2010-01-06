#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'pathname'
require 'hipe-cli'
require 'hipe-core/infrastructure/exception-like'
require 'hipe-core/loquacious/all'
require 'hipe-core/struct/hash-like-with-factories'
require 'hipe-core/struct/open-struct-extended'
require 'hipe-core/struct/table'
require 'hipe-core/lingual/ascii-typesetting'
require 'hipe-core/lingual/en'
require 'dm-core'
require 'dm-aggregates'

module Hipe
  module SocialSync
    VERSION = '0.0.3'
    DIR = File.expand_path('../..',__FILE__)
    module Plugins; end
    class Exception < Hipe::Exception
      include Hipe::ExceptionLike
      self.modules = [Hipe::SocialSync]
      def valid?; false end
    end
    module ViewCommon
      include Hipe::AsciiTypesetting::Methods
      include Hipe::Lingual::English
      def date_format at
        at.strftime '%Y-%m-%d %H:%I:%S'
      end
      def humanize_lite str
        str.to_s.gsub '_', ' '
      end
      # If you want to display a path but don't want to risk revealing the absolute path
      #
      def relativize_path path
        base_dir = Pathname.new(File.expand_path(DIR))
        other_dir = Pathname.new(File.expand_path(path))
        other_dir.relative_path_from base_dir
      end
    end
    module ControllerCommon
      def current_user(identifier)
        return identifier if identifier.kind_of? Model::User
        Hipe::SocialSync::Model::User.first_or_throw :email=>identifier
      end
      def argument_error(*args)
        throw :invalid, Model::ValidationErrors[*args]
      end
    end
    # it is likely that anything we add here we might want to push up.  consider making a common
    # template api.

    class Transports < Hipe::HashLikeWithFactories
      # Transports are objects that talk to external services.
      # This models a collection of all the available transports.
      # The individual transport classes will register themselves with this class when they are loaded
      #
      def new_instance(name)
        self[name].class.new
      end
      def load_all
        path = File.join(DIR,'lib','hipe-socialsync','transport')
        Dir.new(path).map{|entry| /^(.+)\.rb$/=~ entry ? $1 : nil}.compact.each do |basename|
          require_me = File.join('hipe-socialsync','transport',File.basename(basename))
          require require_me
        end
      end
    end

    class GoldenHammer < Hipe::Io::GoldenHammer
      # This is for when to_s is called on a GoldenHammer that has a suggested_template of "tables"
      # This is just a default rendering strategy for ascii contexts (command-line.)
      # A web client should render the table(s) itself.
      def render_tables
        lines = []
        data.tables.each do |table|
          lines << table.render(:ascii)
        end
        lines.concat all_messages
        lines * "\n"
      end
    end
    class App
      include Hipe::Cli
      cli.program_name = 'sosy' # necessary b/c when running it from bacon, its name became 'bacon'
      cli.description = 'Import your wordpress blogs into tumblr.'
      cli.option('-e','--env ENV',['mu','test','dev'],'environment', :default=>'dev')
      cli.does '-h','--help' , 'display this help screen (for the sosy app)'
      cli.default_command = :help
      cli.out.klass = GoldenHammer
      cli.plugins.add_directory(%{#{DIR}/lib/hipe-socialsync/controllers}, Plugins, :lazy=>true)
      cli.config = OpenStruct.new({
        :db => Hipe::OpenStructExtended.new({   # @todo Gash
          :test => %{sqlite3://#{Hipe::SocialSync::DIR}/data/test.db},
          :dev  => %{sqlite3://#{Hipe::SocialSync::DIR}/data/dev.db}
        })
      })

      def initialize(startup_argv=nil)
        if (startup_argv)
          @prepend = startup_argv.dup
        else
          @prepend = []
        end
      end

      def transports
        @transports ||= Transports.new
      end

      def db_path
        connect_string = cli.config.db[@univ.env]
        unless(md=%r{^sqlite3://(.*)$}.match(connect_string))
          raise Exception[%{For now this only works for sqlite strings.  Couldn't parse "#{connect_string}"}]
        end
        filename = md[1]
        filename
      end

      # @return [String] a string (ending in a '/' ?) that corresponds to the root folder where
      #   (usually writable) data is kept.  This should be the folder *that contains* the folder called data,
      #   because at the time of this writing, writable folders exist elsewhere other than just under data/
      #   Also at the time of this writing, this folder is always the root folder of the whole project.
      #   (This is not to say that the root of the project is writable, just that it may contain arbitrary
      #   folders that are writable, and there are no writable folders that exist outside of this folder.)
      def data_path; DIR end

      def db_connect
        return false if DataMapper::Repository.adapters.size > 0
        connect_string = cli.config.db[@univ.env]
        DataMapper.setup(:default, connect_string)
        require 'hipe-socialsync/model'
      end

      def before_run(univ)
        @univ = univ
        db_connect
      end

      def run(argv)
        argv.unshift(*@prepend)
        return catch(:invalid) do
          DataMapper.repository do
            cli.run(argv)
          end
        end # return either the ValidationError or the result
      end

      cli.does('ping','the minimal action') do
        option('--db','try connecting')
      end
      def ping(opts)
        out = cli.out.new
        out << 'Hello.'
        out << %{  My environment is "#{opts.env}".}
        if (opts.db)
          db_connect
          out << %{  My database file is "#{File.basename(db_path)}".}
        end
        out
      end
    end
  end # SocialSync
end # Hipe
# list template and table template last seen 84ab091a03b144f67f99f49ef8d1316c6d6f48b7
# ExceptionUpgrade last seen 84ab091a03b144f67f99f49ef8d1316c6d6f48b7
# soft exception and graceful list last seen 30db43a9797bd11e41c2616aaefc956e730f7149
