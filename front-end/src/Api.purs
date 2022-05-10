module Api where

import Prelude
import Data.Either (Either)
import Effect.Aff (Aff)
import Payload.Client (ClientError, defaultOpts, mkClient)
import Payload.Headers (Headers)
import Payload.ResponseTypes (Response)
import Spec (spec)

client ::
  { dailyRoomCreate ::
      { body ::
          { enable_recording :: Boolean
          , one_to_one :: Boolean
          , owner_only_broadcast :: Boolean
          , user_id :: Int
          }
      } ->
      Aff
        ( Either ClientError
            ( Response
                { id :: String
                , name :: String
                }
            )
        )
  , dailyRoomCreate_ ::
      { extraHeaders :: Headers
      } ->
      { body ::
          { enable_recording :: Boolean
          , one_to_one :: Boolean
          , owner_only_broadcast :: Boolean
          , user_id :: Int
          }
      } ->
      Aff
        ( Either ClientError
            ( Response
                { id :: String
                , name :: String
                }
            )
        )
  , helloWorld ::
      { params ::
          { name :: String
          }
      } ->
      Aff
        ( Either ClientError
            ( Response
                { message :: String
                }
            )
        )
  , helloWorld_ ::
      { extraHeaders :: Headers
      } ->
      { params ::
          { name :: String
          }
      } ->
      Aff
        ( Either ClientError
            ( Response
                { message :: String
                }
            )
        )
  }
client = mkClient opts spec
  where
  opts = defaultOpts { baseUrl = "/api" }
