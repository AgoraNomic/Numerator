module Util where

import Data.Int
import Data.Maybe (fromMaybe)
import qualified Data.Text as Text
import Data.Time
import qualified Data.Vector as Vec
import Data.Word
import System.Environment (lookupEnv)
import qualified Hasql.Connection.Settings as CS

lookupEnvDefault :: String -> String -> IO String
lookupEnvDefault key defVal = fromMaybe defVal <$> lookupEnv key

getDbConnection :: IO CS.Settings
getDbConnection = do
  hostname <- lookupEnvDefault "PGHOST" "localhost"
  portStr <- lookupEnvDefault "PGPORT" "5432"
  let port = read portStr :: Word16
  db <- lookupEnvDefault "PGDATABASE" "numerator"
  user <- lookupEnvDefault "PGUSER" "numerator"
  return $ CS.hostAndPort (Text.pack hostname) port
    <> CS.user (Text.pack user)
    <> CS.dbname (Text.pack db)

getUnzonedEmailTime :: String -> LocalTime
getUnzonedEmailTime str =
  -- silly little function
  let
    -- get the utc timestamp from rfc822 format and stuff it in a UTCTime wrapper...
    Just utcTime = parseTimeM True defaultTimeLocale "%a, %_d %b %Y %H:%M:%S %Z" str :: Maybe UTCTime
  in
    -- ...then immediately discard the timezone data
    -- this has reason. converting to local time would give the time in the local time zone.
    -- unacceptable. agora works on UTC.
    utcToLocalTime utc utcTime

addCardStringToVector :: Vec.Vector Int32 -> String -> Vec.Vector Int32
addCardStringToVector cards str =
  let
    i = read [head str]
  in
    addCardStringToVector (Vec.imap (\j x -> if i == j then x + 1 else x) cards) (tail str)

cardStringToVector :: String -> Vec.Vector Int32
cardStringToVector = addCardStringToVector (Vec.replicate 10 0)
