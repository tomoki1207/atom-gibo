AtomGiboView = require './atom-gibo-view'
{CompositeDisposable} = require 'atom'

path = require 'path'
fs = require 'fs'
execFile = require('child_process').execFile

isWin32 = () ->
  process.platform is 'win32'

giboPath = path.join __dirname, '/gibo', if isWin32() then '/gibo.bat' else '/gibo'

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
    @doGiboWithOption '-u', 'Upgrade Result'

  help: ->
    @doGiboWithOption '-h', 'gibo usage'

  doGiboWithOption: (option, description, callback) ->
    @execGiboPromise [option]
    .then (stdout) =>
      @showInfo description, stdout
    .catch (err) =>
      console.error err
      @showError err
    .then () => callback?()

  doGibo: (arg, destDir, callback) ->
    args = (arg.split />+/i).map (s) -> s.trim()
    return unless args.length <= 2

    @execGiboPromise (args[0].split /\s/).map (s) -> s.trim()
    .then (stdout) =>
      new Promise (resolve, reject) =>
        return resolve stdout if args[0].startsWith '-'

        fileName = args[1] ? '.gitignore'
        filePath = path.join destDir ? atom.project.getPaths()[0], fileName
        func = if (/\s+>\s+/i.test arg) then fs.writeFile else fs.appendFile
        func filePath, stdout, (err) =>
          return reject err if err and !(err.startsWith('Cloning'))
          resolve "Generated #{filePath}"
    .then (msg) =>
      @showInfo arg, msg
    .catch (err) =>
      console.error err
      @showError err
    .then () => callback?()

  showInfo: (title, msg, dismiss = true) ->
    atom.notifications.addInfo "[gibo] #{title}", detail: msg, dismissable: dismiss

  showError: (msg, dismiss = true) ->
    atom.notifications.addError "[gibo] Error", detail: msg, dismissable: dismiss

  execGiboPromise: (arg) ->
    new Promise (resolve, reject) ->
      execFile giboPath, arg, (err, stdout, stderr) ->
        return reject err if err?
        msg = if isWin32() then stdout else stderr
        return reject msg if /unknown/i.test msg
        resolve stdout
