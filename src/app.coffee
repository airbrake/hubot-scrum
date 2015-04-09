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

##
# Setup Handlebars
Handlebars = require('handlebars')

# Models
Team = require('./models/team')
Player = require('./models/player')
Scrum = require('./models/scrum')

##
# Robot
module.exports = (robot) ->

  ## 
  # Initialize the scrum
  scrum = new Scrum(robot)

  ##
  # Define the schedule
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

  # Schedule the Reminder with a direct message so they don't forget
  # Don't send this if they already sent it in
  # instead then send good job and leaderboard changes + streak info
  schedule.reminder REMIND_AT

  ##
  # Schedule when the order should be cleared at
  schedule.notify NOTIFY_AT
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
  

  robot.respond /scrum players/i, (msg) ->
    list = scrum.players().map (player) -> "#{player.name}: #{player.score}"
    msg.reply list.join("\n") || "Nobody is in the scrum!"

  robot.respond /scrum prompt @?([\w .\-]+)\?*$/i, (msg) ->
    name = msg.match[1].trim()
    player = scrum.player(name)
    scrum.prompt(player, "yay")

  # setInterval ->
  #   for player in scrum.players()
  #     scrum.prompt(player, "yay")
  # , 1000

