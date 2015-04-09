Team = require('./team')
Player = require('./player')

class Scrum
  constructor: (robot) ->
    robot.brain.data.scrum ?= {}
    @robot = robot

  team: ->
    new Team(@robot)

  players: ->
    @team().players()

  ##
  # Get specific player by name
  player: (name) ->
    Player.find(@robot, name)
  
  prompt: (player, message) ->
    Player.dm(@robot, player.name, message)

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
    
  # Adds the user's entry to the category
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
  # Just return a key for the current day ie 2015-4-5
  date: ->
    new Date().toJSON().slice(0,10)

  

module.exports = Scrum
