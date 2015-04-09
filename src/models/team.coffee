Player = require('./player')

class Team
  constructor: (robot) ->
    @robot = robot

  save: ->
    attrs =
      name: @name
      score: @score
    @robot.brain.set 'astroscrum-team', attrs
  
  name: ->
    @robot.adapter.client.team.name

  score: ->
    10

  players: ->
    players = []
    for own key, user of @robot.brain.data.users
      roles = user.roles or []
      if 'scrum' in roles
        players.push new Player(user)
    return players

  ##
  # Mail the scrum participants
  mail: (subject, body) ->
    addresses = @players().map (player) -> "#{player.name} <#{player.email}>"
    mailgun.sendText "noreply+scrumbot@example.com", [
      # addresses
    ], subject, body, "noreply+scrumbot@example.com", {}, (err) ->
      if err
        console.log "[mailgun] Oh noes: " + err
      else
        console.log "[mailgun] Success!"
      return

module.exports = Team

