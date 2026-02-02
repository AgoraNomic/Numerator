-- Migration: create-basic
-- Created at: 20260127081326

-- up

BEGIN TRANSACTION;

CREATE TABLE entity(
	id UUID PRIMARY KEY DEFAULT uuidv4(),
	shortname VARCHAR(8) UNIQUE NOT NULL,
	fullname TEXT,
	cards INTEGER[10] NOT NULL DEFAULT ARRAY[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	CONSTRAINT tencards CHECK (array_length(cards, 1) = 10)
);

CREATE TYPE TRANSACTION_TYPE AS ENUM(
	'adjust',
	'transfer',
	'transmute'
);

CREATE TABLE action(
	id UUID PRIMARY KEY DEFAULT uuidv4(),
	subject UUID NOT NULL REFERENCES entity ON DELETE RESTRICT,
	receiver UUID REFERENCES entity ON DELETE RESTRICT,
	action TRANSACTION_TYPE NOT NULL,
	ts TIMESTAMP(0) NOT NULL,
	cards INTEGER[10] NOT NULL,
	comment TEXT,
	CONSTRAINT tencards CHECK (array_length(cards, 1) = 10),
	CONSTRAINT arity CHECK (
		CASE WHEN action = 'transfer'
		THEN RECEIVER IS NOT NULL
		ELSE RECEIVER IS NULL
		END
	)
);

CREATE INDEX timestamp_order ON action(ts);

COMMIT;

-- down

DROP TABLE action;
DROP TYPE TRANSACTION_TYPE;
DROP TABLE entity;
