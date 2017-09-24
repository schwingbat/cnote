module Commands
  #/================================\#
  #           The Commands           #
  #\================================/#

  def search(term)
    term = term.downcase.strip # Search is case insensitive
    matches = @notes

    if term.include? "+t"
      term, tags = term.split("+t")
      if tags
        tags = tags.split(" ")
        matches = matches.select do |num, note|
          note != nil && has_tags(note, tags)
        end
      else
        # +t but no tags - return all results that have at least one tag
        matches = matches.select do |num, note|
          note != nil && note.tags.length > 0
        end
      end
    elsif term.include? "-t"
      term, tags = term.split("-t")
      if tags
        tags = tags.split(" ")
        matches = matches.select do |num, note|
          note != nil && does_not_have_tags(note, tags)
        end
      else
        # Likewise, return all results with no tags
        matches = matches.select do |num, note|
          note != nil && note.tags.length == 0
        end
      end
    end

    if term && term != ""
      matches = matches.select do |num, note|
        note.title.downcase.include?(term) || note.content.downcase.include?(term)
      end
    end

    set_filtered(matches)

    # TODO: Sort by most relevant
    # TODO: Highlight keywords where found
    len = matches.length

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
          @notes.each do |num, note|
            if note.path == full_path
              @notes[num] = nil
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

        note.index = @index
        @notes[@index] = note
        @index += 1

        set_filtered([note])
        print_list("Created", @filtered)
      else
        puts "Scrapped the blank note..."
      end
    else
      puts "Please enter a filename as the first parameter"
    end
  end

  def open(params)
    num = params.first.to_i
    note = @notes[num]

    if note
      system "#{@config.editor} '#{note.path}'"
      note.update
    else
      puts "Hey! There is no note #{num}! Nice try."
    end
  end

  def delete(params)
    notes = multi_note(params)

    notes.each do |note|
      if note and File.exists? note.path
        num = note.index
        if confirm("You're #{'sure'.italic} you want to delete note #{num.to_s.bold.white} with title #{note.title.bold.white}?")
          FileUtils.rm(note.path)
          @notes[num] = nil
          @filtered[num] = nil
          puts "Deleted!"
        else
          puts "Whew! That was close."
        end
      end
    end
  end

  def peek(params)
    if params&.first&.downcase == 'config'
      return @config.print
    end

    note = @notes[params.first.to_i]
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

    set_filtered(notes)
    print_list("Changed", @filtered)

    puts "Added #{params.length - 1} tag#{"s" if params.length != 2} to #{notes.length} note#{"s" if notes.length != 1}."
  end

  def untag(params)
    notes = multi_note(params)

    notes.each do |note|
      tags = params.slice(1, params.length)
      note.remove_tags(tags)
    end
    
    set_filtered(notes)
    print_list("Changed", @filtered)

    puts "Removed #{params.length - 1} tag#{"s" if params.length != 2} from #{notes.length} note#{"s" if notes.length != 1}."
  end

  def tags(params)
    if params.empty?
      list_tags
    else
      puts "NOT YET IMPLEMENTED"
    end
  end

  def list_tags
    tags = Hash.new(0)
    longest = 0
    sorted = []

    @notes.each do |num, note|
      note.tags.each do |tag|
        tags[tag] += 1;
      end
    end

    tags.each do |tag, count|
      longest = tag.length if tag.length > longest
      sorted << [tag, count]
    end

    # Sort alphabetically
    sorted.sort_by! { |item| item[0] }

    puts
    puts "#{indent}All Tags".bold
    puts "#{indent}--------"
    puts
    sorted.each do |entry|
      tag, count = entry
      puts "#{indent}#{tag.bold} #{"." * (longest + 3 - tag.length)} #{count} notes"
    end
    puts
  end

  def info(params)
    # Shows metadata about a note or list of notes.
    notes = multi_note(params)
    set_filtered(notes)
    print_list("Note Info", @filtered, true)
    puts "Printed info for #{notes.length} notes."
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
    puts "    - #{"info".bold.white} #{"note_number(s)".italic}"
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
    puts "    - info: i"
    puts "    - list: l, ls"
    puts "    - exit: quit, q, close"
    puts "    - help: h"
    puts
  end

  def list
    set_filtered(@notes)
    print_list("All Notes", @filtered)
  end
end