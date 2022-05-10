module Handlers.HelloWorld where

import Prelude

import Effect.Aff (Aff)

helloWorld :: { params :: { name :: String } } -> Aff { message :: String }
helloWorld {params: {name}} = pure { message : "Hello " <> name }