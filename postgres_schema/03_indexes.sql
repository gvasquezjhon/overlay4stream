-- =====================================================
-- ADDITIONAL INDEXES AND FULL-TEXT SEARCH
-- =====================================================

-- -----------------------------------------------------
-- Full-Text Search (FTS) Indexes
-- -----------------------------------------------------

-- For products table (name and description)
-- Option 1: Index on expressions
CREATE INDEX idx_products_fts ON products USING GIN (to_tsvector('simple', name || ' ' || coalesce(description, '')));

-- For customers table (business_name, first_name, last_name)
-- Option 1: Index on expressions
CREATE INDEX idx_customers_fts ON customers USING GIN (to_tsvector('simple', coalesce(business_name, '') || ' ' || coalesce(first_name, '') || ' ' || coalesce(last_name, '')));


-- -----------------------------------------------------
-- Composite Indexes from original schema (Performance Optimizations)
-- -----------------------------------------------------

-- Note: Some of these might be redundant if very similar indexes were created with tables,
-- or if query patterns in PostgreSQL differ. Review based on actual usage.

CREATE INDEX idx_invoices_tenant_status_date ON invoices(tenant_id, status, issue_date);
CREATE INDEX idx_invoices_customer_id_issue_date_desc ON invoices(customer_id, issue_date DESC); -- Renamed from idx_invoices_customer_date
CREATE INDEX idx_invoices_payment_status_due_date ON invoices(payment_status, due_date); -- Renamed from idx_invoices_payment_status_due

CREATE INDEX idx_products_tenant_category_is_active ON products(tenant_id, category_id, is_active); -- Renamed
CREATE INDEX idx_products_tenant_track_inventory_current_stock ON products(tenant_id, track_inventory, current_stock); -- Renamed

CREATE INDEX idx_stock_movements_product_id_movement_date_desc ON stock_movements(product_id, movement_date DESC); -- Renamed
CREATE INDEX idx_stock_movements_warehouse_id_movement_type_date ON stock_movements(warehouse_id, movement_type, movement_date); -- Renamed

CREATE INDEX idx_transactions_tenant_reference_type_date ON transactions(tenant_id, reference_type, transaction_date); -- Renamed
CREATE INDEX idx_expenses_tenant_category_id_expense_date ON expenses(tenant_id, category_id, expense_date); -- Renamed

-- -----------------------------------------------------
-- Review existing indexes in 01_tables.sql to avoid significant overlap.
-- For example, idx_products_tenant_is_active (tenant_id, is_active) was already created.
-- The one above (idx_products_tenant_category_is_active) is more specific.
-- Ensure index names are unique.
-- -----------------------------------------------------
