module Main where

import Prelude
import Api (client)
import Data.Either (Either(..))
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Effect.Console (log)
import Halogen (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events (onClick)
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)
import Html.Util (css)
import Payload.ResponseTypes (Response(..))

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
    let
      helloWorld _ = do
        res <- liftAff $ client.helloWorld { params: { name: "Finn" } }
        case res of
          Left _err -> pure unit
          Right (Response { body: { message } }) -> Hooks.put hello_id message
    Hooks.pure do
      HH.div [ css "w-40 mx-auto border p-4 border-gray-500 mt-8 text-center" ]
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
        ]
