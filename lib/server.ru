require 'rack/response'

def parse(body)
  body.gsub!(%r|<INCLUDE>(.+)</INCLUDE>|) {|e| 
    parse(File.read("files/#{$1}"))
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