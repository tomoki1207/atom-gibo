AtomGiboView = require './atom-gibo-view'
{CompositeDisposable} = require 'atom'

path = require 'path'
fs = require 'fs'
exec = require('child_process').exec

giboPath = path.join __dirname, '..', '/gibo', '/gibo'

module.exports = AtomGibo =

  atomGiboView: null
  subscriptions: null

  activate: (state) ->
    fs.chmod giboPath, 755
    @atomGiboView = new AtomGiboView(state.atomGiboViewState, (arg) => @doGibo(arg))
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'gibo:generate-gitignore': => @createGitignore()
    @subscriptions.add atom.commands.add 'atom-workspace', 'gibo:list-boilerplates': => @list()
    @subscriptions.add atom.commands.add 'atom-workspace', 'gibo:upgrade-boilerplates': => @upgrade()
    @subscriptions.add atom.commands.add 'atom-workspace', 'gibo:display-help-text': => @help()

  deactivate: ->
    @subscriptions.dispose()
    @atomGiboView.destroy()

  serialize: ->
    atomGiboViewState: @atomGiboView.serialize()

  createGitignore: ->
    @atomGiboView.show()

  list: ->
    @doGiboWithOption '-l', 'Available boilerplates'

  upgrade: ->
    @doGiboWithOption '-u', 'Upgrade Result', false

  help: ->
    @doGiboWithOption '-h', 'gibo usage'

  doGiboWithOption: (option, description, callback) ->
    exec "#{giboPath} #{option}", (err, stdout, stderr) =>
      if err?
        console.error err
        @showError err
      else
        @showInfo description, stdout
      callback?()

  doGibo: (arg, destDir, callback) ->
    args = arg.split />+/i
    unless args.length <= 2
      return

    exec "#{giboPath} #{args[0]}", (err, stdout, stderr) =>
      if err?
        console.error err
        @showError err
      else if /unknown/i.test(stdout)
        @showError stdout
      else
        if arg.trim().charAt(0) is '-'
          @showInfo "gibo #{arg}", stdout
        else
          fileName = args[1]?.trim() ? '.gitignore'
          filePath = path.join destDir ? atom.project.getPaths()[0], fileName
          try
            if /\s+>\s+/i.test(arg)
              fs.writeFileSync filePath, stdout
              @showInfo "gibo #{arg}", "Created #{fileName}", false
            else
              fs.appendFileSync filePath, stdout
              @showInfo "gibo #{arg}", "Updated #{fileName}", false
          catch err
            console.error err
            @showError err
      callback?()

  showInfo: (title, msg, dismiss = true) ->
    atom.notifications.addInfo "[gibo] #{title}", detail: msg, dismissable: dismiss

  showError: (msg, dismiss = true) ->
    atom.notifications.addError "[gibo] Error", detail: msg, dismissable: dismiss
