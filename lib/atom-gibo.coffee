AtomGiboView = require './atom-gibo-view'
{CompositeDisposable} = require 'atom'

path = require 'path'
fs = require 'fs'
execFile = require('child_process').execFile
CSON = require 'season'

isWin32 = () ->
  process.platform is 'win32'

giboPath = path.join __dirname, '/gibo', if isWin32() then '/gibo.bat' else '/gibo'
boilerplatesPath = path.join (if isWin32() then process.env['APPDATA'] else process.env['HOME']), '/.gitignore-boilerplates'

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
    @doGiboWithOption '-u', 'Upgrade Result', @updateSnippets()

  help: ->
    @doGiboWithOption '-h', 'gibo usage'

  doGiboWithOption: (option, description, callback) ->
    @execGiboPromise [option]
    .then (stdout) =>
      @showInfo description, stdout
    .catch (err) =>
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
        return reject msg if /unknown argument/i.test msg
        resolve stdout

  updateSnippets: ->
    filePath = CSON.resolve(path.join(atom.getConfigDirPath(), 'snippets'))

    Promise.all [
      new Promise (resolve, reject) ->
        fs.readdir boilerplatesPath, (err, files) ->
          return reject err if err?
          files = files.map (f) -> path.join(boilerplatesPath, f)
          resolve files.filter (f) -> fs.statSync(f).isFile() and /\.gitignore$/.test(f)
    , new Promise (resolve, reject) ->
        CSON.readFile filePath, (err, obj) ->
          return reject err if err?
          unless obj
            obj ?= {}
            obj['*'] ?= {}
          resolve  obj
      ]
    .then (result) ->
      root = result[1]
      asterisk = root['*']
      for file in result[0]
        basename = (path.basename file).replace '.gitignore', ''
        snippet = asterisk[basename] ?= {}
        snippet.prefix = "gibo-#{basename}"
        content = fs.readFileSync file
        snippet.body = content.toString()
      CSON.writeFileSync filePath, root
    .catch (err) ->
      console.error err
