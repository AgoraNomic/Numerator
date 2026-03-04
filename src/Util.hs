module Util where

import System.Environment (lookupEnv)

lookupEnvDefault :: String -> String -> IO String
lookupEnvDefault key defVal = fmap (maybe defVal id) (lookupEnv key)
