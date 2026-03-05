module Util where

import Data.Int
import Data.Maybe (fromMaybe)
import qualified Data.Text as Text
import Data.Time
import qualified Data.Vector as Vec
import Data.Word
import Text.Read
import System.Environment (lookupEnv)
import qualified Hasql.Connection.Settings as CS

type CardVec = Vec.Vector Int32

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

tryParseUnzonedEmailTime :: String -> Either String LocalTime
tryParseUnzonedEmailTime str =
  -- silly little function
  -- get the utc timestamp from rfc822 format and stuff it in a UTCTime wrapper...
  case parseTimeM True defaultTimeLocale "%a, %_d %b %Y %H:%M:%S %Z" str :: Maybe UTCTime of
    -- ...then immediately discard the timezone data
    -- this has reason. converting to local time would give the time in the local time zone.
    -- unacceptable. agora works on UTC.
    Just utcTime -> Right $ utcToLocalTime utc utcTime
    Nothing -> Left "Invalid time format"

tryAddCardStringToVector :: Either String CardVec -> String -> Either String CardVec
tryAddCardStringToVector cards [] = cards
tryAddCardStringToVector cards str =
  case readEither [head str] of
    Right i ->
      tryAddCardStringToVector (Vec.imap (\j x -> if i == j then x + 1 else x) <$> cards) (tail str)
    Left s -> Left "Could not parse a character in a card string"

tryCardStringToVector :: String -> Either String CardVec
tryCardStringToVector = tryAddCardStringToVector $ Right $ Vec.replicate 10 0

invertCardVec :: CardVec -> CardVec
invertCardVec = Vec.map (0-)

tryCardStringToTransmuteVector :: String -> Either String CardVec
tryCardStringToTransmuteVector str =
  case tryCardStringToVector str of
    Right cardVec ->
      let
        revokeCardVec = invertCardVec cardVec
        cardSum = foldl (\y x -> y + (read [x] :: Int)) 0 str
        targetCard = mod cardSum 10
      in
        Right $ Vec.accum (+) revokeCardVec [(targetCard, 1)]
    Left s -> Left s
