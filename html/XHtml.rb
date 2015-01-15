#!/usr/bin/env ruby

module XHtml
    def ea(attrs)
        if attrs && attrs.size > 0
            " " + attrs.map { |x| %Q{#{x[0]}="#{x[1]}"} }.join(" ")
        else
            ""
        end
    end

    def popup_menu(name, values, labels = nil, selected=nil, *attrs)
        if (!selected && self.respond_to?("params") && params[name] &&
            params[name].size > 0)
            selected = params[name].to_s
        end
        s = %Q{<select name="#{name}"#{ea(attrs)}>\n}
        values.each { |v|
            label = labels && labels[v] || v
            sel = ""
            if (selected && (selected == v))
                sel = %q{ selected="selected"}
            end
            s += %Q{<option value="#{v}"#{sel}>#{label}</option>\n}
        }
        s += "</select>\n"
        return s
    end

    def hidden(name, val = nil)
        if (!val && self.respond_to?("params") && params[name] &&
            params[name].size > 0)
            val = params[name].to_s
        end
        %Q{<input type="hidden" name="#{name}" value="#{val}" />}
    end

    def checkbox(name, val = nil, default=nil)
        if (!val && self.respond_to?("params") && params[name] &&
            params[name].size > 0)
            val = params[name].to_s
        end
        if (!val && default) 
            val = default
        end
        extra = ""
        if (val == "on")
            extra = %Q{checked="checked"}
        end
        
        %Q{<input type="checkbox" name="#{name}" value="on" #{extra} />}
    end

    def textfield(name, size=nil, default=nil, *attrs)
        if (!default && self.respond_to?("params") && params[name] &&
            params[name].size > 0)
            default = params[name]
        end
        s = size ? %Q{ size="#{size}"} : ""
        v = default ? %Q{ value="#{default}"} : ""
        %Q{<input name="#{name}" type="text"#{s}#{v}#{ea(attrs)} />}
    end

    def tr(contents, *attrs)
      %Q{<tr#{ea(attrs)}>#{contents}</tr>}
    end
  
    def td(contents, *attrs)
        contents.to_a.map { |x| "<td#{ea(attrs)}>#{x}</td>" }.join("")
    end

    def th(contents, *attrs)
        contents.to_a.map { |x| "<th#{ea(attrs)}>#{x}</th>" }.join("")
    end

   def trtd(contents)
       contents.to_a.map { |x| "<tr>#{td(x)}</tr>" }.join("")
   end
   
   def span(contents, *attrs)
       contents.to_a.map { |x| "<span#{ea(attrs)}>#{x}</span>" }.join("")
   end

   def tag(name, attrs)
       "<" + name + ea(attrs) + ">" +
           if block_given?
               yield
           else
               ""
           end +
           "</" + name + ">"
   end

   def a(href = "") # :yield:
      attributes = if href.kind_of?(String)
                     { "href" => href }
                   else
                     href
                   end
      if block_given?
          tag("a", attributes) { yield }
      else
          tag("a", attributes)
      end
   end



end

if $0 == __FILE__
    include XHtml
    print popup_menu("test", ["one", "two"], nil, "two")
    puts tr("hi", ["param", "value"], ["p2", "v2"])
end

