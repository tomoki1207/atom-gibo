AtomGiboView = require './atom-gibo-view'
{CompositeDisposable} = require 'atom'

path = require 'path'
fs = require 'fs'
execFile = require('child_process').execFile

giboPath = path.join __dirname, '/gibo', if process.platform is 'win32' then '/gibo.bat' else '/gibo'

module.exports = AtomGibo =

  atomGiboView: null
  subscriptions: null

  activate: (state) ->
    fs.chmod giboPath, '755', (err) ->
      if err then console.error "Failed chmod to gibo file\n #{err}"
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
    execFile giboPath, [option], (err, stdout, stderr) =>
      if err?
        console.error "Failed gibo with option\n #{err}"
        @showError err
      else
        @showInfo description, stdout
      callback?()

  doGibo: (arg, destDir, callback) ->
    args = arg.split />+/i
    unless args.length <= 2
      return

    execFile giboPath, [args[0].trim()], (err, stdout, stderr) =>
      if err?
        console.error "Failed gibo\n #{err}"
        @showError err
        callback?()
        return
      msg = if process.platform is 'win32' then stdout else stderr
      if /unknown/i.test(msg)
        console.error "Unknown boilerplate\n #{stdout}"
        @showError stdout
        callback?()
        return

      if arg.trim().startsWith '-'
        @showInfo "gibo #{arg}", stdout
        callback?()
        return

      fileName = args[1]?.trim() ? '.gitignore'
      filePath = path.join destDir ? atom.project.getPaths()[0], fileName
      try
        if /\s+>\s+/i.test(arg)
          fs.writeFile filePath, stdout, (err) =>
            if err and !(err.startsWith('Cloning'))
              console.error "Failed writeFile caused by\n #{err}"
            else
              @showInfo "gibo #{arg}", "Created #{fileName}", false
            callback?()
        else
          fs.appendFile filePath, stdout, (err) =>
            if err
              console.error "Failed appendFile caused by\n #{err}"
            else
              @showInfo "gibo #{arg}", "Updated #{fileName}", false
            callback?()
      catch err
        console.error "Exception occurred when access file\n #{err}"
        @showError err

  showInfo: (title, msg, dismiss = true) ->
    atom.notifications.addInfo "[gibo] #{title}", detail: msg, dismissable: dismiss

  showError: (msg, dismiss = true) ->
    atom.notifications.addError "[gibo] Error", detail: msg, dismissable: dismiss
