# https://gist.github.com/jish/e9bcd75e391a2b21206b
Promise::finally ?= (onFinally) ->
  @catch (reason) ->
    reason
  .then onFinally
