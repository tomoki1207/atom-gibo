# atom-gibo package

[![Build Status](https://travis-ci.org/tomoki1207/atom-gibo.svg?branch=master)](https://travis-ci.org/tomoki1207/atom-gibo)
[![Build status](https://ci.appveyor.com/api/projects/status/ikrwj5x58fuorl02?svg=true)](https://ci.appveyor.com/project/tomoki1207/atom-gibo)

Using [gibo](https://github.com/simonwhitaker/gibo) from Atom.

(todo: screen shot)

## Usage

### Generate .gitignore

1. Show gibo palette by `Ctrl-Alt-g g`.
1. Type below commands.

  + generate new .gitignore

    `java`  
    or  
    `java > .gitignore`

  + append other boilerplates to .gitignore

    `jboss >> .gitignore`

  + generate as anothor name (like .hgignore)

    `python >> .hgignore`

1. Create/Update your .gitignore **under project root folder**.

### Commands

option | description | default key binding
:---|:---|:---
gibo _[boilerplates]_ | generate .gitignore file | `Ctrl-Alt-g g`
gibo --help | Display gibo help text | `Ctrl-Alt-g h`
gibo --list | List available boilerplates | `Ctrl-Alt-g l`
gibo --upgrade | Upgrade list of available boilerplates | `Ctrl-Alt-g u`

## Contributing

1. Fork it
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Write tests
1. Make your change
1. Run `apm test`
1. Commit your changes (`git commit -am 'Add new feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create new Pull Request

## See also
https://github.com/simonwhitaker/gibo
