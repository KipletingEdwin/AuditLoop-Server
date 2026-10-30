
class AddRefundGuard < ActiveRecord::Migration[8.1]
  def up
    # Total non-failed refunds on a charge can never exceed the charge.
    # FOR UPDATE on the charge row serializes concurrent refunds.
    execute <<~SQL
      CREATE FUNCTION enforce_refund_cap() RETURNS trigger AS $$
      DECLARE
        charge_total integer;
        already_refunded integer;
      BEGIN
        SELECT amount_cents INTO charge_total FROM charges WHERE id = NEW.charge_id FOR UPDATE;
        SELECT COALESCE(SUM(amount_cents), 0) INTO already_refunded
          FROM refunds WHERE charge_id = NEW.charge_id AND status <> 'failed';

        IF already_refunded + NEW.amount_cents > charge_total THEN
          RAISE EXCEPTION 'refunds would exceed charge amount' USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER refunds_cap_check
        BEFORE INSERT ON refunds
        FOR EACH ROW EXECUTE FUNCTION enforce_refund_cap();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER refunds_cap_check ON refunds;
      DROP FUNCTION enforce_refund_cap();
    SQL
  end
end