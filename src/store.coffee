
##
# Setup Redis to use!
# You are going to need to set the correct REDIS_URL in your environment
# heroku config:set REDIS_URL="$(heroku config:get REDISTOGO_URL)"

Redis = require('redis')
Url = require('url')

Store =
  client: ->
    redisEnvVal = process.env.REDIS_URL || 'redis://localhost:6379'
    redisUrl = Url.parse(redisEnvVal)
    client = Redis.createClient(redisUrl.port, redisUrl.hostname)
    client.on "error", (err) ->
      console.error("RedisError: " + err)
    if redisUrl.auth != null
      client.auth(redisUrl.auth.split(':').pop())
    return client

  find: (id) ->
  create: (attrs) ->
  extended: ->
    @include
      save: ->
        console.log('save')

