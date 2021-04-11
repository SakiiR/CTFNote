CREATE TABLE ctfnote.task (
  "id" serial PRIMARY KEY,
  "title" text NOT NULL,
  "description" text,
  "category" text,
  "flag" text,
  "pad_url" text NOT NULL,
  "ctf_id" integer REFERENCES ctfnote.ctf (id) NOT NULL
);

CREATE INDEX ON ctfnote.task (ctf_id);

GRANT SELECT ON TABLE ctfnote.task TO user_guest;

GRANT UPDATE (title, description, category, flag) ON TABLE ctfnote.task TO user_guest;

GRANT DELETE ON TABLE ctfnote.task TO user_guest;

GRANT usage ON SEQUENCE ctfnote.task_id_seq
  TO user_guest;

CREATE FUNCTION ctfnote_private.create_task (title text, description text, category text, flag text, pad_url text, ctf_id int)
  RETURNS ctfnote.task
  AS $$
  INSERT INTO ctfnote.task (title, description, category, flag, pad_url, ctf_id)
    VALUES (title, description, category, flag, pad_url, ctf_id)
  RETURNING
    *;

$$
LANGUAGE SQL
SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION ctfnote_private.create_task (text, text, text, text, text, int) TO user_guest;

CREATE FUNCTION ctfnote.task_solved(task ctfnote.task) returns BOOLEAN AS $$
SELECT NOT (task.flag IS NULL OR task.flag = '');
$$
LANGUAGE SQL STABLE; 

GRANT EXECUTE ON FUNCTION ctfnote.task_solved (ctfnote.task) TO user_guest;


CREATE FUNCTION ctfnote_private.delete_task_by_ctf ()
    RETURNS TRIGGER
    AS $$
BEGIN
    DELETE FROM ctfnote.task
    WHERE task.ctf_id = OLD.id;
    RETURN OLD;
END
$$
LANGUAGE plpgsql
SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION ctfnote_private.delete_task_by_ctf () TO user_guest;

CREATE TRIGGER delete_task_on_ctf_delete
    BEFORE DELETE ON ctfnote.ctf
    FOR EACH ROW
    EXECUTE PROCEDURE ctfnote_private.delete_task_by_ctf ();



CREATE FUNCTION ctfnote_private.can_play_task (task_id int)
  RETURNS boolean
  AS $$
  SELECT
    ctfnote_private.is_member ()
    OR (
      SELECT
        ctfnote_private.can_play_ctf (ctf.id)
      FROM
        ctfnote.ctf,
        ctfnote.task
      WHERE
        task.id = can_play_task.task_id
        AND task.ctf_id = ctf.id)
$$
LANGUAGE sql
STABLE;

GRANT EXECUTE ON FUNCTION ctfnote_private.can_play_task TO user_guest;