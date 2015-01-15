#!/usr/bin/env ruby

$LOAD_PATH << (File.dirname(__FILE__))

require "date"
require 'rss/2.0'
require 'rss/maker'
require 'rss/content'
require "XHtml"

include XHtml

module RSS
  class RDF
    class Item; include ContentModel; end
  end
end 

class BibParse
  def initialize(bf)
    @bibfile = bf

    @entries = Hash.new
    @crossrefs = Hash.new
    @readinglist = Array.new
    @readinglistbytype = Hash.new
    @strs = Hash.new

    @rlkey = 1

    parse
  end

  def cleanup(val)
     val.gsub(/\"/, "").gsub(/[\{\}]/, "").sub(/,\s*$/, "").gsub('\\ ', ' ')
  end
  
  def binsert(bibent, k, v)
      key = k.downcase
      val = v.delete('"{}').
               sub(/,\s*$/, '').
               sub('\\ ', ' ')
      if (@strs[val])
          val = @strs[val]
      end
      
      bibent["#{key}"] = val
  end

  def parse

    bibent = nil
    ref = nil

    IO.foreach("#{@bibfile}") { |l|
      
      if (l =~ /\@(.*)\{\s*(.*?)\s*,/) 
        type = $1
        ref = $2

        bibent = Hash.new
        bibent["type"] = type

      elsif (l =~ /@string\{(.*)\}/i)
        strdef = $1
        if (strdef =~ /(\w+)\s*\=\s*(.*)/)
           strname = $1
           strval = $2
           val = cleanup(strval)
           @strs[strname] = val
        end

#      elsif (l =~ /month\s*=\s*(.*),\s*year\s*=\s*(.*)/)
#          bibent["month"] = $1
#          bibent["year"] = $2

      elsif (l =~ /^\s*(\w+)\s*=\s*(\w+)\s*,\s*(\w+)\s*=\s*(.*)/)
          binsert(bibent, $1,$2)
          binsert(bibent, $3,$4)
          
      elsif (l =~ /\s*(\w+)\s*\=\s*(.*)/)
          binsert(bibent, $1,$2)
      
      elsif (l =~ /^\}/)
        
        if (bibent["type"] == "proceedings")
           @crossrefs[ref] = bibent
        else
           @entries[ref] = bibent
        end
      end
    }

      # collapse crossrefs!
      @entries.each_pair { |ename, edat|
          if (edat["crossref"] && edat["crossref"].length > 0)
              cr = @crossrefs[edat["crossref"]]
              if (cr)
                  cr.keys.each { |k|
                      edat[k] = cr[k]
                  }
              end
          end
      }
  end


  def printHTML(ref, out, item)

      refname = ref[0]
      r = ref[1]
      basename = r["basefilename"]
      sourcelink = r["sourcelink"]
      item.link = "http://www.cs.cmu.edu/~dga/papers/#{basename}-abstract.html"
      item.title = r["title"]
      item.date = Time.parse("#{r["year"]} #{r["month"] || ""}")

      out.puts "<li>"
      titlestring = "<span class=\"title\">#{r["title"]}</span>\n"
      authorstring = "<span class=\"authors\">#{r["author"]}</span>\n"
      out.puts titlestring
      out.puts authorstring
      item.description = titlestring + "<br />" + authorstring + "<br />\n"

      if (r["booktitle"] || r["journal"])

          title = r["booktitle"]?r["booktitle"]:r["journal"]
          mon = r["month"] ? r["month"].capitalize : ""
          year = r["year"] || ""
          bibdat = "In <span class=\"booktitle\">#{title} #{r["howpublished"] || ""}</span>, <span class=\"date\">#{mon} #{year}</span>"
          bibdat += ", pages #{r["pages"]}" if r["pages"]
          bibdat += " (#{r["note"]}) " if r["note"]
          out.puts bibdat
          item.description += bibdat
      elsif (r["type"] == "techreport")
          out.puts span("Technical report, #{r["institution"]} #{r["number"]}",
                        ["class", "booktitle"])
      elsif (r["school"])
          t = ""
          if (r["type"] == "mastersthesis")
              t = "Masters Thesis"
          elsif (r["type"] == "phdthesis")
              t = "Ph.D. Thesis"
          end
          out.puts span("#{t}, #{r["school"]}", ["class", "booktitle"])
      elsif (r["note"] || r["howpublished"])
          n = r["note"] || r["howpublished"]
          n.sub!("\\_", "_")
          if (n =~ /(http:\/\/[^\s]+)/)
              theurl = $1
              n.sub!(theurl, "<a href=\"#{theurl}\">#{theurl}</a>")
          end
          out.puts span(n, ["class", "booktitle"])
      end
      if (basename)
          out.puts span("<a href=\"#{basename}-abstract.html\">Abstract and BibTeX</a>", ["class", "abslink"])
          out.print "<span class=\"downlink\">Download: "
          if (FileTest.exists?(basename))
              out.print "<a href=\"#{basename}\">HTML</a> "
          end
          ["ppt", "pdf", "ps", "txt"].each { |ext|
              fn = basename + "." + ext
              if (FileTest.exists?(fn))
                  out.print "<a href=\"#{fn}\">#{ext}</a> "
              end
          }
          ["ppt", "pdf", "ps"].each { |ext|
              fn = basename + "-slides." + ext
              if (FileTest.exists?(fn))
                  out.print "<a href=\"#{fn}\">Slides (#{ext})</a> "
              end
          }
          out.print "</span>\n"
      end
      if (sourcelink)
         out.print "Source code:  <a href=\"" + sourcelink + "\">" + sourcelink + "</a>"
      end
      out.print "</li>\n"
  end

  def addFilter() 
      @entries.each { |e|
          if (yield e)
              @readinglist << e
          end
      }
  end

  def printList()

      rss = RSS::Maker.make("2.0") do |maker|
          maker.channel.title = "Dave Andersen's Publications"
          maker.channel.description = "List of papers by Dave Andersen"
          maker.channel.link = "http://www.cs.cmu.edu/~dga/papers/"
          maker.encoding = "UTF-8"

          sorted = @readinglist.sort_by { |e| Date.parse("#{e[1]["year"]} #{e[1]["month"] || ""}") }.reverse
          last_year = "xxx"
          sorted.each { |e|
              if (e[1]["year"] != last_year) 
                  if (last_year != "xxx")
                      puts "</ul>\n"
                  end
                  print "<h2 class=\"yearbreak\">#{e[1]["year"]}</h2>\n"
                  puts "<ul class=\"paperlist\">"
                  last_year = e[1]["year"]
              end
              item = maker.items.new_item
              printHTML(e, $stdout, item)
          }
          
          maker.items.do_sort = true
          maker.items.max_size = 200
          puts "</ul>"
      end
      File.open("papers_rss.xml", "w+") do |f|
          f.print rss
      end
  end

end

if $0 == __FILE__
    bp = BibParse.new("./ref.bib")

    bp.addFilter { |e| e[1]["inpage"] && 
            e[1]["inpage"].split(",").include?("dga") }
    bp.printList()

end
