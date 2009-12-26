#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'hipe-cli'
require 'hipe-core/infrastructure/exception-like'
require 'hipe-core/struct/open-struct-extended'
require 'hipe-core/logic/rules-lite'
require 'dm-core'
require 'dm-aggregates'

module Hipe
  module SocialSync
    VERSION = '0.0.3'
    DIR = File.expand_path('../..',__FILE__)
    module Plugins; end
    module ExceptionUpgrade
      def valid?; false end
    end
    class Exception < Hipe::Exception
      include Hipe::ExceptionLike
      self.modules = [Hipe::SocialSync]
      def self.upgrade(exception)
        return if exception.respond_to? :valid?
        exception.extend ExceptionUpgrage
        exception
      end
      def valid?; false end
    end
    # soft exception and graceful list last seeen in 30db43a9797bd11e41c2616aaefc956e730f7149
    class App
      include Hipe::Cli
      cli.program_name = 'sosy' # necessary b/c when running it from bacon, its name became 'bacon'
      cli.description = 'Import your wordpress blogs into tumblr.'
      cli.option('-e','--env ENV',['test','dev'],'environment', :default=>'dev')
      cli.does '-h','--help' , 'display this help screen (for the sosy app)'
      cli.default_command = :help
      cli.plugins.add_directory(%{#{DIR}/lib/hipe-socialsync/controllers}, Plugins, :lazy=>true)
      cli.config = OpenStruct.new({
        :db => Hipe::OpenStructExtended.new({
          :test => %{sqlite3://#{Hipe::SocialSync::DIR}/data/test.db},
          :dev  => %{sqlite3://#{Hipe::SocialSync::DIR}/data/dev.db}
        })
      })

      def connect!
        unless (connect_string = cli.config.db[@universal_option_values.env])
          raise Exception[%{Couldn't find connect string for evironment setting #{cli.opts.env.inspect}}]
        end
        DataMapper.setup(:default, connect_string)
      end

      # @return [bool] whether or not you actually needed to make a db connection
      def before_run(universal_option_values)
        @universal_option_values = universal_option_values
        return false if DataMapper::Repository.adapters.size > 0
        connect!
        require 'hipe-socialsync/model'
        Hipe::SocialSync::Model.auto_migrate
        true
      end

      def run(argv)
        return catch(:invalid) { cli.run(argv) } # return either the ValidationError or the result
      end

      cli.does('db-rotate', 'move the dev database over') do
        option('-c','--consistent','output the same thing every time (for testing)')
        option('-o','--out-file PATH','write backup database to this file')
      end
      def db_path
        connect_string = cli.config.db[@universal_option_values.env]
        unless(md=%r{^sqlite3://(.*)$}.match(connect_string))
          raise Exception[%{For now this only works for sqlite strings.  Couldn't parse "#{connect_string}"}]
        end
        filename = md[1]
        filename
      end

      def db_rotate(opts)
        filename = db_path
        begin
          if (File.exists?(filename))
            backup = opts.out_file || %{#{filename}.#{DateTime.now.strftime('%Y-%m-%d__%H_%I_%S.db')}}
            FileUtils.mv(filename,backup)
            raise "Rotate only works when we have one (:default) adapter" unless
              DataMapper::Repository.adapters.keys == [:default]
            DataMapper::Repository.adapters.clear # hack1 -- now that it's not on the filesystem we don't want it here
            result = %{Moved #{File.basename(filename)} to }+(opts.consistent ? "backup file." : %{#{backup}.})
            connect!
            Hipe::SocialSync::Model.auto_migrate
          else
            result = %{file #{filename} doesn't exist}
          end
        rescue Errno::ENOENT => e
          result = Exception.upgrade(e)
        end
        Hipe::Io::GoldenHammer[result]
      end
    end

    class GoldenHammer < Hipe::Io::GoldenHammer
      def to_s
        if (data.common_template)
          send(%{#{data.common_template}_template})
        else
          super
        end
      end
      def list_template
        s = Hipe::Io::BufferString.new
        data.list.each do |item|
          s.puts( data.row.call(item) * '' )
        end
        s.puts %{#{data.klass.count} #{Extlib::Inflection.pluralize(data.klass.human_name)}}
        s
      end
    end
  end
end
