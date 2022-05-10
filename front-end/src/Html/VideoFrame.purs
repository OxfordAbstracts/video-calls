-- | A video call component that wraps daily.co component
module Components.VideoFrame (component, video_drag_element_id, video_box_controls_element_id, Query(..)) where

import Prelude

import Control.Monad.Rec.Class (forever)
import Data.Maybe (Maybe(..))
import Data.Monoid (guard)
import Data.Traversable (for_, traverse_)
import Effect (Effect)
import Effect.Aff (Milliseconds(..))
import Effect.Aff as Aff
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Foreign.Object (Object)
import Foreign.Object as Object
import Halogen (HalogenM, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Subscription as HS
import Html.Util (css)
import Web.HTML (HTMLElement)

data Action
  = Initialize
  | Finalize

data Query a
  = HangUp (Boolean -> a)

type Input
  = { room_name :: String
    , name :: String
    }

type State
  = { input :: Input
    , callFrame :: Maybe CallFrame
    , hide :: Boolean
    }

-- | A video call component that wraps daily.co component
component ::
  H.Component Query Input Void Aff.Aff
component =
  H.mkComponent
    { initialState
    , render
    , eval:
        H.mkEval
          $ H.defaultEval
              { handleAction = handleAction
              , initialize = Just Initialize
              , finalize = Just Finalize
              , handleQuery = handleQuery
              }
    }
  where
  initialState :: Input -> State
  initialState input =
    { input
    , callFrame: Nothing
    , hide: false
    }

  handleQuery :: forall a. Query a -> H.HalogenM State Action _ _ _ (Maybe a)
  handleQuery = case _ of
    HangUp reply -> do
      { callFrame } <- H.get
      H.modify_ _ { hide = true }
      traverse_ leaveCall callFrame
      pure (Just (reply true))

  handleAction :: Action -> HalogenM _ _ _ _ _ Unit
  handleAction = case _ of
    Initialize -> do
      { input } <- H.get
      elMay <- H.getHTMLElementRef videoFrameRef
      for_ elMay \el -> do
        callFrame <-
          initCallFrame
            { el
            , dragElementId: video_drag_element_id
            , controlsElementId: video_box_controls_element_id
            , createFrameOpts:
                { url: "https://oa-test-video.daily.co/" <> input.room_name
                , userName: input.name
                , showLeaveButton: false
                , showFullscreenButton: true
                , iframeStyle:
                    Object.fromHomogeneous
                      { height: "100%"
                      , width: "100%"
                      }
                }
            }
        H.modify_ _ { callFrame = Just callFrame }
    Finalize -> do
      { callFrame } <- H.get
      liftEffect $ traverse_ destroyCall callFrame

  render :: State -> _
  render {hide} = HH.div [ HP.ref videoFrameRef, css $ "w-full h-full" <> guard hide " opacity-0" ] []

  videoFrameRef = H.RefLabel "VideoFrame"

video_drag_element_id = "daily_video_drag_element" :: String
video_box_controls_element_id = "daily_video_box_controls_element" :: String

data CallFrame

initCallFrame ::
  forall m.
  MonadAff m =>
  { el :: HTMLElement
  , dragElementId :: String
  , controlsElementId :: String
  , createFrameOpts ::
      { url :: String
      , iframeStyle :: Object String
      , userName :: String
      , showLeaveButton :: Boolean
      , showFullscreenButton :: Boolean
      }
  } ->
  m CallFrame
initCallFrame = initCallFrameImpl >>> fromEffectFnAff >>> liftAff

foreign import initCallFrameImpl ::
  { el :: HTMLElement
  , dragElementId :: String
  , controlsElementId :: String
  , createFrameOpts ::
      { url :: String
      , iframeStyle :: Object String
      , userName :: String
      , showLeaveButton :: Boolean
      , showFullscreenButton :: Boolean
      }
  } ->
  EffectFnAff CallFrame

foreign import leaveCallImpl :: CallFrame -> EffectFnAff Unit

foreign import destroyCall :: CallFrame -> Effect Unit

leaveCall :: forall m. MonadAff m => CallFrame -> m Unit
leaveCall = leaveCallImpl >>> fromEffectFnAff >>> liftAff

tick :: forall m. MonadAff m => Action -> m (HS.Emitter Action)
tick a = do
  { emitter, listener } <- H.liftEffect HS.create
  _ <-
    H.liftAff $ Aff.forkAff
      $ forever do
          Aff.delay $ Milliseconds 5000.0
          H.liftEffect $ HS.notify listener a
  pure emitter