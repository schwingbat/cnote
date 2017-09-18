require "yaml"
require "fileutils"
require "ap"

class Config
  attr_reader :note_path, :path
  attr_writer :prompt, :editor

  def initialize(path)
    @path = File.expand_path(path)

    if !File.exists?(@path)
      puts "Welcome, new user!"

      @note_path = get_note_path
      save
      puts "Okay, we're ready to go!"
    else
      load
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

  def prompt
    @prompt || ">"
  end

  def set(key, val)
    case key.downcase
    when 'editor'
      @editor = val
    when 'prompt'
      @prompt = val
    end
    save
  end

  def get(key)
    case key.downcase
    when 'editor'
      editor
    when 'prompt'
      prompt
    end
  end

  def save
    File.open(@path, "w") do |file|
      file.write(YAML.dump(to_hash))
    end
  end

  def load
    conf = YAML.load(File.read(@path))

    @note_path = conf["note_path"]
    @editor = conf["editor"]
    @prompt = conf["prompt"]
  end

  def print
    ap to_hash
  end

  def to_hash
    hash = Hash.new
    hash["note_path"] = @note_path if @note_path
    hash["editor"] = @editor if @editor
    hash["prompt"] = @prompt if @prompt
    return hash
  end
end