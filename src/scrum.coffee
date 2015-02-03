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

##
# Setup cron
CronJob = require("cron").CronJob

##
# set up your free mailgun account here: TODO
# Setup Mailgun
Mailgun = require('mailgun').Mailgun
mailgun = new Mailgun(process.env.HUBOT_MAILGUN_APIKEY)
FROM_USER = process.env.HUBOT_SCRUM_FROM_USER || "noreply+scrumbot@example.com"

module.exports = (robot) ->
  console.log(robot.brain.data.users)
  ##
  # TODO: Select only opted in users to send email to, match
  # them by user name here, or they could be stored in redis
  # as the key for the user that has scrum items, then we never
  # need an opt-in feature. It would just annouce in the room, then
  # email to all the users with keys.
  # console.log(robot.brain.data.users)
  users = [robot.brain.data.users]

  # NEXT Auth = require('hubot-auth').Auth
  # users = Auth.usersWithRole("scrum")
  # console.log(users)

  console.log(robot.auth)
  ##
  # Define the lunch functions
  scrum =
    team: ->
      console.log("list the team!")

    opt_in: ->
      console.log("Users add themselves!")

    summary: ->
      console.log("summary of scrums")

    # Some nice format
    today: -> new Date().toJSON().slice(0,10)

    users: ->
      robot.brain.data.scrum

    get: ->
      Object.keys(robot.brain.data.scrum)

    add: (key, value) ->
      console.log(user, value)
      robot.brain.data.scrum[key] = value

    remove: (key) ->
      delete robot.brain.data.scrum[key]

    notify: ->
      robot.brain.data.scrum = {}
      robot.messageRoom ROOM, "summary"

    remind: ->
      console.log("remind all users with scrum role not to forget.")

    mail: ->
      addresses = users.map (user) -> "#{user.name} <#{user.email_address}>"
      mailgun.sendText FROM_USER, [
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

  ##
  # Schedule the Reminder with a direct message so they don't forget
  # Don't send this if they already sent it in
  # instead then send good job and leaderboard changes + streak info
  schedule.reminder REMIND_AT

  # Schedule when the order should be cleared at
  ##
  schedule.notify NOTIFY_AT

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
  # Display the day(TODO use as a redis key)
  robot.respond /scrum today/i, (msg) ->
    msg.send scrum.today()

  ##
  # Send mailer to everyone on team
  robot.respond /scrum mail/i, (msg) ->
    scrum.mail()
    msg.send "sent!"

  ##
  # Just print out the details on how the scrum is configured
  robot.respond /scrum config/i, (msg) ->
    console.log("channel: ", msg.channel)
    msg.send "ROOM: #{ROOM} \nTIMEZONE: #{TIMEZONE} \nNOTIFY_AT: #{NOTIFY_AT} \nCLEAR_AT: #{CLEAR_AT}\n "

