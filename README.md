# Scrumbot

Remember Funscrum! Of course you do! Wouldn't it be great if you could do a daily scrum by talking directly to your bot on Slack or Hipchat?!

Scrumbot bugs your teammembers every morning, then annouces everyone's scrum at a specific time.

http://tech.co/wp-content/uploads/2012/12/Screen-Shot-2012-12-06-at-2.03.43-PM.png

## Installing

Add dependency to `package.json`:

```console
$ npm install --save scrumbot
```

Include package in Hubot's `external-scripts.json`:

```json
["scrumbot"]
```

## Configuration

    HUBOT_SCRUMBOT_CLEAR_AT  # When to clear the current scrum, use cron style syntax (defaults to: 0 0 0 * * *)
    HUBOT_SCRUMBOT_NOTIFY_AT # When to notify the HUBOT_SCRUMBOT_ROOM to start the scrum, use cron style syntax (defaults to: 0 0 10 * * 4)
    HUBOT_SCRUMBOT_ROOM      # xxxxx_room_name@conf.hipchat.com

## Commands

    hubot scrum                            # lists all orders
    hubot what is <username> doing today?  # randomly selects person to either order or pickup lunch
    hubot scrum help                       # displays this help message


