Team = require('./team')
Player = require('./player')

# Connect to Redis
client = require('../redis-store')

class Scrum
  constructor: (robot) ->
    robot.brain.data.scrum ?= {}
    @robot = robot

  team: ->
    new Team(@robot)

  players: ->
    @.team().players()

  ##
  # Get specific player by name
  player: (name) ->
    Player.find(@robot, name)

  prompt: (player, message) ->
    Player.dm(@robot, player.name, message)

  demo: ->
    

  # FIXME: This should take a player object
  # and return the total points they have
  # there are a few ways to do this:
  #   - we just find the last scrum they participated
  #     in copy it and add 10 points, this makes it hard
  #     to account for bonus points earned for consecutive
  #     days of particpating in the scrum
  #   - we scan back and total up all their points ever, grouping
  #     the consecutive ones and applying the appropriate bonus points
  #     for those instances



  # takes a player and a callback
  # the callback is going to receive the score for the player
  getScore: (player, fn) ->
    client().zscore("scrum", player.name, (err, scoreFromRedis) ->
      if scoreFromRedis
        player.score = scoreFromRedis
        fn(player)
      else
        console.log(
          "getScoreError: didn't get a response got \' #{scoreFromRedis} \'\n" + "player was: #{player.name}"
        )
    )

  # TODO: JP
  # Fix me! maybe use promises here?
  getScores: (players, fn) ->
    for player in players
      client().zscore("scrum", player.name, (err, scoreFromRedis) ->
        if scoreFromRedis
          player.score = scoreFromRedis
        else
          console.log(
            "getScoreError: didn't get a response got \' #{scoreFromRedis} \'\n" + "player was: #{player.name}"
          )
      ).then(fn(players))

  ##
  # Just return a key for the current day ie 2015-4-5
  date: ->
    new Date().toJSON().slice(0,10)



module.exports = Scrum
