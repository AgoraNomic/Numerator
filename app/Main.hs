module Main where

import Text.Printf
import Args

main :: IO ()
main = do
  cmd <- getCommand
  case cmd of
    CmdRegister r -> do
      printf "Registering %s" (shortName r)
