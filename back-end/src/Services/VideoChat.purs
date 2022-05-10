module Services.VideoChat (ActiveParticipant, createRoom, getActiveParticipants) where

import Prelude

import Affjax (Error(..), Response, defaultRequest)
import Affjax as Affjax
import Affjax.RequestBody as RB
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat as RF
import Affjax.StatusCode (StatusCode(..))
import Data.Argonaut (class DecodeJson, class EncodeJson, Json, decodeJson, encodeJson)
import Data.DateTime (DateTime)
import Data.DateTime.Instant (fromDateTime, unInstant)
import Data.Either (Either(..))
import Data.HTTP.Method as Method
import Data.Int (round)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Effect.Aff.Class (class MonadAff, liftAff)
import Foreign (ForeignError(..), unsafeToForeign)
import Foreign.Object (Object)

daily_api_key = "1844647e30eb55387206a90b4302af9c64408016cd76b434f422ba2749b3e3b0" :: String

createRoom ::
  forall m.
  MonadAff m =>
  { max_participants :: Maybe Int
  , enable_recording :: Boolean
  , owner_only_broadcast :: Boolean
  , private :: Boolean
  , user_id :: Int
  , expiry :: Maybe DateTime
  } ->
  m (Either Error ({ id :: String, name :: String }))
createRoom opts = do
  dailyApiPost "/rooms"
    { properties:
        { max_participants: opts.max_participants
        , enable_recording: opts.enable_recording
        , owner_only_broadcast: opts.owner_only_broadcast
        , exp: map toUnixSecs opts.expiry
        }
    , privacy: if opts.private then "private" else "public"
    }

type ActiveParticipant = 
  { id :: String 
  , userId :: String -- Daily user id, not OA
  , userName :: String
  , joinTime :: String -- stringified DateTime 
  , duration :: Int
  , room :: String
  }
  
-- | https://docs.daily.co/reference#presence-1 
-- | Get actice participants, grouped by room name 
getActiveParticipants :: forall m. MonadAff m => m (Either Error (Object (Array ActiveParticipant)))
getActiveParticipants = dailyApiGet "/presence"

dailyApiPost :: forall m payload res. MonadAff m => EncodeJson payload => DecodeJson res => String -> payload -> m (Either Error res)
dailyApiPost endpoint payload = do
  res <-
    liftAff
      $ Affjax.request
          defaultRequest
            { withCredentials = true
            , url = getDailyEndpointUrl endpoint
            , method = Left Method.POST
            , responseFormat = RF.json
            , content = Just $ RB.Json $ encodeJson payload
            , headers = [ RequestHeader "Authorization" $ "Bearer " <> daily_api_key ]
            }
  pure $ decodeApiJsonRes res

dailyApiGet :: forall m res. MonadAff m =>  DecodeJson res => String -> m (Either Error res)
dailyApiGet endpoint = do
  res <-
    liftAff
      $ Affjax.request
          defaultRequest
            { withCredentials = true
            , url = getDailyEndpointUrl endpoint
            , method = Left Method.GET
            , responseFormat = RF.json
            , headers = [ RequestHeader "Authorization" $ "Bearer " <> daily_api_key ]
            }
  pure $ decodeApiJsonRes res
  
decodeApiJsonRes :: forall res.
  DecodeJson res => Either Error (Response Json) -> Either Error res
decodeApiJsonRes res = case res of
    Left err -> Left err
    Right rightRes@{ status: (StatusCode status), body }
      | status /= 200 -> Left $ ResponseBodyError (ForeignError $ "Bad status code: " <> show status) $ rightRes { body = unsafeToForeign body }
    Right rightRes@{ body } -> case decodeJson body of
      Left err -> Left $ ResponseBodyError (ForeignError $ show err) $ rightRes { body = unsafeToForeign body }
      Right decoded -> Right decoded

getDailyEndpointUrl :: String -> String
getDailyEndpointUrl endpoint = "https://api.daily.co/v1" <> endpoint

toUnixSecs :: DateTime -> Int
toUnixSecs = fromDateTime >>> unInstant >>> unwrap  >>> (_ / 1000.0) >>> round

