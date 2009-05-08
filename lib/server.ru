require 'rack/response'


J = YAML.load(File.read("content.yml"))

MONTHS = %w(stycznia lutego marca kwietnia maja czerwca lipa sierpnia września pażdziernika listopada grudnia)

def tag(body, pattern, replacement)
  body.gsub! %r|<#{pattern}/>|, replacement.to_s
  body.gsub! %r|&#{pattern};|, replacement.to_s
end

def parse(body)
  body.gsub!(%r|<INCLUDE>(.+)</INCLUDE>|) { parse(File.read("files/#{$1}")) }
  
  # wpisy
  body.gsub!(%r|<ENTRY_BLOCK>(.+)</ENTRY_BLOCK>|m) {
    entry_block = $1
    entry_counter = -1
    J[:entries].map {|entry|
      entry_counter += 1 # w 1.8.6 nie ma map.with_index ..
      
      ebody = entry_block.dup
      tag ebody, "ENTRY_SUBJECT", entry[:subject]
      tag ebody, "ENTRY_TITLE", entry[:subject]
      
      tag ebody, "ENTRY_DATE", "#{entry[:date].day} #{MONTHS[entry[:date].month]} #{entry[:date].hour}"
      tag ebody, "ENTRY_DATE_DAY", entry[:date].day
      tag ebody, "ENTRY_DATE_MONTH", MONTHS[entry[:date].month]
      tag ebody, "ENTRY_DATE_YEAR", entry[:date].year
      tag ebody, "ENTRY_HOUR", entry[:date].hour
      
      tag ebody, "ENTRY_ID", rand(100)
      tag ebody, "ENTRY_LEVEL", rand(3)
      
      tag ebody, "ENTRY_CONTENT", entry[:content].sub(%r|<EXCERPT>|, "")
      tag ebody, "ENTRY_CONTENT_LONG", entry[:content].split(%r|<EXCERPT>|).last
      tag ebody, "ENTRY_CONTENT_SHORT", entry[:content].split(%r|<EXCERPT>|).first
      ebody.gsub!(%r|<ENTRY_CONTENT_SHORT_EXIST>(.+)</ENTRY_CONTENT_SHORT_EXIST>|m) { entry[:content]["<EXCERPT>"] ? $1 : "" }
      ebody.gsub!(%r|<ENTRY_CONTENT_SHORT_NOT_EXIST>(.+)</ENTRY_CONTENT_SHORT_NOT_EXIST>|m) { entry[:content]["<EXCERPT>"] ? "" : $1 }
      
      tag ebody, "ENTRY_COMMENT_HREF", "/entry"
      tag ebody, "ENTRY_COMMENT_HREF_DESCR", "3 komentarze"
      tag ebody, "ENTRY_CLASS", "entry#{(entry_counter % 2)+1}"
      entry_counter = 0 if ebody["ENTRY_CLASS_RESET"]
      
      ebody.gsub!(%r|<ENTRY_CATEGORY_BLOCK>(.+)</ENTRY_CATEGORY_BLOCK>|m) {
        category_block = $1
        category_counter = -1
        entry[:categories].map {|category|
          category_counter += 1
          catbody = category_block.dup
          
          tag catbody, "ENTRY_CATEGORY_CLASS", "entrycategory#{(comment_counter % 2)+1}"
          tag catbody, "ENTRY_CATEGORY_HREF", "/za_duzo_bys_chcial"
          tag catbody, "ENTRY_CATEGORY_HREF_DESCR", category
          tag catbody, "ENTRY_CATEGORY_TITLE", category
          catbody.gsub!(%r|<ENTRY_CATEGORY_NOT_LAST>(.+)</ENTRY_CATEGORY_NOT_LAST>|m) { entry_counter == entry[:categories].size ? "" : $1 }
        }.join
      }
      
      

      # tag b, "ENTRY_TRACKBACK_HREF", e
      # tag b, "ENTRY_TRACKBACK_EXIST", e
      # tag b, "ENTRY_TRACKBACK_NOT_EXIST", e
      # tag b, "ENTRY_PREV_EXIST", e
      # tag b, "ENTRY_PREV_NOT_EXIST", e
      # tag b, "ENTRY_PREV_SUBJECT", e
      # tag b, "ENTRY_PREV_TITLE", e
      # tag b, "ENTRY_PREV_CONTENT", e
      # tag b, "ENTRY_PREV_CONTENT_SHORT", e
      # tag b, "ENTRY_PREV_DATE", e
      # tag b, "ENTRY_PREV_HREF", e
      # tag b, "ENTRY_NEXT_EXIST", e
      # tag b, "ENTRY_NEXT_NOT_EXIST", e
      # tag b, "ENTRY_NEXT_SUBJECT", e
      # tag b, "ENTRY_NEXT_TITLE", e
      # tag b, "ENTRY_NEXT_CONTENT", e
      # tag b, "ENTRY_NEXT_CONTENT_SHORT", e
      # tag b, "ENTRY_NEXT_DATE", e
      # tag b, "ENTRY_NEXT_HREF", e
      # tag b, "ENTRY_IS_MINIBLOG", e
      
    
      ebody
    }.join    
  }
  
  body
end

app = Proc.new do |env|
  path = env["REQUEST_URI"]
  
  if path =~ %r[/files/]
    Rack::File.new(Dir.pwd).call(env)
  else
    content = case path
    when "/"
      parse File.read("Szablon wpisów.html")
    when "/entry"
      parse File.read("Szablon komentarzy.html")
    when "/login"
      parse File.read("Szablon logowanie.html")
    else
      path = "strony/#{path.gsub('-', ' ').gsub('/', '').capitalize}.html"
      if File.exists?(path)
        parse File.read(path)
      else
        "NotFound"
      end
    end
    
    [200, {"Content-type" => "text/html"}, content || ""]
  end
  
end

run app