# notehub

A CLI for working with [notehub.org](http://notehub.org) from the command line. Very much a work in progress.

    $ notehub help
    NAME
        notehub - A command line interface for Notehub <notehub.org>

    SYNOPSIS
        notehub [global options] command [command options] [arguments...]

    VERSION
        0.0.1

    GLOBAL OPTIONS
        --help    - Show this message
        --version - Display the program version

    COMMANDS
        create - Create a new note
        help   - Shows a list of commands or help for one command
        info   - Retrieve info for a selected note
        update - Update a note
        view   - Open the selected note in the default browser

    $ notehub help create
    NAME
        create - Create a new note

    SYNOPSIS
        notehub [global options] create [command options] [text for new note]

    COMMAND OPTIONS
        -P, --paste        - Create note from pasteboard (OS X only)
        -c, --copy         - Copy resulting url to clipboard
        -f, --file=arg     - Read input from file (default: none)
        --font=arg         - Alternate font to use for note (Google Web Fonts) (default: none)
        --header=arg       - Alternate font to use for headers (Google Web Fonts) (default: none)
        -o, --open         - Open created note in browser
        -p, --password=arg - Password for future edits (default: rattf1nk)
        -s, --short        - Shorten URL
        --theme=arg        - Alternate theme to use for note (dark, solarized-light, solarized-dark) (default: none)

See `notehub help [command]` for additional info.
