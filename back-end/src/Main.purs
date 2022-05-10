module Main where

import Prelude

import Handlers.DailyRoom (dailyRoomCreate)
import Handlers.HelloWorld (helloWorld)
import Effect (Effect)
import Payload.Server as Payload
import Spec (spec)

handlers :: _
handlers = { helloWorld, dailyRoomCreate }

main :: Effect Unit
main = Payload.launch spec handlers