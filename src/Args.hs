module Args where

{-# LANGUAGE OverloadedStrings #-}

import Options.Applicative

-- Define the various commands and their parameters

-- Command for 'register'
data Register = Register
  { shortName :: String
  , longName  :: Maybe String
  } deriving Show

-- Commands 'adjust', 'grant', 'revoke', 'transmute'
data Adjust = Adjust
  { date    :: String
  , name    :: String
  , cards   :: String
  , comment :: Maybe String
  } deriving Show

-- Command for 'transfer'
data Transfer = Transfer
  { transferDate  :: String
  , fromName      :: String
  , toName        :: String
  , transferCards :: String
  , transferComment :: Maybe String
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
  <$> strArgument (metavar "SHORT-NAME" <> help "Short name")
  <*> optional (strArgument (metavar "LONG-NAME" <> help "Optional long name"))

-- Parser for 'adjust', 'grant', 'revoke', 'transmute' commands
parseAdjust :: String -> Parser Command
parseAdjust cmdName = fmap CmdAdjust $ Adjust
  <$> strArgument (metavar "DATE" <> help "Date")
  <*> strArgument (metavar "NAME" <> help "Name")
  <*> strArgument (metavar "CARDS" <> help "Cards")
  <*> optional (strOption (long "comment" <> short 'c' <> metavar "COMMENT" <> help "Optional comment"))

-- Parser for 'transfer' command
parseTransfer :: Parser Command
parseTransfer = fmap CmdTransfer $ Transfer
  <$> strArgument (metavar "DATE" <> help "Date")
  <*> strArgument (metavar "FROM" <> help "Source name")
  <*> strArgument (metavar "TO" <> help "Destination name")
  <*> strArgument (metavar "CARDS" <> help "Cards")
  <*> optional (strOption (long "comment" <> short 'c' <> metavar "COMMENT" <> help "Optional comment"))

-- Main parser for subcommands
parseCommand :: Parser Command
parseCommand = subparser
    ( command "register" (info (parseRegister) (progDesc "Register a player"))
   <> command "adjust"  (info (parseAdjust "adjust") (progDesc "Adjust players' balancesj"))
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

