module Main where

import Prelude
import Api (client)
import Components.VideoFrame (video_drag_element_id)
import Components.VideoFrame as VideoFrame
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Newtype (wrap)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Aff (Aff, delay)
import Effect.Aff.Class (liftAff)
import Effect.Console (log)
import Halogen (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML (slot_)
import Halogen.HTML as HH
import Halogen.HTML.Events (onClick)
import Halogen.HTML.Properties (id)
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)
import Html.Util (css, maybeElem)
import Payload.ResponseTypes (Response(..))
import Type.Proxy (Proxy(..))

main :: Effect Unit
main =
  HA.runHalogenAff do
    liftEffect $ log "Starting app!"
    bodyEl <- HA.awaitBody
    runUI component {} bodyEl

component :: forall q i o. H.Component q { | i } o Aff
component =
  Hooks.component \{} {} -> Hooks.do
    count /\ count_id <- Hooks.useState 0
    hello /\ hello_id <- Hooks.useState ""
    daily_config /\ daily_config_id <- Hooks.useState Nothing
    let
      helloWorld _ = do
        res <- liftAff $ client.helloWorld { params: { name: "Finn" } }
        case res of
          Left _err -> pure unit
          Right (Response { body: { message } }) -> Hooks.put hello_id message

      getDailyRoom _ = do
        res <-
          liftAff
            $ client.dailyRoomCreate
                { body:
                    { enable_recording: false
                    , one_to_one: true
                    , owner_only_broadcast: false
                    , user_id: 1
                    }
                }
        case res of
          Left _err -> pure unit
          Right (Response { body }) -> Hooks.put daily_config_id $ Just body
    Hooks.pure do
      HH.div [ css "w-80 mx-auto border p-4 border-gray-500 mt-8 text-center" ]
        [ HH.text $ show count
        , HH.button
            [ css "w-full border border-gray-500 rounded"
            , onClick \_ -> Hooks.modify_ count_id $ (+) 1
            ]
            [ HH.text "+1!" ]
        , HH.button
            [ css "w-full border border-gray-500 rounded mt-4"
            , onClick helloWorld
            ]
            [ HH.text "Say hello" ]
        , HH.div [] [ HH.text hello ]
        , HH.button
            [ css "w-full border border-gray-500 rounded mt-4"
            , onClick getDailyRoom
            ]
            [ HH.text "Connect to daily.io" ]
        , maybeElem daily_config \{ name } ->
            HH.div
              [ css "absolute w-[500px] h-[500px] border border-gray-200 rounded shadow-xl bg-gray-50 left-0 right-0 mx-auto"
              , id video_drag_element_id
              ]
              [ HH.div
                  [ css "flex justify-between items-center p-1"
                  ]
                  [ HH.text $ "Room name: " <> name
                  , HH.button
                      [ css "border-gray-200 rounded p-2"
                      , onClick \_ -> Hooks.put daily_config_id Nothing
                      ]
                      [ HH.text "close" ]
                  ]
              , slot_ (Proxy :: _ "daily-test") unit VideoFrame.component { name: "Finn", room_name: name }
              ]
        ]
