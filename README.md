# Scrumbot!

Remember Funscrum! Of course you do! Wouldn't it be great if you could do a daily scrum by talking directly to your bot on Slack or Hipchat?!

Scrumbot bugs your teammembers every morning, then annouces everyone's scrum at a specific time.

http://tech.co/wp-content/uploads/2012/12/Screen-Shot-2012-12-06-at-2.03.43-PM.png

## Installing

Add dependency to `package.json`:

```console
$ npm install --save hubot-scrum
```

Include package in Hubot's `external-scripts.json`:

```json
["hubot-scrum"]
```

## Configuration

    HUBOT_SCRUM_CLEAR_AT  # When to clear the current scrum, use cron style syntax (defaults to: 0 0 0 * * *)
    HUBOT_SCRUM_NOTIFY_AT # When to notify the HUBOT_SCRUM_ROOM to start the scrum, use cron style syntax (defaults to: 0 0 10 * * 4)
    HUBOT_SCRUM_ROOM      # xxxxx_room_name@conf.hipchat.com

## Commands

    hubot scrum                            # start scrum
    hubot what is <username> doing today?  # what has <username> entered for their scrum today?
    hubot scrum help                       # displays this help message


