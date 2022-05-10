module Handlers.DailyRoom where

import Prelude

import Data.DateTime as DateTime
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Hours(..))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Now (nowDateTime)
import Payload.Headers as Headers
import Payload.ResponseTypes (Failure(..), Response(..), ResponseBody(..))
import Services.VideoChat as VideoChat

dailyRoomCreate :: 
  { body :: 
    { one_to_one :: Boolean
    , enable_recording :: Boolean
    , owner_only_broadcast :: Boolean
    , user_id :: Int
    }
  } ->
  Aff (Either Failure {id :: String, name :: String})
dailyRoomCreate { body } = do 
  now <- liftEffect nowDateTime
  room <- VideoChat.createRoom 
    { enable_recording: body.enable_recording
    , expiry: DateTime.adjust (Hours 1.0) now
    , max_participants: if body.one_to_one then Just 2 else Nothing
    , owner_only_broadcast: body.owner_only_broadcast
    , private: false
    , user_id: body.user_id 
    }

  pure case room of 
    Left _ -> failWithStatus 500 "Could not create room"
    Right res -> Right $ res

failWithStatus :: forall r. Int -> String -> Either Failure r
failWithStatus code reason =
  Left
    $ Error
    $ Response
    $ { body: EmptyBody
      , headers: Headers.empty
      , status:
          { code
          , reason
          }
      }