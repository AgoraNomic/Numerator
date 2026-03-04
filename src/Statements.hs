{-# LANGUAGE QuasiQuotes #-}

module Statements where

import Args

import Data.Functor.Contravariant
import Data.Int
import Data.Text
import Data.UUID
import Data.Time
import Data.Vector
import Hasql.Session (Session)
import Prelude
import qualified Hasql.Connection as Connection
import qualified Hasql.Connection.Settings as Settings
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Hasql.Session as Session
import qualified Hasql.Statement as Statement
import Hasql.TH

registerStatement :: Statement.Statement (Text, Maybe Text) UUID
registerStatement =
  [singletonStatement|
    INSERT INTO entity (shortname, fullname)
    VALUES ($1 :: text, $2 :: text?)
    RETURNING id :: uuid
  |]

setCardsByIdStatement :: Statement.Statement (UUID, Vector Int32) ()
setCardsByIdStatement =
  [resultlessStatement|
    UPDATE entity SET cards = $2 :: int4[]
    WHERE id = $1 :: uuid
  |]

setCardsByNameStatement :: Statement.Statement (Text, Vector Int32) ()
setCardsByNameStatement =
  [resultlessStatement|
    UPDATE entity SET cards = $2 :: int4[]
    WHERE shortname = $1 :: text
  |]

getEntityByIdStatement :: Statement.Statement UUID (Text, Text, Vector Int32)
getEntityByIdStatement =
  [singletonStatement|
    SELECT shortname :: text, fullname :: text, cards :: int4[]
    FROM entity
    WHERE id = $1 :: uuid
  |]

getEntityByNameStatement :: Statement.Statement Text (UUID, Text, Vector Int32)
getEntityByNameStatement =
  [singletonStatement|
    SELECT id :: uuid, fullname :: text, cards :: int4[]
    FROM entity
    WHERE shortname = $1 :: text
  |]

getEntitiesStatement :: Statement.Statement () (Vector (UUID, Text, Text, Vector Int32))
getEntitiesStatement =
  [vectorStatement|
    SELECT id :: uuid, shortname :: text, fullname :: text, cards :: int4[]
    FROM entity
  |]

getHistoryStatement :: Statement.Statement () (Vector (LocalTime, Text, Vector Int32, Text))
getHistoryStatement =
  [vectorStatement|
    SELECT action.ts :: timestamp, sub.shortname :: text, action.cards :: int4[], rec.shortname :: text
    FROM action
      LEFT JOIN entity AS sub ON sub.id = action.subject
      LEFT JOIN entity AS rec ON rec.id = action.receiver
    ORDER BY action.ts
  |]

adjustByIdStatement :: Statement.Statement (UUID, LocalTime, Vector Int32, Maybe Text) UUID
adjustByIdStatement =
  [singletonStatement|
    INSERT INTO action (subject, action, ts, cards, comment)
    VALUES ($1 :: uuid, 'adjust', $2 :: timestamp, $3 :: int4[], $4 :: text?)
    RETURNING id :: uuid
  |]

adjustByNameStatement :: Statement.Statement (Text, LocalTime, Vector Int32, Maybe Text) UUID
adjustByNameStatement =
  [singletonStatement|
    INSERT INTO action (subject, action, ts, cards, comment)
    SELECT id, 'adjust', $2 :: timestamp, $3 :: int4[], $4 :: text?
    FROM entity
    WHERE shortname = $1 :: text
    RETURNING action.id :: uuid
  |]
