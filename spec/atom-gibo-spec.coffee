AtomGibo = require '../lib/atom-gibo'
helper = require './spec-helper'

describe "AtomGibo", ->
  [workspaceElement, activationPromise] = []
  beforeEach ->
    workspaceElement = atom.views.getView atom.workspace
    activationPromise = atom.packages.activatePackage 'atom-gibo'

  describe "when the gibo:generate-gitignore event is triggered", ->
    it "shows the modal panel", ->
      expect(workspaceElement.querySelector('.atom-gibo')).not.toExist()
      atom.commands.dispatch workspaceElement, 'gibo:generate-gitignore'
      waitsForPromise ->
        activationPromise
      runs ->
        expect(workspaceElement.querySelector('.atom-gibo')).toExist()
        atomGiboElement = workspaceElement.querySelector '.atom-gibo'
        expect(atomGiboElement).toExist()
        atomGiboPanel = atom.workspace.panelForItem atomGiboElement
        expect(atomGiboPanel.isVisible()).toBe true
    it "shows the view", ->
      jasmine.attachToDOM workspaceElement
      expect(workspaceElement.querySelector('.atom-gibo')).not.toExist()
      atom.commands.dispatch workspaceElement, 'gibo:generate-gitignore'
      waitsForPromise ->
        activationPromise
      runs ->
        atomGiboElement = workspaceElement.querySelector '.atom-gibo'
        expect(atomGiboElement).toBeVisible()

  describe "activated", ->
    it "added comamnds", ->
      commands = (c.name for c in atom.commands.findCommands({target: workspaceElement}))
      expect(commands).toContain 'gibo:generate-gitignore'
      expect(commands).toContain 'gibo:list-boilerplates'
      expect(commands).toContain 'gibo:upgrade-boilerplates'
      expect(commands).toContain 'gibo:display-help-text'

  describe "notifications", ->
    atomGibo = null
    beforeEach ->
      jasmine.attachToDOM workspaceElement
      atom.commands.dispatch workspaceElement, 'gibo:generate-gitignore'
      waitsForPromise ->
        activationPromise
      runs ->
        atomGibo = atom.packages.getActivePackage("atom-gibo").mainModule

    it "shows info", ->
      runs ->
        spyOn atom.notifications, "addInfo"
        atomGibo.showInfo()
        expect(atom.notifications.addInfo).toHaveBeenCalled()
    it "shows error", ->
      runs ->
        spyOn atom.notifications, "addError"
        atomGibo.showError()
        expect(atom.notifications.addError).toHaveBeenCalled()

  describe "list command", ->
    beforeEach ->
      jasmine.attachToDOM workspaceElement

    it "called by command", ->
      atom.commands.dispatch workspaceElement, 'gibo:list-boilerplates'
      waitsForPromise ->
        activationPromise
      runs ->
        atomGibo = atom.packages.getActivePackage("atom-gibo").mainModule
        spyOn(atomGibo, "list").andCallThrough()
        spyOn atomGibo, "doGiboWithOption"
        atom.commands.dispatch workspaceElement, 'gibo:list-boilerplates'
        expect(atomGibo.list).toHaveBeenCalled()
        expect(atomGibo.doGiboWithOption).toHaveBeenCalled()
        expect(atomGibo.doGiboWithOption.calls[0].args[0]).toEqual '-l'

  describe "upgrade command", ->
    it "called by command", ->
      atom.commands.dispatch workspaceElement, 'gibo:upgrade-boilerplates'
      waitsForPromise ->
        activationPromise
      runs ->
        atomGibo = atom.packages.getActivePackage("atom-gibo").mainModule
        spyOn(atomGibo, "upgrade").andCallThrough()
        spyOn(atomGibo, "doGiboWithOption").andCallThrough()
        spyOn atomGibo, "updateSnippets"
        atom.commands.dispatch workspaceElement, 'gibo:upgrade-boilerplates'
        expect(atomGibo.upgrade).toHaveBeenCalled()
        expect(atomGibo.doGiboWithOption).toHaveBeenCalled()
        expect(atomGibo.doGiboWithOption.calls[0].args[0]).toEqual '-u'
        expect(atomGibo.updateSnippets).toHaveBeenCalled()

  describe "help command", ->
    it "called by command", ->
      atom.commands.dispatch workspaceElement, 'gibo:display-help-text'
      waitsForPromise ->
        activationPromise
      runs ->
        atomGibo = atom.packages.getActivePackage("atom-gibo").mainModule
        spyOn(atomGibo, "help").andCallThrough()
        spyOn atomGibo, "doGiboWithOption"
        atom.commands.dispatch workspaceElement, 'gibo:display-help-text'
        expect(atomGibo.help).toHaveBeenCalled()
        expect(atomGibo.doGiboWithOption).toHaveBeenCalled()
        expect(atomGibo.doGiboWithOption.calls[0].args[0]).toEqual '-h'

  describe "generate command", ->
    it "called doGibo() with params when pressed enter", ->
      jasmine.attachToDOM workspaceElement
      atom.commands.dispatch workspaceElement, 'gibo:generate-gitignore'
      waitsForPromise ->
        activationPromise
      runs ->
        atomGibo = atom.packages.getActivePackage("atom-gibo").mainModule
        atomGiboElement = workspaceElement.querySelector '.atom-gibo'
        editor = atomGiboElement.querySelector 'atom-text-editor'
        editor.getModel().setText 'java'
        spyOn atomGibo, "doGibo"
        spy = jasmine.createSpy "enterPressSpy"
        helper.simulateKeyPress editor, 'Enter', spy
        waitsFor ->
          spy.callCount > 0
        runs ->
          expect(atomGibo.doGibo).toHaveBeenCalledWith 'java'

  describe "doGiboWithOption shows info notification", ->
    it "called with optinos", ->
      spyOn AtomGibo, "showInfo"
      spy = jasmine.createSpy "callbackSpy"
      AtomGibo.doGiboWithOption '-l', 'called by spec', spy
      waitsFor ->
        spy.callCount > 0
      runs ->
        expect(AtomGibo.showInfo).toHaveBeenCalled()

  describe "doGibo create gitignore file", ->
    fs = require('fs')
    path = require('path')
    os = require('os')
    fs.mkdirSync './spec/output', '777' if !fs.existsSync './spec/output'
    testDir = path.join './spec/output', helper.randomString(16)
    fs.mkdirSync testDir, '777'
    it "called with 'Java'", ->
      cloneSpy = jasmine.createSpy "cloneSpy"
      AtomGibo.doGibo '-u', testDir, cloneSpy
      waitsFor ->
        cloneSpy.callCount > 0
      , 'waitsfor clone'
      , 10000
      runs ->
        spyOn(fs, "appendFile").andCallThrough()
        spy = jasmine.createSpy "callbackSpy"
        AtomGibo.doGibo 'Java', testDir, spy
        waitsFor ->
          spy.callCount > 0
        runs ->
          file = path.join testDir, '.gitignore'
          expect(fs.existsSync(file)).toBeTruthy()
          expect(fs.appendFile).toHaveBeenCalled()
          expect(helper.fileSize(file)).toBeGreaterThan 0
    it "called with 'Jawa' (unknown param)", ->
      cloneSpy = jasmine.createSpy "cloneSpy"
      AtomGibo.doGibo '-u', testDir, cloneSpy
      waitsFor ->
        cloneSpy.callCount > 0
      , 'waitsfor clone'
      , 10000
      runs ->
        spyOn AtomGibo, "showError"
        spy = jasmine.createSpy "callbackSpy"
        AtomGibo.doGibo 'Jawa', testDir, spy
        waitsFor ->
          spy.callCount > 0
        runs ->
          expect(AtomGibo.showError).toHaveBeenCalled()
    it "called with redirect >", ->
      param = 'Java > .singleRedirection'
      cloneSpy = jasmine.createSpy "cloneSpy"
      AtomGibo.doGibo '-u', testDir, cloneSpy
      waitsFor ->
        cloneSpy.callCount > 0
      , 'waitsfor clone'
      , 10000
      runs ->
        spyOn(fs, "writeFile").andCallThrough()
        spy = jasmine.createSpy "callbackSpy"
        AtomGibo.doGibo param, testDir, spy
        waitsFor ->
          spy.callCount > 0
        runs ->
          file = path.join testDir, '.singleRedirection'
          expect(fs.existsSync(file)).toBeTruthy()
          expect(fs.writeFile).toHaveBeenCalled()
          size = helper.fileSize file
          expect(size).toBeGreaterThan 0
          size = helper.fileSize file
          spy = jasmine.createSpy "callbackSpy"
          AtomGibo.doGibo param, testDir, spy
          waitsFor ->
            spy.callCount > 0
          runs ->
            expect(helper.fileSize(file)).toEqual size
    it "called with redirect >>", ->
      param = 'Java >> .doubleRedirection'
      cloneSpy = jasmine.createSpy "cloneSpy"
      AtomGibo.doGibo '-u', testDir, cloneSpy
      waitsFor ->
        cloneSpy.callCount > 0
      , 'waitsfor clone'
      , 10000
      runs ->
        spyOn(fs, "writeFile").andCallThrough()
        spy = jasmine.createSpy "callbackSpy"
        AtomGibo.doGibo param, testDir, spy
        waitsFor ->
          spy.callCount > 0
        runs ->
          file = path.join testDir, '.doubleRedirection'
          expect(fs.existsSync(file)).toBeTruthy()
          expect(fs.writeFile).toHaveBeenCalled()
          size = helper.fileSize file
          expect(size).toBeGreaterThan 0
          spy = jasmine.createSpy "callbackSpy"
          AtomGibo.doGibo param, testDir, spy
          waitsFor ->
            spy.callCount > 0
          runs ->
            expect(helper.fileSize(file)).toBeGreaterThan size
    it "called with multiple boilerplates", ->
      param = 'Java Jboss > .multipleIgnore'
      cloneSpy = jasmine.createSpy "cloneSpy"
      AtomGibo.doGibo '-u', testDir, cloneSpy
      waitsFor ->
        cloneSpy.callCount > 0
      , 'waitsfor clone'
      , 10000
      runs ->
        spy = jasmine.createSpy "callbackSpy"
        AtomGibo.doGibo param, testDir, spy
        waitsFor ->
          spy.callCount > 0
        runs ->
          file = path.join testDir, '.multipleIgnore'
          expect(fs.existsSync(file)).toBeTruthy()
          size = helper.fileSize file
          expect(size).toBeGreaterThan 0
