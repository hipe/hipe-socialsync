#!/usr/bin/env ruby

require "rubygems"
require File.dirname(__FILE__)+"/markus/cli"
require "hpricot"
require "yaml"

module Markus

  class Wp3Tumblr    

    include Cli::App

    CDATA_RE = /\A<!\[CDATA\[(.*)\]\]>\Z/m    

    def initialize
      cli_pre_init
      @intermediate_filename = 'tmp.wp2tumblr.yml'
      
      @cli_description = "Import your wordpress blogs into tumblr."
      @cli_commands[:help]        = @@cli_common_commands[:help]
      @cli_global_options[:debug] = @@cli_common_options[:debug]
      @cli_commands[:parse_wp_xml] = {
        :description => 'parse wordpress xml into an intermediate yml file.',
        :required_arguments => [
          { :name => :XML_IN, 
            :description => 'an xml file exported from wordpress',
            :validations => [
              {:type=>:file_must_exist},
              {:type=>:regexp, :regexp=>/\.xml\Z/,
               :message=>"Sorry, expecting the file to end in *.xml."
              }
            ],
            :action => {:action=>:open_hpricot}
          }
        ]
      }
      @cli_commands[:push_to_tumblr] = {
        :description => "push the intermediate yml file up to tumblr",
        :required_arguments => [
          {:name=>:tumblr_account_email, :description=>'the email address of your tumblr account'}
        ]
      } # end command push to tumblr
    end # end initialize

    def cli_activate_opt_or_arg_open_hpricot action, var_hash, var_name
      cli_activate_opt_or_arg_open_file({:as=>'r'}, var_hash, var_name)
      @cli_files[var_name][:fh] = Hpricot(cli_file(var_name)) # overwrite
    end

    def cli_execute_parse_wp_xml
      @intermediate_file = File.open(@intermediate_filename,'w')
      _get_articles
    end
    
    # note that here it sort of kills the point of trying to save on memory
    def cli_execute_push_to_tumblr
      struct = YAML::load fh
      self.get_missing_tumblr_args
      self.num_articles_pushed = 0;
      struct[:articles].each do |article|
        self.push_article_to_tumblr(article)
        print "yes:\n"+article[:content]+"\n"
      end
      puts "done pushing #{self.num_articles_pushed} articles to tumblr."      
    end
    
    def _get_articles
      @intermediate_file.write(":articles:\n");
      i = 0;
      h_doc = cli_file(:XML_IN)
      els = h_doc.search('//channel/item')
      obj = {}
      els.each do |item|
        obj[:status] = item.at('wp:status').inner_html
        art_id = item/'wp:post_id'
        if ! (obj[:status] == 'publish'||obj[:status]=='inherit') 
          print "skipping article (##{art_id}) with status of "+obj[:status]+"\n";
          next
        end
        obj[:content] = self.un_cdata( (item/'content:encoded').inner_html )
        if (obj[:content].length == 0)
          print "skipping article (##{art_id}) with empty content (probably an uploaded attachment)\n"
        end                  
        obj[:author] = self.un_cdata( (item/'dc:creator').inner_html )
        obj[:post_date] = (item/'wp:post_date').inner_html
        yaml_obj = YAML::dump( obj )
        s = yaml_obj.to_s
        s.sub!(/\A--- \n/, '');
        s = '- '+s.gsub(/\n(?!\Z)/, "\n  ");
        @intermediate_file.write( s )
        i += 1;
      end # each item
      print "wrote intermediate file \"#{@intermediate_filename}\"." 
    end # def _get_articles    

    def un_cdata str
      matches = CDATA_RE.match(str)
      unless matches
        throw Exception.new(self.truncate("failed to match #{str} against #{self.re.to_s}\n",160))
      end
      return matches[1]
    end # def un_cdata
  end # class Wp3Tumblr
end # module Markus


    #   def _get_keywords
    #     tagstruct = { :tags => [] }
    #     keyword_list = tagstruct[:tags]
    #     # we do it as list in tree not stream style b/c we assume the tag list will never bee too long
    #     (self.doc/:channel/'wp:tag').each do |tag|
    #       slug = (tag/'wp:tag_slug').inner_html
    #       name = self.un_cdata((tag/'wp:tag_name').inner_html)
    #       keyword_list << { :name => name, :slug => slug }
    #     end
    #     yaml_obj = YAML::dump tagstruct
    #     self.intermediate_file.write( yaml_obj.to_s )
    #     self.get_articles
    #   end

#    
#    # ''todo'' move to OptionsParse
#    def get_missing_tumblr_args
#      prompted = false;
#      @backend.tumblr_params.each do |key, arg|
#        next if (:password == key)
#        if (arg[:value].nil?)
#          prompted = true;
#          print key.to_s+" ("+arg[:desc]+")"
#          print " (y/n)" if (arg[:type] == :bool)
#          print " (optional)" unless (arg[:required])
#          print " :"
#          begin
#            repeat = false
#            entry = gets
#            entry.strip!
#            if (:bool==arg[:type] && ! ['y','n'].include?(entry) )
#              unless (!args[:required] && ''==entry)              
#                puts "Please enter 'y' or 'n'.\"#{entry}\" is not a valid answer."
#                repeat = true
#              end
#            elsif (arg[:required] && ''===entry)
#              puts "This is a required field.  Please enter something."
#              repeat = true
#            else
#              @backend.tumblr_params[key][:value] = entry
#            end
#          end while repeat
#        end # if no value for arg
#      end # each arg
#      return prompted
#    end # def

#     :options => {
#       :type => {
#          :value    => 'regular'
#          :validations => [
#            {:type=>:regexp, :regexp=>%r{^(?regular|photo|quote|link|conversation|video|audio)}
#             :message=>"must be regular, photo, quote, link, conversation, video, or audio"
#            }
#          ]
#          #   #regular photo quote link conversation video audio           
#        },
#        :generator => {
#          :default => 'MarkusWp2tumbler version 0.01beta',
#          :description => "i forgot what this is for"
#        },
#        # date, private
#         # :private => 'Whether the post is private. Private posts only appear in the Dashboard or with authenticated links, and do not appear on the blog\'s main page.'
#        :tags => 'Comma-separated list of post tags. You may optionally enclose tags in double-quotes.',
#        :format => {
#          :default => 'html'
#        }

  
# @tumblrArgs = {
#  :password=>nil,:date=>nil,:generator=>nil,:format=>nil,:date=>nil,:private=>nil,:tags=>nil,:type
# }

Markus::Wp3Tumblr.new.cli_run if $PROGRAM_NAME == __FILE__