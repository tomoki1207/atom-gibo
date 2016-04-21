module.exports.simulateKeyPress = (element, identifier, callback) ->
  element.addEventListener 'keydown', callback, true
  event = document.createEvent 'KeyboardEvent'
  event.initKeyboardEvent 'keydown', true, true, window, identifier
  element.dispatchEvent event
  event

module.exports.randomString = (len) ->
  require('crypto').randomBytes(Math.ceil(len * 3 / 4))
    .toString('base64')
    .slice(0, len)
    .replace(/\//g, '0')
    .replace(/\+/g, '0')

module.exports.fileSize = (filePath) ->
  require('fs').statSync(filePath)['size']
