-- =====================================================
-- TRIGGER FUNCTIONS AND TRIGGERS
-- =====================================================

-- -----------------------------------------------------
-- Generic function to update 'updated_at' or 'last_updated' timestamp
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF TG_TABLE_NAME = 'currencies' THEN
            NEW.last_updated = CURRENT_TIMESTAMP;
        ELSE
            NEW.updated_at = CURRENT_TIMESTAMP;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------
-- Trigger for invoices.full_number
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION fn_update_invoice_full_number()
RETURNS TRIGGER AS $$
DECLARE
    v_series_prefix VARCHAR(10);
BEGIN
    IF NEW.series_id IS NOT NULL AND NEW.document_number IS NOT NULL THEN
        SELECT series_prefix INTO v_series_prefix FROM document_series WHERE id = NEW.series_id;
        IF FOUND THEN
            NEW.full_number = v_series_prefix || '-' || LPAD(NEW.document_number::TEXT, 8, '0');
        ELSE
            -- Handle case where series_id might be invalid, though FK should prevent this.
            -- For safety, or if series_id could be temporarily null during some operations.
            NEW.full_number = 'ERROR-' || LPAD(NEW.document_number::TEXT, 8, '0');
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_invoice_full_number
BEFORE INSERT OR UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION fn_update_invoice_full_number();

-- -----------------------------------------------------
-- Apply fn_update_timestamp to relevant tables
-- -----------------------------------------------------

-- tenants
CREATE TRIGGER trg_tenants_update_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- users
CREATE TRIGGER trg_users_update_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- tenant_settings
CREATE TRIGGER trg_tenant_settings_update_updated_at
BEFORE UPDATE ON tenant_settings
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- currencies (for last_updated)
CREATE TRIGGER trg_currencies_update_last_updated
BEFORE UPDATE ON currencies
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- product_categories
CREATE TRIGGER trg_product_categories_update_updated_at
BEFORE UPDATE ON product_categories
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- products
CREATE TRIGGER trg_products_update_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- customers
CREATE TRIGGER trg_customers_update_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- suppliers
CREATE TRIGGER trg_suppliers_update_updated_at
BEFORE UPDATE ON suppliers
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- invoices (also has full_number trigger)
CREATE TRIGGER trg_invoices_update_updated_at
BEFORE UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- invoice_items
CREATE TRIGGER trg_invoice_items_update_updated_at
BEFORE UPDATE ON invoice_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- purchase_orders
CREATE TRIGGER trg_purchase_orders_update_updated_at
BEFORE UPDATE ON purchase_orders
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- purchase_order_items
CREATE TRIGGER trg_purchase_order_items_update_updated_at
BEFORE UPDATE ON purchase_order_items
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- product_stock_by_warehouse
CREATE TRIGGER trg_product_stock_by_warehouse_update_updated_at
BEFORE UPDATE ON product_stock_by_warehouse
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- accounts
CREATE TRIGGER trg_accounts_update_updated_at
BEFORE UPDATE ON accounts
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- transactions
CREATE TRIGGER trg_transactions_update_updated_at
BEFORE UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- expenses
CREATE TRIGGER trg_expenses_update_updated_at
BEFORE UPDATE ON expenses
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- quotations
CREATE TRIGGER trg_quotations_update_updated_at
BEFORE UPDATE ON quotations
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();

-- payments
CREATE TRIGGER trg_payments_update_updated_at
BEFORE UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION fn_update_timestamp();
