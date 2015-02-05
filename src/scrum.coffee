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
# Set up your free mailgun account here: TODO
# Setup Mailgun
Mailgun = require('mailgun').Mailgun
mailgun = new Mailgun(process.env.HUBOT_MAILGUN_APIKEY)
FROM_USER = process.env.HUBOT_SCRUM_FROM_USER || "noreply+scrumbot@example.com"

console.log("scrum loaded!")

##
# Setup Handlebars
Handlebars = require('handlebars')

##
# Robot
module.exports = (robot) ->

  ##
  # Make sure the scrum object is set
  robot.brain.data.scrum ?= {}

  ##
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
    #
    # Right now this just returns a stub of 100
    #
    tally: (user) ->
      user['points'] = 100

    ##
    # Tally up all the users points
    tallyTeam: (users) ->
      for user in users
        scrum.tally user

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
      robot.brain.data.scrum[scrum.date()] ?= {}

    ##
    # Mail the scrum participants
    mail: ->
      addresses = scrum.participants().map (user) -> "#{user.name} <#{user.email_address}>"
      mailgun.sendText FROM_USER, [
        # addresses
      ], "Daily Scrum", "This is the text", "noreply+scrumbot@example.com", {}, (err) ->
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
        hey {{user.name}}, You have {{user.points}} points.
      """
      template = Handlebars.compile(source)
      template({ user: user })

    leaderboard: (users) ->
      source = """
        Hey team, here is the leaderboard:
        {{#each users}}
          {{this.name}}: {{this.points}}
        {{/each}}
      """
      template = Handlebars.compile(source)
      template({ users: users })

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

  ##
  # Schedule when the order should be cleared at
  schedule.notify NOTIFY_AT

  ##
  # Tallys up all the team members points on load
  scrum.tallyTeam scrum.participants()

  ##
  # Handle user input
  robot.respond /scrum info/i, (msg) ->
    list = scrum.participants().map (user) -> "#{user.name}: #{user.points}"
    msg.send list.join("\n") || "Nobody is in the scrum!"
    console.log scrum.today()

  ##
  # Responds with details about my user
  robot.respond /scrum my status/i, (msg) ->
    console.log(msg.message.user)
    msg.send status.personal(msg.message.user)

  ##
  # Responds with the points for everyone on the team
  robot.respond /scrum leaderboard/i, (msg) ->
    msg.send status.leaderboard(scrum.participants())

