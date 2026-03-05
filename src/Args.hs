module Args where

{-# LANGUAGE OverloadedStrings #-}

import qualified Data.Text as T
import Data.Time
import Options.Applicative
import Readers
import Util

-- Define the various commands and their parameters

-- Command for 'register'
data Register = Register
  { shortName :: T.Text
  , longName  :: Maybe T.Text
  } deriving Show

-- Commands 'adjust', 'grant', 'revoke', 'transmute'
data Adjust = Adjust
  { date    :: LocalTime
  , name    :: T.Text
  , cards   :: CardVec
  , comment :: Maybe T.Text
  } deriving Show

-- Command for 'transfer'
data Transfer = Transfer
  { transferDate  :: LocalTime
  , fromName      :: T.Text
  , toName        :: T.Text
  , transferCards :: CardVec
  , transferComment :: Maybe T.Text
  } deriving Show

-- All commands combined
data Command
  = CmdRegister Register
  | CmdAdjust Adjust
  | CmdGrant Adjust
  | CmdRevoke Adjust
  | CmdTransmute Adjust
  | CmdTransfer Transfer
  deriving Show

-- Parser for 'register' command
parseRegister :: Parser Command
parseRegister = fmap CmdRegister $ Register
  <$> argument textReader (metavar "SHORT-NAME" <> help "Short name")
  <*> optional (argument textReader (metavar "LONG-NAME" <> help "Optional long name"))

-- Parser for 'adjust', 'grant', 'revoke', 'transmute' commands
parseAdjust :: String -> Parser Command
parseAdjust cmdName = fmap CmdAdjust $ Adjust
  <$> argument unzonedEmailTimeReader (metavar "DATE" <> help "Date")
  <*> argument textReader (metavar "NAME" <> help "Name")
  <*> argument cardVecReader (metavar "CARDS" <> help "Cards")
  <*> optional (strOption (long "comment" <> short 'c' <> metavar "COMMENT" <> help "Optional comment"))

-- Parser for 'transfer' command
parseTransfer :: Parser Command
parseTransfer = fmap CmdTransfer $ Transfer
  <$> argument unzonedEmailTimeReader (metavar "DATE" <> help "Date")
  <*> argument textReader (metavar "FROM" <> help "Source name")
  <*> argument textReader (metavar "TO" <> help "Destination name")
  <*> argument cardVecReader (metavar "CARDS" <> help "Cards")
  <*> optional (strOption (long "comment" <> short 'c' <> metavar "COMMENT" <> help "Optional comment"))

-- Main parser for subcommands
parseCommand :: Parser Command
parseCommand = subparser
    ( command "register" (info (parseRegister) (progDesc "Register a player"))
   -- <> command "adjust"  (info (parseAdjust "adjust") (progDesc "Adjust players' balances"))
   <> command "grant"   (info (parseAdjust "grant") (progDesc "Grant cards"))
   <> command "revoke"  (info (parseAdjust "revoke") (progDesc "Revoke cards"))
   <> command "transmute" (info (parseAdjust "transmute") (progDesc "Transmute cards"))
   <> command "transfer" (info (parseTransfer) (progDesc "Transfer cards"))
    )

getCommand :: IO Command
getCommand = do
  execParser opts
  where
    opts = info (parseCommand <**> helper)
      ( fullDesc
     <> progDesc "A command line tool for managing something"
     <> header "command line argument parser example" )

