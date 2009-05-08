require 'mechanize'

class Rubber
  def initialize(args)
    @args = args
    @agent = WWW::Mechanize.new
  end

  def run
    load_config_file
  end

  protected

  def load_config_file
    if File.exists?("config.yml")
      @config = YAML.load(File.read("config.yml"))
    else
      File.open("config.yml", "w") {|f|
        f.write YAML.dump({:jabber_id => "your@jabber.id", :password => "secret"})
      }
      puts "Brak pliku config.yml. Przykładowy plik został utworzony."
      exit
    end

    case @args[0]
    when 'download'
      download
    when 'upload'
      @args.shift
      upload(@args)
    else
      usage
    end
  end

  def download
    login
    get_filemap
    get_pagesmap

    # files
    Dir.mkdir("files") unless File.exists?("files")
    @filemap.each do |filename, url|
      puts "Pobieranie #{filename}"
      
      if confirm(filename)
        File.open(filename, 'wb') {|f| f.write @agent.get(url).body }
      end
    end

    # strony
    Dir.mkdir("strony") unless File.exists?("strony")
    @pagesmap.each do |filename, url|
      puts "Pobieranie #{filename}"
      
      if confirm(filename)
        File.open(filename, 'w') {|f| f.write @agent.get("https://login.jogger.pl#{url}").forms.first.templatesContent }
      end
    end
  end

  def upload(files = [])
    login
    get_filemap
    get_pagesmap

    files.each do |file|
      if url = @pagesmap[file]
        form = @agent.get(url).forms.first
        form.templatesContent = File.read(file)
        form.submit
        puts "Plik #{file} został zaktualizowany"
      elsif url = @filemap[file] || file =~ %r[^files/]
        form = @agent.get('https://login.jogger.pl/templates/files/').forms.first
        form.file_uploads.first.file_name = file
        form.submit
        puts "Plik #{file} został zaktualizowany"
      else
        puts "Plik #{file} nie istnieje"
      end
    end
  end
  
  def confirm(filename)
    if File.exists?(filename) && @args[1] != '--force'
      puts "Plik #{filename} istnieje. Nadpisac? [T/N]"

      loop do
        print "> "
        res = STDIN.gets.chomp.upcase
        
        if res == "T"
          return true
        elsif res == "N"
          return false
        else
          puts "Nie czaje..."
        end
      end
      
    end
    
    return true
  end
  
  def get_pagesmap
    @pagesmap = Hash[*@agent.get('https://login.jogger.pl/templates/edit/').links.select{|e| e.href =~ %r[/templates/edit/\?page_id] }.map {|e| ["strony/#{e.text}.html", e.href]}.flatten]
    @pagesmap["Szablon wpisów.html"] ='/templates/edit/?file=entries'
    @pagesmap["Szablon komentarzy.html"] ='/templates/edit/?file=comments'
    @pagesmap["Szablon logowania.html"] ='/templates/edit/?file=login'
   end

  def get_filemap
    @filemap = Hash[*@agent.get('https://login.jogger.pl/templates/files/').parser.css("td > a").map {|e| ["files/#{e.text}", e[:href]] }.flatten]
  end

  def login
    form = @agent.get('https://login.jogger.pl/login/').forms.first
    form.login_jabberid = @config[:jabber_id]
    form.login_jabberpass = @config[:password]
    page = form.submit

    if page.uri.to_s == 'https://login.jogger.pl/login/'
      puts "Identyfikator jabbera lub hasło jest nieporawne"
      exit
    end
  end

  def usage
    puts <<-USAGE
rubber [action]

Actions:
 download (--force)
 upload [file]
USAGE
    exit
  end

end
