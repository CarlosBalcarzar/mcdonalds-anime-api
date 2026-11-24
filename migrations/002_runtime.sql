SET LOCAL search_path TO mcd,pg_catalog;
CREATE ROLE mcd_api LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOBYPASSRLS;
ALTER ROLE mcd_api SET search_path TO mcd,pg_catalog;
GRANT USAGE ON SCHEMA mcd TO mcd_api;
GRANT SELECT ON roles, permissions, role_permissions, profiles, categories, products, inventory,
 orders, order_items, deliveries, payments, order_status_history, promotions, promotion_products,
 support_tickets, support_messages, addresses, audit_logs TO mcd_api;
GRANT INSERT ON profiles, categories, products, inventory, orders, order_items, deliveries, payments,
 order_status_history, inventory_movements, promotions, promotion_products, support_tickets,
 support_messages, addresses, audit_logs, role_permissions TO mcd_api;
GRANT UPDATE ON products, inventory, orders, payments, promotions, support_tickets, addresses TO mcd_api;
GRANT UPDATE(name,role,active) ON profiles TO mcd_api;
GRANT DELETE ON addresses, role_permissions TO mcd_api;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA mcd TO mcd_api;
DO $$ DECLARE t text; BEGIN
 FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='mcd'
 AND tablename NOT IN ('auth_credentials','sessions','schema_migrations')
 LOOP EXECUTE format('CREATE POLICY runtime_access ON mcd.%I TO mcd_api USING (true) WITH CHECK (true)',t); END LOOP;
END $$;
CREATE INDEX order_history_by_order ON order_status_history(order_id,id);
CREATE INDEX messages_by_ticket ON support_messages(ticket_id,id);
CREATE INDEX tickets_assignment ON support_tickets(assigned_to);
CREATE INDEX addresses_owner ON addresses(user_id);
