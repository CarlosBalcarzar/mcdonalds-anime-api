CREATE SCHEMA IF NOT EXISTS mcd;
SET search_path TO mcd,public;
CREATE TABLE roles(name text PRIMARY KEY);
INSERT INTO roles VALUES ('customer'),('employee'),('admin'),('superadmin') ON CONFLICT DO NOTHING;
CREATE TABLE permissions(name text PRIMARY KEY);
CREATE TABLE role_permissions(role text REFERENCES roles,permission text REFERENCES permissions,PRIMARY KEY(role,permission));
INSERT INTO permissions VALUES ('orders.manage'),('orders.assigned'),('payments.manage'),('catalog.manage'),('inventory.manage'),('promotions.manage'),('staff.manage'),('support.manage'),('support.assigned'),('reports.read'),('roles.manage'),('audit.read'),('orders.deliver'),('payments.assigned');
INSERT INTO role_permissions SELECT 'superadmin',name FROM permissions;
INSERT INTO role_permissions SELECT 'admin',name FROM permissions WHERE name NOT IN ('roles.manage','audit.read','orders.deliver','payments.assigned');
INSERT INTO role_permissions VALUES ('employee','orders.assigned'),('employee','support.assigned');
CREATE TABLE profiles(id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, email text UNIQUE NOT NULL, role text NOT NULL DEFAULT 'customer' REFERENCES roles, active boolean NOT NULL DEFAULT true, created_at timestamptz DEFAULT now());
CREATE TABLE auth_credentials(user_id uuid PRIMARY KEY REFERENCES profiles, password_hash text NOT NULL);
CREATE TABLE sessions(token_hash text PRIMARY KEY, user_id uuid NOT NULL REFERENCES profiles, expires_at timestamptz NOT NULL);
CREATE TABLE addresses(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES profiles, address text NOT NULL);
CREATE TABLE categories(name text PRIMARY KEY, active boolean NOT NULL DEFAULT true);
CREATE TABLE products(id text PRIMARY KEY, name text NOT NULL, category text NOT NULL REFERENCES categories, description text NOT NULL, price numeric(12,2) NOT NULL CHECK(price>=0), image text NOT NULL, active boolean NOT NULL DEFAULT true, version integer NOT NULL DEFAULT 0, position integer NOT NULL DEFAULT 1000);
CREATE TABLE inventory(product_id text PRIMARY KEY REFERENCES products, quantity integer NOT NULL DEFAULT 0 CHECK(quantity>=0), reserved integer NOT NULL DEFAULT 0 CHECK(reserved>=0 AND reserved<=quantity), version integer NOT NULL DEFAULT 0);
CREATE TABLE orders(id uuid PRIMARY KEY DEFAULT gen_random_uuid(), number bigint GENERATED ALWAYS AS IDENTITY UNIQUE, user_id uuid NOT NULL REFERENCES profiles, assigned_to uuid REFERENCES profiles, status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','confirmed','preparing','ready','waiting','on_way','delivered','cancelled')), total numeric(12,2) NOT NULL CHECK(total>=0), version integer NOT NULL DEFAULT 0, request_key uuid NOT NULL, request_hash text NOT NULL, created_at timestamptz DEFAULT now(), UNIQUE(user_id,request_key));
CREATE TABLE order_items(order_id uuid REFERENCES orders, product_id text REFERENCES products, name text NOT NULL, unit_price numeric(12,2) NOT NULL CHECK(unit_price>=0), quantity integer NOT NULL CHECK(quantity>0), PRIMARY KEY(order_id,product_id));
CREATE TABLE deliveries(order_id uuid PRIMARY KEY REFERENCES orders, method text NOT NULL CHECK(method IN ('pickup','delivery')), address text, CHECK(method='pickup' OR length(address)>0));
CREATE TABLE payments(order_id uuid PRIMARY KEY REFERENCES orders, method text NOT NULL CHECK(method IN ('cash','qr')), status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','verification','paid','rejected','refunded')));
CREATE TABLE order_status_history(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, order_id uuid REFERENCES orders, actor uuid REFERENCES profiles, status text NOT NULL, reason text, created_at timestamptz DEFAULT now());
CREATE TABLE inventory_movements(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, product_id text REFERENCES products, order_id uuid REFERENCES orders, actor uuid REFERENCES profiles, quantity_delta integer NOT NULL, reserved_delta integer NOT NULL, reason text NOT NULL, created_at timestamptz DEFAULT now());
CREATE TABLE promotions(id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, active boolean NOT NULL DEFAULT true, starts_at timestamptz, ends_at timestamptz, CHECK(ends_at IS NULL OR starts_at IS NULL OR ends_at>starts_at));
CREATE TABLE promotion_products(promotion_id uuid REFERENCES promotions, product_id text REFERENCES products, PRIMARY KEY(promotion_id,product_id));
CREATE TABLE support_tickets(id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid REFERENCES profiles, assigned_to uuid REFERENCES profiles, name text NOT NULL,email text NOT NULL,subject text NOT NULL,status text NOT NULL DEFAULT 'open' CHECK(status IN ('open','closed')), created_at timestamptz DEFAULT now());
CREATE TABLE support_messages(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,ticket_id uuid REFERENCES support_tickets, actor uuid REFERENCES profiles, message text NOT NULL, created_at timestamptz DEFAULT now());
CREATE TABLE audit_logs(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,actor uuid REFERENCES profiles, action text NOT NULL, resource text NOT NULL, record_id text NOT NULL, created_at timestamptz DEFAULT now());
CREATE INDEX orders_owner ON orders(user_id); CREATE INDEX orders_assignment ON orders(assigned_to); CREATE INDEX tickets_owner ON support_tickets(user_id);
-- Private schema: no direct browser access. API authorization applies to each request.
REVOKE ALL ON SCHEMA mcd FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA mcd FROM PUBLIC;

-- Deny all direct row access for non-owner roles unless explicitly granted a server policy.
DO $$ DECLARE t record; BEGIN FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='mcd' LOOP EXECUTE format('ALTER TABLE mcd.%I ENABLE ROW LEVEL SECURITY',t.tablename); END LOOP; END $$;
