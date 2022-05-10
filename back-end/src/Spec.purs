module Spec where

import Payload.Spec (GET, Spec(..), POST)

spec ::
  Spec
    { helloWorld ::
        GET "/hello/<name>"
          { params :: { name :: String }
          , response :: { message :: String }
          }
    , dailyRoomCreate ::
        POST "/daily-room"
          { body ::
              { one_to_one :: Boolean
              , enable_recording :: Boolean
              , owner_only_broadcast :: Boolean
              , user_id :: Int
              }
          , response :: { id :: String, name :: String }
          }
    }
spec = Spec
