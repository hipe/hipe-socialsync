#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'hipe-core'
require 'hipe-core/asciitypesetting'
require 'hipe-cli'
require 'hipe-socialsync/model'

module Hipe
  module SocialSync
    
    VERSION = '0.0.2'
    DIR = File.expand_path(File.dirname(__FILE__)+'/../')    

    module Plugins; end # forward-declare it in case their end up being zero plugins or we change the logic it    
    class Exception < Hipe::HipeException; end
    class Cli
      include Hipe::Cli::App     
      def self.run
        begin
          self.new.cli << ARGV
        rescue Hipe::SocialSync::Exception => e
          puts %{Sorry, #{e.message}}
        end
      end
      def self.load_plugins
        plugin_infos = []
        Dir[%{#{DIR}/lib/hipe-socialsync/plugins/*.rb}].each do |filename|
          require filename
          raise Exception.factory(%{filenames for plugins must be lowercase underscored and end in *.rb }+
          %{ -- bad name: "#{filename}}, :type=>'bad_plugin_filename') unless (md = %r{/([a-z_]+)\.rb$}.match(filename))
          lowcase_name = md[1]
          class_name = lowcase_name.gsub(/(?:^|_)[a-z]/){|x| x.upcase}
          plugin_infos << {:name => lowcase_name, :file_name =>filename, :class_name=>class_name}
        end
        plugin_infos.each do |info|
          begin
            const = Plugins.const_get info[:class_name]
          rescue NameError => e
            raise Exception::factory(%{couldn't find plugin "#{info[:name]}" }+
              %{in file "#{info[:file_name]}" -- #{e.message}}, :type=>:plugin_not_found)
          end
          self.cli.plugin info[:name].to_sym, const
        end
      end
      cli.description = 'Import your wordpress blogs into tumblr.'
      cli.does '-h --help'
      begin
        load_plugins
      rescue Hipe::SocialSync::Exception => e
        puts %{Sorry, #{e.message}}
        exit # eww
      end
    end # class
  end # module SocialSync
end # module Hipe
