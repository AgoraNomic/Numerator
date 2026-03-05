module RunCommand where

import Data.UUID
import Data.Text (pack)
import qualified Data.Vector as Vec
import qualified Hasql.Session as Sess
import Args
import Statements
import Util

registerSession :: Register -> Sess.Session UUID
registerSession reg =
  Sess.statement
    ( shortName reg
    , longName reg
    ) registerStatement

-- adjustSession :: Adjust -> Sess.Session UUID
-- adjustSession adj =
--   Sess.statement
--     ( name adj
--     , date adj
--     , cards adj
--     , comment adj
--     )
--     adjustByNameStatement

grantSession :: Adjust -> Sess.Session UUID
grantSession adj =
  Sess.statement
    ( name adj
    , date adj
    , cards adj
    , comment adj
    )
    adjustByNameStatement

revokeSession :: Adjust -> Sess.Session UUID
revokeSession adj =
  Sess.statement
    ( name adj
    , date adj
    , cards adj
    , comment adj
    )
    adjustByNameStatement

transmuteSession :: Adjust -> Sess.Session UUID
transmuteSession adj =
  Sess.statement
    ( name adj
    , date adj
    , cards adj
    , comment adj
    )
    adjustByNameStatement
