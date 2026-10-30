
class AddEventGuards < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE FUNCTION events_append_only() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'events is append-only';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER events_no_update_delete
        BEFORE UPDATE OR DELETE ON events
        FOR EACH ROW EXECUTE FUNCTION events_append_only();

      CREATE TRIGGER events_no_truncate
        BEFORE TRUNCATE ON events
        FOR EACH STATEMENT EXECUTE FUNCTION events_append_only();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER events_no_truncate ON events;
      DROP TRIGGER events_no_update_delete ON events;
      DROP FUNCTION events_append_only();
    SQL
  end
end