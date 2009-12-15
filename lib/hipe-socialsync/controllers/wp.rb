# socsync wp:pull out.yml data/wordpress.rizmo.2009-11-17.xml
require 'nokogiri'           # for parsing responses from xml data from blog services
require 'yaml'               # for representing the intermediate data file
require 'hipe-core/funsummarize'

module Hipe::SocialSync::Plugins
  class Wp
    include Hipe::Cli
    cli.out = :golden_hammer
    
    cli.does '-h','--help'
    
    cli.does(:pull,'parse wordpress xml into database.') {
      option('limit', "only this many will be pulled in from the xml file"){
        it.must_be_in_range(0..1000)
      }
      required('xml-in','an xml worpress dumpfile to pull into the database.'){
        it.must_match_regexp(/\.xml\z/,'It must end in *.xml')
        it.must_exist
        it.gets_opened
      }
    }
    
    def pull(xml_in,opts)
      out = cli.out
      @summary = {
        :skipped => {
          :because_of_status => {},
          :because_of_no_content => 0 },
        :grabbed => 0,
        :number_of_files => 0,
      }
      @limit = opts.limit
      objects = objects in_files
      out << summarize(@summary, yaml_file)
      out.puts %{\nDone writing entries to "#{yaml_file[:filename]}".}
      out
    end
    
    def objects in_files
      objects = []
      catch :limit_reached do 
        in_files.each do |file|
          objects += objects_in_file file
        end
      end
      objects
    end
    
    def objects_in_file file
      out = cli.out
      summary = @summary
      objects = []
      filename = file[:filename]
      fh = file[:fh]
      out << %{\n\n#{'='*20} #{Hipe::AsciiTypesetting.wordwrap(filename,38)} #{'='*20}\n}
      begin
        # wordpress dumps are of course not valid xml.  they breakup the rss tag across multiple lines
        doc = Nokogiri::XML(fh ,nil,nil,Nokogiri::XML::ParseOptions::RECOVER) # was STRICT
      rescue Nokogiri::XML::SyntaxError => e
        @out.puts %{ERROR: failed to parse "#{filename}" as well-formed XML! }+
        %{skipping file. Error: "#{e.message.strip}"}
        return objects
      end
      summary[:number_of_files] += 1
      summarizer = Hipe::FunSummarize
      doc.xpath('/rss/channel/item').each do |item_node|
        obj = object_in_nokogiri_node item_node #obj = hpricot_get_item_info(item_node)
        if ! (['publish','inherit'].include?(obj[:status])) 
          out.puts summarizer.minimize(%q{Skipping article #%%#%% because of status "%%status %%"},
          "#" => obj[:art_id],"status "=>obj[:status])
          summary[:skipped][:because_of_status][obj[:status].to_sym] ||= 0
          summary[:skipped][:because_of_status][obj[:status].to_sym] += 1                  
        elsif (obj[:content].length == 0)
          out.puts summarizer.minimize(
            %{\nSkipping article #%%#%% with empty content (probably an uploaded attachment)},
            '#' => obj[:art_id]
          )
          summary[:skipped][:because_of_no_content] += 1
        else
          out.puts summarizer.minimize(%{\nGrabbing article #%%#%%},'#' => obj[:art_id])
          summary[:grabbed] += 1
          objects << obj
          if (@limit && summary[:grabbed] >= @limit)
            out.puts %{\nReached limit of #{@limit} items.}
            throw :limit_reached
          end
        end
      end # each nokogiri item node
      objects
    end # def objects_file 
        
    def object_in_nokogiri_node node
      obj = {}
      obj[:title]       = node.at_xpath('./title').content
      obj[:status]      = node.at_xpath('./wp:status').content
      obj[:art_id]      = node.at_xpath('./wp:post_id').content
      obj[:content]     = node.at_xpath('./content:encoded').content
      obj[:author]      = node.at_xpath('./dc:creator').content
      obj[:post_date]   = node.at_xpath('./wp:post_date').content
      obj[:tags] = []
      node.xpath('./category[@domain="tag" and @nicename]').each do |cat|
      obj[:tags] << cat.content
      end
      obj[:tags] = obj[:tags] * ',' # meh for readability
      obj
    end

    def summarize summary, file
      s = ''
      s << ( "\n\n"+((('='*80)+"\n")*1)+"\nSummary: wrote intermediate file \"#{file[:filename]}\" with:\n" )
      s << "of items in wordpress xml "+ Hipe::FunSummarize.summarize_totals(summary);
      s << "\n"
      s
    end    
  end # end wordpress
end
