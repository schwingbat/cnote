# CNote
> CLI notes app for Linux (and probably macOS) ((and maybe Windows Subsystem for Linux)) written in Ruby

CNote is my personal system for managing notes. I wanted something snappy and lightweight that would let me search, tag and edit a folder full of markdown files using just my keyboard and some `vim`-ish single-letter commands.

## Changelog

### 0.2.0
- Added `config` command to adjust configuration within CNote. Try: `config set prompt >>>` or `config get editor`, or even just `config` to edit the file directly. Current config properties are `prompt`, `editor`, and `note_path`.

### 0.1.3 and lower
- Trial and error gem publishing-related fixes.

## Installation

First of all, make sure you have a recent version of Ruby installed (including RubyGems). I'm using 2.4.0. Then run:

    $ gem install cnote

## Usage

CNote will be installed as a command on your machine. To get started, run `cnote`. The first time you run `cnote`, you'll be walked through the basic setup process which will produce a `.cnote.yaml` file within your `$HOME` directory. To skip this, just create the file yourself. Valid options for this file are covered [here](#configuration).

```
$ cnote

Hello, new user!
Enter the path to the folder where you would like to store your notes: _
```

Running `cnote` again will drop you into a REPL interface where you can type in commands to interact with your notes. `help` will show the complete list while the program is running.

```
$ cnote

Welcome to CNote! Type 'help' or 'h' to see a list of available commands.
> _
```

Here are the available commands:

### Commands

Keywords surrounded by `<these>` are placeholders. You would enter the real value yourself.

#### `list`
> Aliases: `l`, `ls`

Lists *every single* note in your notes directory (recursively). This might be a lot of notes. To search for something specific, you would use the `find` command.

```bash
> list

    All Notes
    ---------

1.  Note Title
    /subfolder/some-note.md
    tags: [pickle] [fish]

2.  Note Title
    /whatever.md
    <no tags>

3.  ...

    Listed 27 Notes
```

#### `new <file_name>`
> Aliases: `create`, `n`, `c`

Creates a new note with the given filename. If you pass in a nested directory, the directory will be created relative to your `note_path` value from the configuration file.

```bash
> new general/whatever.md
#=> creates file at '$note_path/general/whatever.md'

> create note.jpg
#=> creates file at '$note_path/note.md'
#=> (File extension is ignored. All notes are markdown.)

> c note.md
> n note.md
#=> All aliases do the same thing.
```

#### `edit <note_number>`
> Aliases: `open`, `o`, `e`

Opens the note file in your editor of choice, first looking for the `editor` property in your `.cnote.yaml` config file, and if that fails, uses the `EDITOR` environment variable.

#### `delete <note_number(s)>`
> Aliases: `d`, `rm`

Deletes the note(s) specified by their numbers. The numbers will be whatever number appeared next to that note the last time the notes were listed.

```bash
> delete 12

Are you sure you want to delete note number 12 with title 'Some Title Here'? [y/n] y
Deleted!

> _
```

#### `find <search_term>`
> Aliases: `search`, `s`, `f`

Searches and returns a list of all notes whose title or contents contain the search term. 

```bash
> find cnote
#=> Returns a list of notes whose titles or content match the given term.
#=> Sample output:

    Found 2 Notes
    -------------

1.  CNote Commands
    /cnote/commands.md
    tags: [cnote] [programming]

2.  CNote Sync Backends
    /cnote/cnote-sync.md
    <no tags>

    Listed 2 Notes

> find +t cnote
#=> Returns a list of notes that include the tag 'cnote'
#=> Sample output:

    Found 1 Note
    ------------

1.  CNote Commands
    /cnote/commands.md
    tags: [cnote] [programming]

    Listed 1 Note

> find -t cnote
#=> Returns a list of notes that DO NOT contain the tag 'cnote'

> f project +t cnote
#=> Returns a list of notes that both match the text 'project' AND contain the tag 'cnote'
```

#### `peek <note_number`

Shows a short preview of the note, just to make sure it's the one you're looking for before you commit to editing, tagging, etc.

```bash
> peek 10
> p 10
#=> Shows the first 15 lines of note number 10
```

#### `tag <note_number(s)> <tag> <tag> <tag> ...`
> Aliases: `t`

Adds a space separated list of tags to the note specified by its list number.

```bash
> tag 15 pizza charcoal fishness
#=> Adds ['pizza', 'charcoal', 'fishness'] to the tag list of note number 15

> tag 4,17 double_tag
#=> Adds 'double_tag' to the tag lists of BOTH notes 4 and 17.
```

#### `untag <note_number(s)> <tag> <tag> ...`
> Aliases: `ut`

Removes the space separated list of tags from the note specified by its list number. Works exactly the same as `tag`, but in reverse.

## Configuration

CNote uses a YAML file called `.cnote.yaml` to store your preferences. The file is stored in your home directory and is editable in any text editor. Here are the options:

```yaml
# note_path is the only required property.
# This is the root directory for your notes folder.
note_path: ~/Documents/Notes

# Optionally, you can provide an editor that CNote will 
# open your notes in. This can be any editor that handles
# markdown files: vscode, gedit, emacs, etc...
editor: vim

# prompt can be any string. This will show up just
# before your cursor whenever CNote is waiting for you to
# type something.
prompt: "=> uLtR4Hax <=(🌭)>>"
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
