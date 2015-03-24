# Description:
#   Team members enter their scrum and scrumbot will send a summary.
#
# Dependencies:
#    "cron": "",
#    "time": ""
#
# Configuration:
#   HUBOT_SCRUM_ROOM
#   HUBOT_SCRUM_NOTIFY_AT
#   HUBOT_SCRUM_CLEAR_AT
#   TZ # eg. "America/Los_Angeles"
#
# Commands:
#   hubot scrum
#   hubot what is <username> doing today?
#   hubot scrum help
#
# Optional Environment Variables:
#   TIMEZONE
#
# Notes:
#   We were sad to see funscrum die so we are making this now!
#
# Authors:
#   @jpsilvashy
#   @mmcdaris

##
# What room do you want to post the scrum summary in?
ROOM = process.env.HUBOT_SCRUM_ROOM

##
# Explain how to use the scrum bot
MESSAGE = """
 USAGE:
 hubot scrum                            # start your scrum
 hubot what is <username> doing today?  # look up other team member scrum activity
 hubot scrum help                       # displays help message
"""

##
# Set to local timezone
TIMEZONE = process.env.TZ

##
# Default scrum reminder time
REMIND_AT = process.env.HUBOT_SCRUM_REMIND_AT || '0 0 6 * * *' # 6am everyday

##
# SEND the scrum at 10 am everyday
NOTIFY_AT = process.env.HUBOT_SCRUM_NOTIFY_AT || '0 0 10 * * *' # 10am

REQUIRED_CATEGORIES = ["today", "yesterday"]

##
# Setup cron
CronJob = require("cron").CronJob

##
# Set up your free mailgun account here: TODO
# Setup Mailgun
Mailgun = require('mailgun').Mailgun
mailgun = new Mailgun(process.env.HUBOT_MAILGUN_APIKEY)
FROM_USER = process.env.HUBOT_SCRUM_FROM_USER || "noreply+scrumbot@example.com"

console.log("scrum loaded!")

##
# Setup Handlebars
Handlebars = require('handlebars')

# Setup Redis to use!
# You are going to need to set the correct REDIS_URL in your environment
# heroku config:set REDIS_URL="$(heroku config:get REDISTOGO_URL)"
##
Redis = require('redis')
Url = require('url')
redisEnvVal = process.env.REDIS_URL || 'redis://localhost:6379'
redisUrl = Url.parse(redisEnvVal)

client = Redis.createClient(redisUrl.port, redisUrl.hostname)
client.on "error", (err) ->
  console.error("RedisError: " + err)

if redisUrl.auth != null
  client.auth(redisUrl.auth.split(':').pop())

##
# Robot
module.exports = (robot) ->

  ##
  # Make sure the scrum object is set
  robot.brain.data.scrum ?= {}

  # Scrum!
  scrum =
    # FIXME: This should take a user object
    # and return the total points they have
    # there are a few ways to do this:
    #   - we just find the last scrum they participated
    #     in copy it and add 10 points, this makes it hard
    #     to account for bonus points earned for consecutive
    #     days of particpating in the scrum
    #   - we scan back and total up all their points ever, grouping
    #     the consecutive ones and applying the appropriate bonus points
    #     for those instances

    ##
    # Adds the user's entry to the category
    #
    entry: (user, category, message) ->
      @.givePoints(user, category)
      key = user + ":" + category
      client.lpush(key, message)

    # if the user has filled out a required category...
    givePoints: (user, category) ->
      key = user + ":" + category
      unless client.exists(key) is 0 and REQUIRED_CATEGORIES.indexOf(category)
        client.zadd("scrum", 5, user)

    # takes a user and a callback
    # the callback is going to receive the score for the user
    getScore: (user, fn) ->
      client.zscore("scrum", user.name, (err, scoreFromRedis) ->
        if scoreFromRedis
          user.score = scoreFromRedis
          fn(user)
        else
          console.log(
            "getScoreError: didn't get a response got \' #{scoreFromRedis} \'\n" + "User was: #{user.name}"
          )
      )

    # TODO: JP
    # Fix me! maybe use promises here?
    getScores: (users, fn) ->
      for user in users
        client.zscore("scrum", user.name, (err, scoreFromRedis) ->
          if scoreFromRedis
            user.score = scoreFromRedis
          else
            console.log(
              "getScoreError: didn't get a response got \' #{scoreFromRedis} \'\n" + "User was: #{user.name}"
            )
        ).then(fn(users))

    ##
    # Particpating in the scrum currently depends on hubot-auth and the
    # user having the role of "scrum". To add the "scrum" role to a user
    # you can say `hubot <username> has scrum role`
    participants: ->
      scrumUsers = []
      for own key, user of robot.brain.data.users
        roles = user.roles or []
        if 'scrum' in roles
          scrumUsers.push user
      return scrumUsers

    ##
    # Just return a key for the current day ie 2015-4-5
    date: ->
      new Date().toJSON().slice(0,10)

    today: ->
      new Date().toJSON().slice(0,10)

    ##
    # Mail the scrum participants
    mail: ->
      addresses = scrum.participants().map (user) -> "#{user.name} <#{user.email_address}>"
      mailgun.sendText FROM_USER, [
        # addresses
      ], "Daily Scrum", status.summary() , "noreply+scrumbot@example.com", {}, (err) ->
        if err
          console.log "[mailgun] Oh noes: " + err
        else
          console.log "[mailgun] Success!"
        return



  ##
  # Messages presented to the channel, via DM, or email
  status =
    personal: (user) ->
      source = """
        =------------------------------------------=
        hey {{user}}, You have {{score}} points.
        =------------------------------------------=
      """
      template = Handlebars.compile(source)
      template({ user: user.name, score: user.score })

    leaderboard: (users) ->
      source = """
        =------------------------------------------=
        Hey team, here is the leaderboard:
        {{#each users}}
          {{name}}: {{score}}
        {{/each}}
        =------------------------------------------=
      """
      template = Handlebars.compile(source)
      template({ users: users })

    summary: (users)->
      source = """
        =------------------------------------------=
        Scrum Summary for {{ day }}:
        {{#each users}}
          {{name}}
          today: {{today}}
          yesterday: {{yesterday}}
          blockers: {{blockers}}
        {{/each}}
        =------------------------------------------=
      """
      template = Handlebars.compile(source)
      # Users will be users:[{name:"", today:"", yesterday:"", blockers:""}]
      template({users: users, date: scrum.today()})

  ##
  # Define things to be scheduled
  schedule =
    reminder: (time) ->
      new CronJob(time, ->
        scrum.remind()
        return
      , null, true, TIMEZONE)

    notify: (time) ->
      new CronJob(time, ->
        robot.brain.data.scrum = {}
        return
      , null, true, TIMEZONE)
    # set up seasons

  # ======================================================================== #
  #                           Experiment Here!                               #
  # ======================================================================== #

  class User
    constructor: (@name, @score = 0) ->

    getScore: ->
      updateScore()
      return @score

    setScore: (redis_score) =>
      console.log("Setting Score to #{redis_score} from #{@score}")
      @score = redis_score

    updateScore: ->
      client.zscore("scrum", @name, (err, resp) ->
        console.log("I am in updateScore, resp is: #{resp}")
        return @.setScore(resp)
      )

    awardPoints: ->
      client.zadd("scrum", 10, @name)

    stats: ->
      console.log("#{@name} has #{@points} Points!")

    today: (message) ->
      scrum.entry(@name, "today", message)

    yesterday: (message) ->
      scrum.entry(@name, "yesterday", message)

    blockers: (message) ->
      scrum.entry(@name, "blockers", message)

  jp = new User "jp"
  jp.today("Dishes!")
  jp.blockers("Too many bottle caps in the garbage disposal")
  jp.yesterday( "Partied!!!!")
  jp.awardPoints

  andrew = new User "andrew"
  andrew.today("Watched videos and played some games, fostdom")
  andrew.blockers("None!  more work! Bring it on!")
  andrew.yesterday("Paired with JP and fixed the computer box!")
  andrew.awardPoints()

  users = [jp, andrew]

  # it's alive!
  printPersonalStatus = (user) ->
    console.log( status.personal(user) )

  scrum.getScore( user, printPersonalStatus ) for user in users


  printLeaderboard = (users) ->
    console.log( status.leaderboard(users) )

  # TODO: JP make this work:
  # scrum.getScores( users, printLeaderBoard )


  # ======================================================================== #
  #                           Stop Experimenting                             #
  # ======================================================================== #

  # Schedule the Reminder with a direct message so they don't forget
  # Don't send this if they already sent it in
  # instead then send good job and leaderboard changes + streak info
  schedule.reminder REMIND_AT

  ##
  # Schedule when the order should be cleared at
  schedule.notify NOTIFY_AT

  ##
  # Handle user input
  robot.hear /start scrum/i, (msg) ->
    list = scrum.participants().map (user) -> "#{user.name}: #{scrum.getPoints(user)}"
    msg.send list.join("\n") || "Nobody is in the scrum!"
    console.log("What are you doing today?")

  ##
  # Responds with details about my user
  robot.hear /scrum my status/i, (msg) ->
    console.log(msg.message.user)
    msg.send status.personal(msg.message.user)

  ##
  # Responds with details about my user
  robot.hear /scrum/i, (msg) ->
    console.log(msg.message.user)
    msg.send status.personal(msg.message.user)

  ##
  # Responds with the points for everyone on the team
  robot.hear /scrum leaderboard/i, (msg) ->
    msg.send status.leaderboard(scrum.participants())

  robot.hear /andrew score/i, (msg) ->
    msg.send "Andrew has #{andrew.points} name: #{andrew.name}"

  robot.hear /scrum summary/i, (msg) ->
    msg.send status.summary(scrum.participants())
