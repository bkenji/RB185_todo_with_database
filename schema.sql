DROP TABLE IF EXISTS lists;

CREATE TABLE lists (
  id serial PRIMARY KEY,
  name text NOT NULL,
  user_id int NOT NULL REFERENCES users(id),
  UNIQUE (name, user_id)
);

DROP TABLE IF EXISTS todos;

CREATE TABLE todos (
  id serial PRIMARY KEY,
  name text NOT NULL,
  completed boolean NOT NULL DEFAULT false,
  list_id int NOT NULL REFERENCES lists(id)
   ON DELETE CASCADE
);

DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id serial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  hashed_pw text NOT NULL,
  CHECK (username ~ '^[A-Za-z0-9_]+$')
);