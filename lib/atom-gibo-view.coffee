module.exports =
  class AtomGiboView

    constructor: (serializedState, callback) ->
      @element = document.createElement 'div'
      @element.classList.add 'atom-gibo'
      label = document.createElement 'label'
      label.textContent = "gibo:"
      @element.appendChild label
      @editorElement = document.createElement 'atom-text-editor'
      @editor = atom.workspace.buildTextEditor {
        mini: true,
        lineNumberGutterVisible: false,
        placeholderText: 'Type gibo command parameters'
      }
      @editorElement.setModel @editor;
      @editorElement.onkeydown = (e) =>
        if e.keyIdentifier is 'Enter'
          value = @editor.getText()
          @hide()
          @callback?(value)
      @element.appendChild this.editorElement
      @callback = callback

    focus: ->
      @editorElement.focus()

    clear: ->
      @editor.setText ''

    show: ->
      @panel ?= atom.workspace.addModalPanel(item: @element)
      @panel.show()
      window.addEventListener 'keydown', @escapeListener, true
      @focus()

    hide: ->
      @clear()
      @panel.hide()

    escapeListener: (e) =>
      keystroke = atom.keymaps.keystrokeForKeyboardEvent e
      if keystroke is 'escape'
        @hide()
        window.removeEventListener 'keydown', @escapeListener, true

    serialize: ->

    destroy: ->
      @element.remove()

    getElement: ->
      @element
