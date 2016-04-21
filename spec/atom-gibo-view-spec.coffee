AtomGiboView = require '../lib/atom-gibo-view'
helper = require './spec-helper'

describe "AtomGiboView", ->
  [editor] = []
  beforeEach ->
    editor = new AtomGiboView()

  describe "when constracted", ->
    it "members initialized", ->
      expect(editor.editorElement).not.toBeNull()
      expect(editor.editor).not.toBeNull()
      expect(editor.element).not.toBeNull()

  describe "show()", ->
    it "panel initialized", ->
      editor.show()
      expect(editor.panel).not.toBeNull()
    it "called focus", ->
      spyOn editor, "focus"
      editor.show()
      expect(editor.focus).toHaveBeenCalled()
    it "called show of panel", ->
      editor.show()
      spyOn editor.panel, "show"
      editor.show()
      expect(editor.panel.show).toHaveBeenCalled()

  describe "focus()", ->
    it "called focus of editor element", ->
      spyOn editor.editorElement, "focus"
      editor.focus()
      expect(editor.editorElement.focus).toHaveBeenCalled()

  describe "clear()", ->
    it "clear text", ->
      editor.editor.setText 'not empty'
      expect(editor.editor.getText()).not.toBe ''
      editor.clear()
      expect(editor.editor.getText()).toBe ''

  describe "hide()", ->
    it "called hide of panel", ->
      editor.show()
      spyOn editor.panel, "hide"
      editor.hide()
      expect(editor.panel.hide).toHaveBeenCalled()
    it "clear text", ->
      editor.show()
      spyOn editor, "clear"
      editor.hide()
      expect(editor.clear).toHaveBeenCalled()

  describe "pressed enter into editor", ->
    it "called hide", ->
      editor.show()
      spyOn editor, "hide"
      spy = jasmine.createSpy "enterPressSpy"
      helper.simulateKeyPress editor.editorElement, 'Enter', spy
      waitsFor ->
        spy.callCount > 0
      runs ->
        expect(editor.hide).toHaveBeenCalled()
    it "called callback", ->
      editor.show()
      callback = jasmine.createSpy "callbackSpy"
      editor.callback = callback
      spy = jasmine.createSpy "enterPressSpy"
      helper.simulateKeyPress editor.editorElement, 'Enter', spy
      waitsFor ->
        spy.callCount > 0
      runs ->
        expect(callback.callCount).toBe 1

  describe "pressed escape", ->
    it "call hide", ->
      editor.show()
      spyOn editor, "hide"
      spy = jasmine.createSpy "escapeSpy"
      helper.simulateKeyPress window, 'Escape', spy
      waitsFor ->
        spy.callCount > 0
      runs ->
        expect(editor.hide).toHaveBeenCalled()
