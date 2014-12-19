# hubot-lunch

A bot to help keep track of lunch orders for your office.

## Installing

Add dependency to `package.json`:

```console
$ npm install --save hubot-lunch
```

Include package in Hubot's `external-scripts.json`:

```json
["hubot-lunch"]
```

## Configuration

    HUBOT_LUNCHBOT_CLEAR_AT  # When to clear the current lunch order, use cron style syntax (defaults to: 0 0 0 * * *)
    HUBOT_LUNCHBOT_NOTIFY_AT # When to notify the HUBOT_LUNCHBOT_ROOM to start the lunch order, use cron style syntax (defaults to: 0 0 10 * * 4)
    HUBOT_LUNCHBOT_ROOM      # xxxxx_room_name@conf.hipchat.com

## Commands

    hubot I want <food>                       # adds <food> to the list of items to be ordered
    hubot remove my order                     # removes your order
    hubot cancel all orders                   # cancels all the orders
    hubot lunch orders                        # lists all orders
    hubot who should order|pickup|get lunch?  # randomly selects person to either order or pickup lunch
    hubot lunch help                          # displays this help message


