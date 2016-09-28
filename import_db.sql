DROP TABLE if exists users;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS question_likes;


CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  asker_id INTEGER NOT NULL,

  FOREIGN KEY (asker_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  question_id INTEGER,
  follower_id INTEGER,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (follower_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  replier_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (replier_id) REFERENCES users(id)
);

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  liker_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (liker_id) REFERENCES users(id)
);

INSERT INTO
  users(fname, lname)
VALUES
  ('Lindsey', 'Whitley'),
  ('Tyler', 'Fields'),
  ('Abraham', 'Lincoln'),
  ('Luke', 'Skywalker'),
  ('Bugs', 'Bunny');

INSERT INTO
  questions(title, body, asker_id)
VALUES
  ('Halp', 'What is SQL?', (SELECT id FROM users WHERE fname = 'Lindsey')),
  ('What?', 'Seriously?', (SELECT id FROM users WHERE fname = 'Lindsey')),
  ('How?', 'Does this even work?', (SELECT id FROM users WHERE fname = 'Lindsey')),
  ('Why?', 'What am I doing with my life?', (SELECT id FROM users WHERE fname = 'Lindsey')),
  ('UM...', 'What is a YAML', (SELECT id FROM users WHERE fname = 'Lindsey')),
  ('idk', 'How do joins work?', (SELECT id FROM users WHERE fname = 'Tyler'));

INSERT INTO
  question_follows(question_id, follower_id)
VALUES
  ((SELECT id FROM questions WHERE title = 'idk'),
    (SELECT id FROM users WHERE fname = 'Lindsey')),
    ((SELECT id FROM questions WHERE title = 'Halp'),
      (SELECT id FROM users WHERE fname = 'Lindsey')),
  ((SELECT id FROM questions WHERE title = 'Halp'),
    (SELECT id FROM users WHERE fname = 'Tyler'));

INSERT INTO
  replies(question_id, parent_id, replier_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'idk'),
    NULL, (SELECT id FROM users WHERE fname = 'Lindsey'), 'No.');

INSERT INTO
  replies(question_id, parent_id, replier_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'idk'),
    (SELECT id FROM replies WHERE body = 'No.'),
    (SELECT id FROM users WHERE fname = 'Tyler'), 'Yes.');

INSERT INTO
  question_likes(question_id, liker_id)
VALUES
  ((SELECT id FROM questions WHERE title = 'Halp'),
    (SELECT id FROM users WHERE fname = 'Lindsey')),
  ((SELECT id FROM questions WHERE title = 'Halp'),
    (SELECT id FROM users WHERE fname = 'Bugs')),
  ((SELECT id FROM questions WHERE title = 'Halp'),
    (SELECT id FROM users WHERE fname = 'Abraham')),
  ((SELECT id FROM questions WHERE title = 'Halp'),
    (SELECT id FROM users WHERE fname = 'Luke')),
  ((SELECT id FROM questions WHERE title = 'Halp'),
    (SELECT id FROM users WHERE fname = 'Tyler')),

    ((SELECT id FROM questions WHERE title = 'How?'),
    (SELECT id FROM users WHERE fname = 'Tyler')),
    ((SELECT id FROM questions WHERE title = 'How?'),
    (SELECT id FROM users WHERE fname = 'Abraham')),
    ((SELECT id FROM questions WHERE title = 'How?'),
    (SELECT id FROM users WHERE fname = 'Bugs')),

    ((SELECT id FROM questions WHERE title = 'Why?'),
    (SELECT id FROM users WHERE fname = 'Tyler')),
    ((SELECT id FROM questions WHERE title = 'Why?'),
    (SELECT id FROM users WHERE fname = 'Abraham')),
    ((SELECT id FROM questions WHERE title = 'Why?'),
    (SELECT id FROM users WHERE fname = 'Bugs')),

    ((SELECT id FROM questions WHERE title = 'What?'),
    (SELECT id FROM users WHERE fname = 'Bugs')),

  ((SELECT id FROM questions WHERE title = 'idk'),
    (SELECT id FROM users WHERE fname = 'Lindsey'));
