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
  # List out all the orders
  robot.respond /scrum$/i, (msg) ->
    tasks = scrum.get().map (user) -> "#{user}: #{robot.brain.data.scrum[user]}"
    msg.send tasks.join("\n") || "No items in the scrum."

  ##
  # Save what a person wants to the lunch order
  # robot.respond /i want (.*)/i, (msg) ->
  #   item = msg.match[1].trim()
  #   scrum.add msg.message.user.name, item
  #   msg.send "ok, added #{item} to your order."

  ##
  # Remove the persons items from the lunch order
  # robot.respond /remove my order/i, (msg) ->
  #   lunch.remove msg.message.user.name
  #   msg.send "ok, I removed your order."

  ##
  # Cancel the entire order and remove all the items
  # robot.respond /cancel all orders/i, (msg) ->
  #   delete robot.brain.data.lunch
  #   lunch.clear()

  ##
  # Help decided who should either order, pick up or get
  # robot.respond /who should (order|pick up|get) lunch?/i, (msg) ->
  #   orders = lunch.get().map (user) -> user
  #   key = Math.floor(Math.random() * orders.length)
  #   msg.send "#{orders[key]} looks like you have to #{msg.match[1]} lunch today!"

  ##
  # Display usage details
  # robot.respond /lunch help/i, (msg) ->
  #   msg.send MESSAGE

  ##
  # Just print out the details on how the lunch bot is configured
  # robot.respond /lunch config/i, (msg) ->
  #   msg.send "ROOM: #{ROOM} \nTIMEZONE: #{TIMEZONE} \nNOTIFY_AT: #{NOTIFY_AT} \nCLEAR_AT: #{CLEAR_AT}\n "

