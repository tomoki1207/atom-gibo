# https://gist.github.com/felixrabe/db88674566e14e413c6f
String::startsWith ?= (s) -> @slice(0, s.length) == s
String::endsWith   ?= (s) -> s == '' or @slice(-s.length) == s 
