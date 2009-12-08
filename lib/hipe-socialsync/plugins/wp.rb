# socsync wp:pull out.yml data/wordpress.rizmo.2009-11-17.xml
require 'nokogiri'           # for parsing responses from xml data from blog services
require 'yaml'               # for representing the intermediate data file
require 'hipe-core/funsummarize'

module Hipe::SocialSync::Plugins
  class Wp
    include Hipe::Cli::App
    cli.does '-h --help'
    def initialize
      @out = cli.out
    end
    cli.does :pull, {
      :description => 'parse wordpress xml into an intermediate yml file.',
      :required => [
        {:name=>:OUTFILE,
         :description=>"the intermediate yaml file.",
         :it=>[:gets_opened]
        }
      ],
      :splat => {
        :name => :XML_IN,
        :minimum => 1,
        :description => 'a list of one or more wordpress XML dump files to take in.',
        :regexp => /\.xml\Z/,
        :regexp_sentence => 'It must end in *.xml',
        :it => [:must_exist, :gets_opened]
      },
      :options => {
        :limit => {
          :description => "only this many will be pulled in from the xml file",
          :range => (0..1000)
        },
        :sort_by => {
          :description => %q{
            during the grab phase it will sort the items in this order for the push phase.  
            Multiple sort-by's may eventually be supported when there are multiple available criteria.  
            Available criteria are: ("post_date"). The criteria must be affixed with 'ascending' or 'descending'.  
            Example: --sort-by="author ascending" --sort-by="post_date descending"}.gsub(/\n */,''),
          :regexp=>/^([_a-z]+) (ascending|descending)$/,
          :regexp_sentence=>%s[must be of the form "FIELD {ascending|descending}"]
        }        
      }
    }
    
    def pull(yaml_file, in_files, opts)
      summary = {
        :skipped => {
          :because_of_status => {},
          :because_of_no_content => 0 },
        :grabbed => 0,
        :number_of_files => 0,
      }
      @limit = opts[:limit]
      @sort_by = opts[:sort_by]
      objects = objects in_files, summary
      file = yml objects, yaml_file
      @out << summarize(summary, yaml_file)
      @out.puts %{\nDone writing entries to "#{yaml_file[:filename]}".}
    end
    
    def yml objects, yaml_file
      if @sort_by
        field, asc_desc = @sort_by
        raise Exception.factory(%{Sorry, we don't recognize the sort-by field "field"}) unless 
         'post_date' == field
        sorter = case asc_desc
          when 'ascending' then Proc.new{|x,y| DateTime.parse(x[symbol]) <=> DateTime.parse(y[symbol]) }
          when 'desceding' then Proc.new{|x,y| DateTime.parse(y[symbol]) <=> DateTime.parse(x[symbol]) }
        end
        objects.sort!(&sorter)
        @out.puts %{Sorted items by date #{field}}
      end
      fh = yaml_file[:fh]
      fh.write(":articles:\n");        
      objects.each do |object|
        yaml_obj = YAML::dump object
        s = yaml_obj.to_s # in order to take this yaml dump and put it inside of another yaml tree...
        s.sub!(/\A--- \n/, ''); # remove this thing from the beginning of the yaml dump..
        s = '- '+s.gsub(/\n(?!\Z)/, "\n  ") # and indent appropriately 
        fh.write s         
      end
      fh.close
      yaml_file
    end # post_process_items    

    def objects in_files, summary
      objects = []
      catch :limit_reached do 
        in_files.each do |file|
          objects += objects_in_file file, summary
        end
      end
      objects
    end
    
    def objects_in_file file, summary
      objects = []
      filename = file[:filename]
      fh = file[:fh]
      @out << %{\n\n#{'='*20} #{Hipe::AsciiTypesetting.wordwrap(filename,38)} #{'='*20}\n}
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
          @out.puts summarizer.minimize(%q{Skipping article #%%#%% because of status "%%status %%"},
          "#" => obj[:art_id],"status "=>obj[:status])
          summary[:skipped][:because_of_status][obj[:status].to_sym] ||= 0
          summary[:skipped][:because_of_status][obj[:status].to_sym] += 1                  
        elsif (obj[:content].length == 0)
          @out.puts summarizer.minimize(
            %{\nSkipping article #%%#%% with empty content (probably an uploaded attachment)},
            '#' => obj[:art_id]
          )
          summary[:skipped][:because_of_no_content] += 1
        else
          @out.puts summarizer.minimize(%{\nGrabbing article #%%#%%},'#' => obj[:art_id])
          summary[:grabbed] += 1
          objects << obj
          if (@limit && summary[:grabbed] >= @limit)
            @out.puts %{\nReached limit of #{@limit} items.}
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
