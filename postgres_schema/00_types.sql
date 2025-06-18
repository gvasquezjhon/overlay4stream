-- PostgreSQL ENUM type definitions
-- Based on modelo-er.sql

-- For tenants table
CREATE TYPE tax_regime_enum AS ENUM ('RUS', 'RER', 'GENERAL', 'MYPE');
CREATE TYPE business_type_enum AS ENUM ('GENERAL', 'RESTAURANT', 'RETAIL', 'SERVICE');
CREATE TYPE sunat_environment_enum AS ENUM ('BETA', 'PRODUCTION');
CREATE TYPE subscription_plan_enum AS ENUM ('NRUS', 'PROFESSIONAL', 'ENTERPRISE');
CREATE TYPE billing_cycle_enum AS ENUM ('MONTHLY', 'YEARLY');

-- For users table
CREATE TYPE user_role_enum AS ENUM ('OWNER', 'ADMIN', 'ACCOUNTANT', 'SELLER', 'VIEWER');

-- For tenant_settings table
CREATE TYPE tenant_setting_category_enum AS ENUM ('GENERAL', 'INVOICING', 'INVENTORY', 'ACCOUNTING', 'NOTIFICATIONS');
CREATE TYPE tenant_setting_data_type_enum AS ENUM ('STRING', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'JSON');

-- For sunat_tax_types table
CREATE TYPE sunat_tax_applies_to_enum AS ENUM ('PRODUCTS', 'SERVICES', 'BOTH');

-- For products table
CREATE TYPE product_type_enum AS ENUM ('PRODUCT', 'SERVICE', 'DIGITAL');
CREATE TYPE product_costing_method_enum AS ENUM ('FIFO', 'LIFO', 'AVERAGE', 'SPECIFIC');

-- Generic ENUMs (reused across tables)
CREATE TYPE customer_type_enum AS ENUM ('INDIVIDUAL', 'BUSINESS');
CREATE TYPE document_type_enum AS ENUM ('RUC', 'DNI', 'PASSPORT', 'OTHER'); -- Used in customers, suppliers, invoices
CREATE TYPE company_size_enum AS ENUM ('SMALL', 'MEDIUM', 'LARGE'); -- Used in customers
CREATE TYPE supplier_rating_enum AS ENUM ('A', 'B', 'C', 'D'); -- Used in suppliers

CREATE TYPE invoice_reference_type_enum AS ENUM ('CREDIT_NOTE', 'DEBIT_NOTE', 'RECTIFICATION'); -- Used in invoices
CREATE TYPE payment_method_enum AS ENUM ('CASH', 'TRANSFER', 'CARD', 'CHECK', 'CREDIT', 'YAPE', 'PLIN', 'OTHER'); -- Used in invoices, purchase_orders, expenses
CREATE TYPE payment_status_enum AS ENUM ('PENDING', 'PARTIAL', 'PAID', 'OVERDUE', 'CANCELLED'); -- Used in invoices, purchase_orders, expenses
CREATE TYPE sunat_status_enum AS ENUM ('DRAFT', 'SENT', 'ACCEPTED', 'REJECTED', 'CANCELLED', 'ERROR'); -- Used in invoices
CREATE TYPE generic_status_enum AS ENUM ( -- Used in invoices, purchase_orders, expenses, quotations, transactions, payments
    'DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'SENT', 'CANCELLED', 'VOIDED', -- for invoices
    'CONFIRMED', 'RECEIVED', -- for purchase_orders
    'POSTED', -- for transactions
    'PAID', -- for expenses, payments
    'ACCEPTED', 'REJECTED', 'EXPIRED', 'CONVERTED', -- for quotations
    'PENDING' -- for payments
);
CREATE TYPE purchase_order_item_status_enum AS ENUM ('PENDING', 'PARTIAL', 'RECEIVED', 'CANCELLED'); -- Used in purchase_order_items

-- For stock_movements table
CREATE TYPE stock_movement_type_enum AS ENUM ('IN', 'OUT', 'TRANSFER', 'ADJUSTMENT');
CREATE TYPE stock_movement_reason_enum AS ENUM (
    'SALE', 'PURCHASE', 'RETURN', 'ADJUSTMENT',
    'TRANSFER', 'INITIAL_STOCK', 'DAMAGED',
    'EXPIRED', 'PROMOTION', 'SAMPLE'
);
CREATE TYPE reference_type_enum AS ENUM ('INVOICE', 'PURCHASE', 'TRANSFER', 'ADJUSTMENT', 'MANUAL', 'EXPENSE', 'PAYMENT', 'ADVANCE', 'REFUND'); -- Used in stock_movements, transactions, payments

-- For accounts table
CREATE TYPE account_type_enum AS ENUM ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE');

-- For cash_register_sessions table
CREATE TYPE cash_register_session_status_enum AS ENUM ('OPEN', 'CLOSED');

-- For payment_methods table
CREATE TYPE payment_method_type_enum AS ENUM ('CASH', 'BANK_TRANSFER', 'CARD', 'DIGITAL_WALLET', 'CHECK', 'CREDIT', 'OTHER');

-- For payments table
CREATE TYPE payment_entity_type_enum AS ENUM ('CUSTOMER', 'SUPPLIER');

-- For activity_logs table
CREATE TYPE activity_log_action_enum AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'VIEW', 'EXPORT', 'IMPORT');

-- For sunat_integration_logs table
CREATE TYPE sunat_operation_type_enum AS ENUM ('SEND_DOCUMENT', 'GET_STATUS', 'GET_CDR', 'VOID_DOCUMENT', 'SUMMARY');
