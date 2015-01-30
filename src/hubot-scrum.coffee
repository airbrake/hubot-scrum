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
# Default scrum deadline
NOTIFY_AT = process.env.HUBOT_SCRUM_NOTIFY_AT || '0 0 11 * * *' # 11am everyday

##
# Clear the scrum on a schedule
CLEAR_AT = process.env.HUBOT_SCRUM_CLEAR_AT || '0 0 0 * * *' # midnight

##
# Setup cron
CronJob = require("cron").CronJob

##
# Setup Mailgun
Mailgun = require('mailgun').Mailgun
mailgun = new Mailgun(process.env.HUBOT_MAILGUN_APIKEY)

module.exports = (robot) ->

  ##
  # TODO: Select only opted in users to send email to, match
  # them by user name here, or they could be stored in redis 
  # as the key for the user that has scrum items, then we never 
  # need an opt-in feature. It would just annouce in the room, then
  # email to all the users with keys.
  # console.log(robot.brain.data.users)
  users = robot.brain.data.users["U03CLE1T7"]
  
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
    
    mail: ->
      addresses = users.map (user) -> "#{user.name} <#{user.email_address}>"
      mailgun.sendText "noreply+scrumbot@example.com", [
        # addresses
      ], "Daily Scrum", "This is the text", "noreply+scrumbot@example.com", {}, (err) ->
        if err
          console.log "[mailgun] Oh noes: " + err
        else
          console.log "[mailgun] Success!"
        return

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
  # Send mailer to everyone on team
  robot.respond /scrum mail/i, (msg) ->
    scrum.mail()
    msg.send "sent!"

  ##
  # Just print out the details on how the scrum is configured
  robot.respond /scrum config/i, (msg) ->
    msg.send "ROOM: #{ROOM} \nTIMEZONE: #{TIMEZONE} \nNOTIFY_AT: #{NOTIFY_AT} \nCLEAR_AT: #{CLEAR_AT}\n "

