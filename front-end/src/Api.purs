module Api where

import Prelude
import Data.Either (Either)
import Effect.Aff (Aff)
import Payload.Client (ClientError, defaultOpts, mkClient)
import Payload.Headers (Headers)
import Payload.ResponseTypes (Response)
import Spec (spec)

client ::
  { helloWorld ::
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
