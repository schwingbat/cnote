require "yaml"
require "fileutils"

class Config
  attr_reader :note_path

  def initialize(path)
    path = File.expand_path path

    if !File.exists? path
      puts "Welcome, new user!"

      @note_path = get_note_path

      File.open(path, "w") do |file|
        file.write(YAML.dump(to_hash))
      end

      puts "Okay, we're ready to go!"
    else
      conf = YAML.load(File.read(path))

      @note_path = conf["note_path"]
      @editor = conf["editor"]
      @cursor = conf["prompt"]
    end
  end

  def get_note_path
    path = nil

    while !path or !File.exists? path
      print "Enter a path for your note folder: "

      path = File.expand_path gets.chomp
      
      if File.exists? path
        if !File.directory? path
          puts "Hey, that's not a folder!"
        end
      else
        puts "That folder doesn't exist yet. Do you want to create it?"
        case gets.strip.downcase
        when "y", "yes", "yeah", "sure", "ok", "okay", "alright", "yep", "yup"
          FileUtils.mkdir_p path
          puts "Done!"
        else
          puts "Okay."
        end
      end
    end

    return path
  end

  def editor
    @editor || ENV["EDITOR"]
  end

  def cursor
    @cursor || ">"
  end

  def to_hash
    {
      "note_path" => @note_path
    }
  end
end