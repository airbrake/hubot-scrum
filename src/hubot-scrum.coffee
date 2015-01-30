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
# Notes:
#   We were sad to see funscrum die so we are making this now!
#
# Authors:
#   @jpsilvashy
#   @mmcdaris

console.log("SCRUM LOADED.....")

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
# Default lunch time
NOTIFY_AT = process.env.HUBOT_SCRUM_NOTIFY_AT || '0 0 11 * * *' # 11am everyday

##
# clear the lunch order on a schedule
CLEAR_AT = process.env.HUBOT_SCRUM_CLEAR_AT || '0 0 0 * * *' # midnight

##
# setup cron
CronJob = require("cron").CronJob

module.exports = (robot) ->

  ##
  # Define the lunch functions
  scrum =
    get: ->
      Object.keys(robot.brain.data.scrum)

    add: (user, item) ->
      console.log(user, item)
      robot.brain.data.scrum[user] = item

    remove: (user) ->
      delete robot.brain.data.scrum[user]

    clear: ->
      robot.brain.data.scrum = {}
      robot.messageRoom ROOM, "scrum cleared..."

    notify: ->
      robot.messageRoom ROOM, MESSAGE

  ##
  # Define things to be scheduled
  schedule =
    notify: (time) ->
      new CronJob(time, ->
        scrum.notify()
        return
      , null, true, TIMEZONE)

    clear: (time) ->
      new CronJob(time, ->
        robot.brain.data.scrum = {}
        return
      , null, true, TIMEZONE)

  ##
  # Schedule when to alert the ROOM that it's time to start ordering lunch
  schedule.notify NOTIFY_AT

  ##
  # Schedule when the order should be cleared at
  schedule.clear CLEAR_AT

  ##
  ##
  # List out all the tasks
  robot.respond /scrum$/i, (msg) ->
    items = scrum.get().map (user) -> "#{user}: #{robot.brain.data.scrum[user]}"
    msg.send items.join("\n") || "No items in the scrum."

  robot.respond /scrum add (.*)/i, (msg) ->
    item = msg.match[1].trim()
    scrum.add msg.message.user.name, item
    msg.send "added #{item}"

  robot.respond /scrum (clear|reset|setup)/i, (msg) ->
    delete robot.brain.data.scrum
    scrum.clear()

  ##
  # Display usage details
  robot.respond /scrum help/i, (msg) ->
    msg.send MESSAGE

  ##
  # Just print out the details on how the scrum is configured
  robot.respond /scrum config/i, (msg) ->
    msg.send "ROOM: #{ROOM} \nTIMEZONE: #{TIMEZONE} \nNOTIFY_AT: #{NOTIFY_AT} \nCLEAR_AT: #{CLEAR_AT}\n "

