module RunCommand where

import Data.UUID
import Data.Text (pack)
import qualified Hasql.Session as Sess
import Args
import Statements
import Util

registerSession :: Register -> Sess.Session UUID
registerSession reg =
  Sess.statement
    ( pack $ shortName reg
    , pack <$> longName reg
    ) registerStatement

adjustSession :: Adjust -> Sess.Session UUID
adjustSession adj =
  Sess.statement
    ( pack $ name adj
    , getUnzonedEmailTime $ date adj
    , cardStringToVector $ cards adj
    , pack <$> comment adj
    )
    adjustByNameStatement
