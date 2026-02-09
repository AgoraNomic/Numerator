-- Migration: create-notes
-- Created at: 20260209080914

-- up

BEGIN TRANSACTION;

CREATE TABLE note(
	id UUID PRIMARY KEY DEFAULT uuidv4(),
	start_time TIMESTAMP(0),
	end_time TIMESTAMP(0),
	content TEXT,
	CONSTRAINT ordered CHECK (start_time < end_time)
);

COMMIT;

-- down

DROP TABLE note;
