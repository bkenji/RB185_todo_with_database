DROP TABLE IF EXISTS lists;

CREATE TABLE lists (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL 
);

DROP TABLE IF EXISTS todos;

CREATE TABLE todos (
  id serial PRIMARY KEY,
  name text NOT NULL,
  completed boolean NOT NULL DEFAULT false,
  list_id int NOT NULL REFERENCES lists(id)
   ON DELETE CASCADE
);