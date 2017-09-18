require "colorize"
require "fileutils"
require "time"
require "ap"
require "cnote/note"

class Notes
  def initialize(config)
    @config = config
    @notes = Dir[File.join(@config.note_path, "**/*.md")].map { |f| Note.new(f) }
    @filtered = @notes
  end

  #/================================\#
  #          REPL type thing         #
  #\================================/#

  def await_command(message = nil)
    puts message if message
    print "#{@config.prompt} ".magenta
    input = STDIN.gets.chomp

    # Strip and process
    action, *params = input.strip.gsub(/\s{2,}/, " ").split(" ")
    run_command(action || "help", params)
  end

  def run_command(action, params)
    case action.downcase
    when "new", "create", "n", "c"
      create(params)
    when "edit", "open", "e", "o"
      open(params)
    when "delete", "d", "rm"
      delete(params)
    when "peek", "p"
      peek(params)
    when "tag", "t"
      tag(params)
    when "untag", "ut"
      untag(params)
    when "search", "find", "s", "f"
      search(params.join(" "))
    when "list", "l", "ls"
      list
    when "help", "h"
      help
    when "config", "conf"
      config(params)
    when "quit", "exit", "close", "q"
      exit
    else
      puts "Sorry, didn't quite get that..."
      help
    end

    await_command # Drop back to REPL
  end

  #/================================\#
  #           The Commands           #
  #\================================/#

  def search(term)    
    term = term.downcase # Search is case insensitive
    matches = @notes

    if term.include? "+t "
      term, tags = term.split("+t ")
      tags = tags.split(" ")
      puts "\n    Searching: '#{term.strip}' with tags: #{tags}"
      matches = matches.select do |note|
       has_all_tags(note, tags)
      end
    elsif term.include? "-t "
      term, tags = term.split("-t ")
      tags = tags.split(" ")
      puts "\n    Searching: '#{term.strip}' without tags: #{tags}"
      matches = matches.select do |note|
        has_none_tags(note, tags)
      end
    end

    term.strip!

    @filtered = matches.select do |note|
      note.title.downcase.include?(term) || note.content.downcase.include?(term)
    end

    # TODO: Sort by most relevant
    # TODO: Highlight keywords where found
    len = @filtered.length

    print_list("Found #{len} Match#{"es" if len != 1}", @filtered)
  end

  def create(params)
    if params.first
      dirname = File.dirname(params.first)
      new_filename = File.basename(params.first, File.extname(params.first)) + ".md"
      rel_path = ""
      tags = []

      if params.include? "+t"
        tags = params.slice(params.index("+t") + 1, params.length)
        puts "CREATING WITH TAGS: #{tags}"
      end

      if dirname != "."
        rel_path = dirname
          .gsub(@config.note_path, "")
          .gsub(File.basename(params.first), "")
      end

      full_path = File.join(@config.note_path, rel_path, new_filename)

      if File.exists?(full_path)
        if confirm("#{"Whoa!".bold.red} That file already exists. Overwrite it?")
          File.delete(full_path)
          @notes.each do |note|
            if note.path == full_path
              @notes.delete(note)
              puts "Removed!"
            end
          end
        else
          return
        end
      else
        # Make sure the directory actually exists.
        FileUtils.mkdir_p(File.join(@config.note_path, rel_path))
      end

      system "#{@config.editor} '#{full_path}'"

      if File.exists?(full_path)
        note = Note.new(full_path)
        note.add_tags(tags) if tags.length > 0
        note.created = Time.new
        note.update

        @notes << Note.new(full_path)

        print_list("Created", [note])
        @filtered = [note]
      else
        puts "Scrapped the blank note..."
      end
    else
      puts "Please enter a filename as the first parameter"
    end
  end

  def open(params)
    num = params.first.to_i
    note = @filtered[num - 1]

    if note
      system "#{@config.editor} '#{note.path}'"
      note.update
    else
      puts "Hey! There is no note #{num}! Nice try."
    end
  end

  def delete(params)
    num = params.first.to_i
    note = @filtered[num - 1]

    if note and File.exists? note.path
      if confirm("You're #{'sure'.italic} you want to delete note #{num.to_s.bold.white} with title #{note.title.bold.white}?")
        FileUtils.rm(note.path)
        @notes.delete(note)
        @filtered.delete(note)
        puts "Deleted!"
      else
        puts "Whew! That was close."
      end
    else
      puts "Looks like my job is done here, since note #{num} doesn't exist anyway!"
    end
  end

  def peek(params)
    if params&.first&.downcase == 'config'
      return @config.print
    end

    note = @filtered[params.first.to_i - 1]
    if note
      lines = note.content.lines
      puts
      puts "-" * 40
      puts note.title.bold.white
      puts lines.slice(0, 15)
      if lines.length > 15
        puts
        puts "(#{lines.length - 15} more line#{'s' if lines.length != 16}...)".italic
      end
      puts "-" * 40
      puts
    else
      puts "Note doesn't exist!"
    end
  end

  def tag(params)
    notes = multi_note(params)

    notes.each do |note|
      tags = params.slice(1, params.length)
      note.add_tags(tags)
    end

    print_list("Changed", notes)

    @filtered = notes

    puts "Added #{params.length - 1} tag#{"s" if params.length != 2} to #{notes.length} note#{"s" if notes.length != 1}."
  end

  def untag(params)
    notes = multi_note(params)

    notes.each do |note|
      tags = params.slice(1, params.length)
      note.remove_tags(tags)
    end
    
    print_list("Changed", notes)

    @filtered = notes

    puts "Removed #{params.length - 1} tag#{"s" if params.length != 2} from #{notes.length} note#{"s" if notes.length != 1}."
  end

  def config(params = [])
    if params.length == 0
      system "#{@config.editor} #{@config.path}"
      @config.load
      return
    end

    action, key, *value = params
    value = value.join(" ")

    if action == "get"
      if key
        puts "#{key}: \"#{@config.get(key)}\""
      else
        @config.print
      end
    elsif action == "set"
      if key
        if value
          puts "Config: #{key} changed from '#{@config.get(key)}' to '#{value}'"
          @config.set(key, value)
        else
          puts "Can't set a key to a value if no value is given."
        end
      else
        puts "Can't set a key if one wasn't given."
      end
    else
      puts "Invalid action: #{action}"
    end
  end

  def help
    puts
    puts "Enter a command with the structure:"
    puts "    #{@config.prompt} action parameter(s)"
    puts
    puts "Actions:"
    puts "    - #{"new".bold.white} #{"filename".italic}"
    puts "    - #{"edit".bold.white} #{"note_number".italic}"
    puts "    - #{"delete".bold.white} #{"note_number".italic}"
    puts "    - #{"peek".bold.white} #{"note_number".italic}"
    puts "    - #{"tag".bold.white} #{"note_number".italic}"
    puts "    - #{"untag".bold.white} #{"note_number".italic}"
    puts "    - #{"search".bold.white} #{"search_term".italic}"
    puts "    - #{"list".bold.white}"
    puts "    - #{"config".bold.white} #{"(set/get)".italic} #{"key".italic} [#{"value".italic}]"
    puts "    - #{"exit".bold.white}"
    puts "    - #{"help".bold.white}"
    puts
    puts "Alternate actions:"
    puts "  Most actions also have aliases that do the same thing."
    puts "  These are listed for each command:"
    puts "    - new: create, c, n"
    puts "    - edit: e, open, o"
    puts "    - delete: d, rm"
    puts "    - peek: p"
    puts "    - tag: t"
    puts "    - untag: ut"
    puts "    - search: find, f, s"
    puts "    - list: l, ls"
    puts "    - exit: quit, q, close"
    puts "    - help: h"
    puts
  end

  def list
    @filtered = recently_edited_first(@notes)
    print_list("All Notes", @filtered)
  end

  #/================================\#
  #             Utilities            #
  #\================================/#

  private def print_list(title, notes)
    path_length = @config.note_path.split("/").length
    i = 0

    puts
    puts "    #{title}".bold
    puts "    #{"-" * title.length}"
    puts

    notes.each do |note|
      i += 1
      puts "#{i}.".ljust(4) + note.title.bold
      puts "    #{note.path.gsub(@config.note_path, "")}".italic.light_magenta
      if note.tags.length > 0
        tags = note.tags.map { |tag| tag.yellow }
        puts "    tags: " + "[#{tags.join('] [')}]"
      else
        puts "    <no tags>"
      end
      puts "    modified: " + note.modified.strftime("%a, %b %e %Y, %l:%M%P").italic
      puts "    created:  " + note.created.strftime("%a, %b %e %Y, %l:%M%P").italic
      puts
    end

    puts "    Listed #{i.to_s.bold} Notes"
    puts
  end

  private def confirm(message = "Confirm")
    print "#{message} [y/n]: "
    case gets.chomp.strip.downcase
    when "y", "yes", "yeah", "sure", "yep", "okay", "aye"
      return true
    when "n", "no", "nope", "nay"
      return false
    else
      return confirm("Sorry, didn't quite get that...")
    end
  end

  private def multi_note(params)
    notes = []

    params.first.split(",").each do |num|
      note = @filtered[num.to_i - 1]
      if note
        notes << note
      else
        puts "Note #{num} doesn't exist!"
      end
    end

    notes
  end

  private def recently_edited_first(notes)
    notes.sort_by { |note| note.modified }.reverse
  end

  private def has_all_tags(note, tags)
    has = true
    note_tags = note.tags
    tags.each do |tag|
      if !note_tags.include? tag
        has = false
        break
      end
    end
    has
  end

  private def has_none_tags(note, tags)
    doesnt_have = true
    note_tags = note.tags
    tags.each do |tag|
      if note_tags.include? tag
        doesnt_have = false
        break
      end
    end
    doesnt_have
  end
end