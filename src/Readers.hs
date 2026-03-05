module Readers where

import Data.Functor
import Data.Int
import qualified Data.Text as T
import Data.Time
import qualified Data.Vector as Vec
import Text.Read
import Options.Applicative
import Util

unzonedEmailTimeReader :: ReadM LocalTime
unzonedEmailTimeReader = eitherReader tryParseUnzonedEmailTime

cardVecReader :: ReadM (Vec.Vector Int32)
cardVecReader = eitherReader tryCardStringToVector

textReader :: ReadM T.Text
textReader = eitherReader (Right . T.pack)
