-- =====================================================
-- CORE MULTI-TENANCY & BUSINESS SETUP
-- =====================================================

CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    ruc VARCHAR(11) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    district VARCHAR(100),
    province VARCHAR(100),
    department VARCHAR(100),
    tax_regime tax_regime_enum NOT NULL,
    business_type business_type_enum DEFAULT 'GENERAL',

    -- SUNAT Integration
    sunat_environment sunat_environment_enum DEFAULT 'BETA',
    sunat_certificate_path VARCHAR(500),
    sunat_certificate_password VARCHAR(255),
    sunat_ruc_user VARCHAR(50),
    sunat_ruc_password VARCHAR(255),

    -- Subscription & Billing
    subscription_plan subscription_plan_enum DEFAULT 'NRUS',
    monthly_price DECIMAL(8,2) DEFAULT 69.00,
    trial_ends_at TIMESTAMP NULL,
    billing_cycle billing_cycle_enum DEFAULT 'MONTHLY',
    max_branches INT DEFAULT 1,
    max_users INT DEFAULT 5,

    -- Media & Customization
    logo_url VARCHAR(500),
    primary_color VARCHAR(7) DEFAULT '#1f2937',
    secondary_color VARCHAR(7) DEFAULT '#3b82f6',

    -- Status & Audit
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    CONSTRAINT check_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$') -- Example check, adjust as needed
);

CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_ruc ON tenants(ruc);
CREATE INDEX idx_tenants_subscription_plan_is_active ON tenants(subscription_plan, is_active);


-- =====================================================
-- USER MANAGEMENT & PERMISSIONS
-- =====================================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dni VARCHAR(8),
    phone VARCHAR(20),

    -- Role & Permissions
    role user_role_enum NOT NULL,
    permissions JSONB, -- Granular permissions, using JSONB for better performance
    branch_access JSONB, -- Array of branch IDs user can access, using JSONB

    -- Status & Activity
    is_active BOOLEAN DEFAULT TRUE,
    email_verified_at TIMESTAMP NULL,
    last_login_at TIMESTAMP NULL,
    password_reset_token VARCHAR(255),
    password_reset_expires_at TIMESTAMP NULL,

    -- Audit
    created_by BIGINT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT unique_email_per_tenant UNIQUE (tenant_id, email)
);

CREATE INDEX idx_users_tenant_role ON users(tenant_id, role);
CREATE INDEX idx_users_tenant_is_active ON users(tenant_id, is_active);


-- =====================================================
-- BUSINESS CONFIGURATION
-- =====================================================

CREATE TABLE branches (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(200) NOT NULL,
    address TEXT,
    district VARCHAR(100),
    province VARCHAR(100),
    department VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(255),
    is_main_branch BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_branches_tenant_is_active ON branches(tenant_id, is_active);


CREATE TABLE tenant_settings (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    category tenant_setting_category_enum NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    data_type tenant_setting_data_type_enum DEFAULT 'STRING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT unique_setting_per_tenant UNIQUE (tenant_id, category, setting_key)
);

CREATE INDEX idx_tenant_settings_tenant_category ON tenant_settings(tenant_id, category);


-- =====================================================
-- SUNAT CONFIGURATION TABLES
-- =====================================================

CREATE TABLE document_types (
    id SERIAL PRIMARY KEY,
    sunat_code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    is_credit_note BOOLEAN DEFAULT FALSE,
    is_debit_note BOOLEAN DEFAULT FALSE,
    requires_reference BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);


CREATE TABLE sunat_tax_types (
    id SERIAL PRIMARY KEY,
    sunat_code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    rate DECIMAL(5,2) NOT NULL,
    is_percentage BOOLEAN DEFAULT TRUE,
    is_included_in_price BOOLEAN DEFAULT TRUE,
    is_gratuita BOOLEAN DEFAULT FALSE,
    applies_to sunat_tax_applies_to_enum DEFAULT 'BOTH',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);


CREATE TABLE sunat_units (
    id SERIAL PRIMARY KEY,
    sunat_code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    symbol VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE
);


CREATE TABLE currencies (
    id SERIAL PRIMARY KEY,
    iso_code CHAR(3) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,
    is_base_currency BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Trigger will handle ON UPDATE
);


-- =====================================================
-- PRODUCT MANAGEMENT
-- =====================================================

CREATE TABLE product_categories (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES product_categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_product_categories_tenant_parent ON product_categories(tenant_id, parent_id);
CREATE INDEX idx_product_categories_sort_order ON product_categories(sort_order);


CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    code VARCHAR(50) NOT NULL,
    barcode VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Classification
    category_id BIGINT NULL,
    product_type product_type_enum DEFAULT 'PRODUCT',
    unit_id INT NOT NULL, -- References sunat_units(id)
    tax_type_id INT NOT NULL, -- References sunat_tax_types(id)

    -- Pricing
    cost_price DECIMAL(12,2) DEFAULT 0,
    sale_price DECIMAL(12,2) NOT NULL,
    wholesale_price DECIMAL(12,2),
    currency_id INT NOT NULL, -- References currencies(id)
    price_includes_tax BOOLEAN DEFAULT TRUE,

    -- Inventory Management
    track_inventory BOOLEAN DEFAULT TRUE,
    initial_stock DECIMAL(12,3) DEFAULT 0,
    current_stock DECIMAL(12,3) DEFAULT 0,
    reserved_stock DECIMAL(12,3) DEFAULT 0,
    min_stock_alert DECIMAL(12,3) DEFAULT 0,
    max_stock DECIMAL(12,3),

    -- Costing Method
    costing_method product_costing_method_enum DEFAULT 'AVERAGE',

    -- Media & Presentation
    primary_image_url VARCHAR(500),
    gallery_images JSONB,

    -- SEO & Online
    slug VARCHAR(255),
    meta_title VARCHAR(255),
    meta_description TEXT,
    tags JSONB,

    -- Status & Audit
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE
    deleted_at TIMESTAMP NULL,

    -- Full-text search will be handled by a tsvector column and GIN index created in 03_indexes.sql
    -- name_tsvector TSVECTOR GENERATED ALWAYS AS (to_tsvector('simple', name || ' ' || coalesce(description, ''))) STORED,

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE SET NULL,
    FOREIGN KEY (unit_id) REFERENCES sunat_units(id),
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),

    CONSTRAINT unique_products_code_per_tenant UNIQUE (tenant_id, code),
    CONSTRAINT unique_products_barcode_per_tenant UNIQUE (tenant_id, barcode)
);

CREATE INDEX idx_products_tenant_is_active ON products(tenant_id, is_active);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_stock_alerts ON products(tenant_id, track_inventory, current_stock, min_stock_alert) WHERE track_inventory = TRUE;
-- CREATE INDEX idx_products_name_description_fts ON products USING GIN (to_tsvector('simple', name || ' ' || coalesce(description, ''))); -- Example for FTS, will be in 03_indexes.sql


-- =====================================================
-- CUSTOMER MANAGEMENT
-- =====================================================

CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    customer_code VARCHAR(50),

    -- Personal/Business Info
    customer_type customer_type_enum NOT NULL,
    document_type document_type_enum NOT NULL,
    document_number VARCHAR(20) NOT NULL,

    -- Names
    business_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),

    -- Contact Information
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    website VARCHAR(255),

    -- Address Information
    address TEXT,
    district VARCHAR(100),
    province VARCHAR(100),
    department VARCHAR(100),
    postal_code VARCHAR(10),
    country VARCHAR(100) DEFAULT 'PERU',

    -- Business Details
    industry VARCHAR(100),
    company_size company_size_enum,

    -- Credit Management
    credit_limit DECIMAL(12,2) DEFAULT 0,
    credit_days INT DEFAULT 0,
    current_balance DECIMAL(12,2) DEFAULT 0,

    -- Preferences
    preferred_currency_id INT NULL, -- References currencies(id)
    payment_terms VARCHAR(100),
    discount_percentage DECIMAL(5,2) DEFAULT 0,

    -- Status & Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE
    deleted_at TIMESTAMP NULL,

    -- Full-text search will be handled by a tsvector column and GIN index created in 03_indexes.sql

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (preferred_currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),

    CONSTRAINT unique_customers_document_per_tenant UNIQUE (tenant_id, document_type, document_number)
);

CREATE INDEX idx_customers_tenant_is_active ON customers(tenant_id, is_active);
CREATE INDEX idx_customers_customer_type ON customers(customer_type);
CREATE INDEX idx_customers_credit_management ON customers(tenant_id, credit_limit, current_balance);
-- CREATE INDEX idx_customers_name_fts ON customers USING GIN (to_tsvector('simple', coalesce(business_name, '') || ' ' || coalesce(first_name, '') || ' ' || coalesce(last_name, ''))); -- Example for FTS


-- =====================================================
-- SUPPLIERS MANAGEMENT
-- =====================================================

CREATE TABLE suppliers (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_code VARCHAR(50),

    -- Basic Info
    business_name VARCHAR(255) NOT NULL,
    document_type document_type_enum NOT NULL,
    document_number VARCHAR(20) NOT NULL,

    -- Contact Information
    contact_person VARCHAR(200),
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    website VARCHAR(255),

    -- Address
    address TEXT,
    district VARCHAR(100),
    province VARCHAR(100),
    department VARCHAR(100),
    country VARCHAR(100) DEFAULT 'PERU',

    -- Business Terms
    payment_terms VARCHAR(100),
    credit_days INT DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,

    -- Categories & Classification
    category VARCHAR(100),
    rating supplier_rating_enum DEFAULT 'C',

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),

    CONSTRAINT unique_suppliers_document_per_tenant UNIQUE (tenant_id, document_type, document_number)
);

CREATE INDEX idx_suppliers_tenant_is_active ON suppliers(tenant_id, is_active);


-- =====================================================
-- DOCUMENT SERIES MANAGEMENT
-- =====================================================

CREATE TABLE document_series (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    branch_id BIGINT NULL, -- References branches(id)
    document_type_id INT NOT NULL, -- References document_types(id)

    series_prefix VARCHAR(10) NOT NULL,
    current_number BIGINT DEFAULT 0,
    min_number BIGINT DEFAULT 1,
    max_number BIGINT DEFAULT 99999999,

    is_electronic BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,

    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (document_type_id) REFERENCES document_types(id),

    CONSTRAINT unique_doc_series_per_branch UNIQUE (tenant_id, branch_id, document_type_id, series_prefix)
);

CREATE INDEX idx_doc_series_tenant_is_active ON document_series(tenant_id, is_active);


-- =====================================================
-- SALES & INVOICING
-- =====================================================

CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    branch_id BIGINT NULL, -- References branches(id)

    -- Document Identification
    document_type_id INT NOT NULL, -- References document_types(id)
    series_id BIGINT NOT NULL, -- References document_series(id)
    document_number BIGINT NOT NULL,
    -- full_number: In MySQL, was: VARCHAR(20) GENERATED ALWAYS AS (CONCAT((SELECT series_prefix FROM document_series WHERE id = series_id), '-', LPAD(document_number, 8, '0'))) STORED
    -- For PostgreSQL, this will be handled by a trigger (BEFORE INSERT OR UPDATE) in 02_triggers.sql or application logic.
    full_number VARCHAR(30) NULL, -- Increased size slightly for safety, ensure trigger logic matches

    -- Reference Document (for credit/debit notes)
    reference_invoice_id BIGINT NULL, -- References invoices(id)
    reference_type invoice_reference_type_enum NULL,
    reference_reason TEXT,

    -- Customer Information
    customer_id BIGINT NULL, -- References customers(id)
    customer_document_type document_type_enum NOT NULL,
    customer_document_number VARCHAR(20) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_address TEXT,
    customer_email VARCHAR(255),

    -- Dates & Terms
    issue_date DATE NOT NULL,
    due_date DATE NULL,
    currency_id INT NOT NULL, -- References currencies(id)
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,

    -- Amounts Calculation
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_discounts DECIMAL(12,2) DEFAULT 0,
    total_tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,

    -- Additional Costs
    shipping_amount DECIMAL(12,2) DEFAULT 0,
    handling_amount DECIMAL(12,2) DEFAULT 0,
    insurance_amount DECIMAL(12,2) DEFAULT 0,

    -- Payment Information
    payment_method payment_method_enum DEFAULT 'CASH',
    payment_status payment_status_enum DEFAULT 'PENDING',
    paid_amount DECIMAL(12,2) DEFAULT 0,
    outstanding_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,

    -- SUNAT Integration
    sunat_status sunat_status_enum DEFAULT 'DRAFT',
    sunat_response_code VARCHAR(10),
    sunat_response_description TEXT,
    sunat_xml TEXT, -- Changed from LONGTEXT
    sunat_cdr_xml TEXT, -- Changed from LONGTEXT
    sunat_hash VARCHAR(255),
    sunat_sent_at TIMESTAMP NULL,

    -- Additional Information
    notes TEXT,
    internal_notes TEXT,
    terms_and_conditions TEXT,

    -- Status & Workflow
    status generic_status_enum DEFAULT 'DRAFT',
    approved_by BIGINT NULL, -- References users(id)
    approved_at TIMESTAMP NULL,

    -- Audit Trail
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE
    deleted_at TIMESTAMP NULL,

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (document_type_id) REFERENCES document_types(id),
    FOREIGN KEY (series_id) REFERENCES document_series(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (reference_invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id)
);

ALTER TABLE invoices ADD CONSTRAINT unique_invoices_document_number UNIQUE (tenant_id, series_id, document_number);

CREATE INDEX idx_invoices_tenant_date ON invoices(tenant_id, issue_date);
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX idx_invoices_sunat_status ON invoices(sunat_status);
CREATE INDEX idx_invoices_outstanding_amount ON invoices(tenant_id, outstanding_amount);
CREATE INDEX idx_invoices_full_number ON invoices(full_number); -- Index on the manually populated/triggered column

-- Original MySQL composite indexes for reference (will be created in 03_indexes.sql if confirmed useful):
-- CREATE INDEX idx_invoices_tenant_status_date ON invoices(tenant_id, status, issue_date);
-- CREATE INDEX idx_invoices_customer_date ON invoices(customer_id, issue_date DESC);
-- CREATE INDEX idx_invoices_payment_status_due ON invoices(payment_status, due_date);


CREATE TABLE invoice_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL, -- References invoices(id)
    product_id BIGINT NULL, -- References products(id)

    -- Product Information (denormalized for historical accuracy)
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT,
    unit_code VARCHAR(10) NOT NULL, -- Consider if this should reference sunat_units.sunat_code or be just text
    unit_name VARCHAR(50) NOT NULL, -- Consider if this should reference sunat_units.name or be just text

    -- Quantities
    quantity DECIMAL(12,3) NOT NULL,

    -- Pricing
    unit_price DECIMAL(12,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0, -- This could be a generated column: (unit_price * quantity * discount_percentage / 100)

    -- Tax Information
    tax_type_id INT NOT NULL, -- References sunat_tax_types(id)
    tax_rate DECIMAL(5,2) NOT NULL, -- Could be denormalized from sunat_tax_types or calculated
    tax_amount DECIMAL(12,2) NOT NULL, -- This could be a generated column

    -- Line Totals
    -- line_subtotal: (unit_price * quantity) - discount_amount
    -- line_total: line_subtotal + tax_amount
    -- These are good candidates for generated columns or view calculations.
    -- For simplicity in direct conversion, keeping them as regular columns for now.
    line_subtotal DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,

    -- Additional Information
    notes TEXT,
    sort_order INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id)
);

CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id);
CREATE INDEX idx_invoice_items_product_id ON invoice_items(product_id);


-- =====================================================
-- PURCHASE MANAGEMENT
-- =====================================================

CREATE TABLE purchase_orders (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    branch_id BIGINT NULL, -- References branches(id)

    -- Document Info
    purchase_number VARCHAR(50) NOT NULL,
    supplier_invoice_number VARCHAR(100),

    -- Supplier Information
    supplier_id BIGINT NULL, -- References suppliers(id)
    supplier_name VARCHAR(255) NOT NULL,
    supplier_document_type document_type_enum NOT NULL,
    supplier_document_number VARCHAR(20) NOT NULL,

    -- Dates & Terms
    order_date DATE NOT NULL,
    delivery_date DATE NULL,
    currency_id INT NOT NULL, -- References currencies(id)
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,

    -- Amounts
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_discounts DECIMAL(12,2) DEFAULT 0,
    total_tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,

    -- Payment
    payment_method payment_method_enum DEFAULT 'CASH',
    payment_status payment_status_enum DEFAULT 'PENDING',
    paid_amount DECIMAL(12,2) DEFAULT 0,

    -- Status
    status generic_status_enum DEFAULT 'DRAFT',

    -- Additional Info
    notes TEXT,
    terms_and_conditions TEXT,

    -- Audit
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),

    CONSTRAINT unique_purchase_orders_purchase_number UNIQUE (tenant_id, purchase_number)
);

CREATE INDEX idx_purchase_orders_tenant_date ON purchase_orders(tenant_id, order_date);
CREATE INDEX idx_purchase_orders_supplier_id ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_payment_status ON purchase_orders(payment_status);


CREATE TABLE purchase_order_items (
    id BIGSERIAL PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL, -- References purchase_orders(id)
    product_id BIGINT NULL, -- References products(id)

    -- Product Info
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    unit_code VARCHAR(10) NOT NULL, -- Consider if this should reference sunat_units.sunat_code

    -- Quantities
    quantity_ordered DECIMAL(12,3) NOT NULL,
    quantity_received DECIMAL(12,3) DEFAULT 0,

    -- Pricing
    unit_cost DECIMAL(12,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0, -- Candidate for generated column

    -- Tax
    tax_type_id INT NOT NULL, -- References sunat_tax_types(id)
    tax_rate DECIMAL(5,2) NOT NULL, -- Candidate for denormalization or calculation
    tax_amount DECIMAL(12,2) NOT NULL, -- Candidate for generated column

    -- Line Totals
    line_subtotal DECIMAL(12,2) NOT NULL, -- Candidate for generated column
    line_total DECIMAL(12,2) NOT NULL, -- Candidate for generated column

    -- Status
    status purchase_order_item_status_enum DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id)
);

CREATE INDEX idx_purchase_order_items_purchase_order_id ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_purchase_order_items_product_id ON purchase_order_items(product_id);


-- =====================================================
-- INVENTORY MANAGEMENT
-- =====================================================

CREATE TABLE warehouses (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    branch_id BIGINT NULL, -- References branches(id)
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    address TEXT,
    is_main_warehouse BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,

    CONSTRAINT unique_warehouses_code_per_tenant UNIQUE (tenant_id, code)
);

CREATE INDEX idx_warehouses_tenant_is_active ON warehouses(tenant_id, is_active);


CREATE TABLE stock_movements (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL, -- References warehouses(id)
    product_id BIGINT NOT NULL, -- References products(id)

    -- Movement Classification
    movement_type stock_movement_type_enum NOT NULL,
    movement_reason stock_movement_reason_enum NOT NULL,

    -- Reference Documents
    reference_type reference_type_enum NOT NULL,
    reference_id BIGINT NULL, -- Could reference invoices, purchase_orders, etc. No direct FK to keep it flexible.
    reference_number VARCHAR(100),

    -- Movement Details
    quantity DECIMAL(12,3) NOT NULL,
    unit_cost DECIMAL(12,2) DEFAULT 0, -- Consider if this should be captured or derived
    total_cost DECIMAL(12,2) DEFAULT 0, -- Candidate for generated column (quantity * unit_cost)

    -- Stock Levels (before this movement)
    previous_stock DECIMAL(12,3) NOT NULL,
    new_stock DECIMAL(12,3) NOT NULL, -- This would typically be previous_stock + (quantity if IN else -quantity)

    -- Additional Information
    notes TEXT,
    expiry_date DATE NULL,
    batch_number VARCHAR(100),

    -- Timestamps
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL, -- References users(id)

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_stock_movements_tenant_product_id ON stock_movements(tenant_id, product_id);
CREATE INDEX idx_stock_movements_warehouse_product_id ON stock_movements(warehouse_id, product_id);
CREATE INDEX idx_stock_movements_movement_date ON stock_movements(movement_date);
CREATE INDEX idx_stock_movements_reference ON stock_movements(reference_type, reference_id);
CREATE INDEX idx_stock_movements_movement_type_reason ON stock_movements(movement_type, movement_reason);


CREATE TABLE product_stock_by_warehouse (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL, -- References warehouses(id)
    product_id BIGINT NOT NULL, -- References products(id)

    current_stock DECIMAL(12,3) DEFAULT 0,
    reserved_stock DECIMAL(12,3) DEFAULT 0,
    available_stock DECIMAL(12,3) GENERATED ALWAYS AS (current_stock - reserved_stock) STORED,

    average_cost DECIMAL(12,2) DEFAULT 0, -- This would likely be updated by triggers/application logic
    last_cost DECIMAL(12,2) DEFAULT 0, -- This would likely be updated by triggers/application logic

    last_movement_date TIMESTAMP NULL, -- This would likely be updated by triggers/application logic
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,

    CONSTRAINT unique_prod_stock_prod_wh UNIQUE (tenant_id, warehouse_id, product_id)
);

CREATE INDEX idx_prod_stock_tenant_current_stock ON product_stock_by_warehouse(tenant_id, current_stock);
CREATE INDEX idx_prod_stock_tenant_available_stock ON product_stock_by_warehouse(tenant_id, available_stock); -- Index on generated column


-- =====================================================
-- FINANCIAL MANAGEMENT
-- =====================================================

CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(200) NOT NULL,
    account_type account_type_enum NOT NULL,
    account_subtype VARCHAR(100), -- E.g., 'CURRENT_ASSET', 'NON_CURRENT_ASSET', 'BANK', 'CASH'
    parent_account_id BIGINT NULL, -- References accounts(id) for hierarchical chart of accounts

    -- Configuration
    is_system_account BOOLEAN DEFAULT FALSE, -- For accounts that should not be deleted/modified by users
    is_bank_account BOOLEAN DEFAULT FALSE,
    bank_name VARCHAR(200),
    account_number VARCHAR(50),

    -- Balances (These might be calculated or snapshotted. For direct conversion, keeping as is)
    opening_balance DECIMAL(15,2) DEFAULT 0,
    current_balance DECIMAL(15,2) DEFAULT 0, -- Typically updated by transactions via triggers or application logic

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_account_id) REFERENCES accounts(id) ON DELETE SET NULL,

    CONSTRAINT unique_accounts_code_per_tenant UNIQUE (tenant_id, code)
);

CREATE INDEX idx_accounts_tenant_type ON accounts(tenant_id, account_type);
CREATE INDEX idx_accounts_parent_account_id ON accounts(parent_account_id);


CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,

    -- Transaction Details
    transaction_number VARCHAR(50) NOT NULL, -- E.g., JE-2023-0001
    transaction_date DATE NOT NULL,
    description TEXT NOT NULL,

    -- Reference (Polymorphic: could be INVOICE, PURCHASE, EXPENSE, PAYMENT, etc.)
    reference_type reference_type_enum NOT NULL,
    reference_id BIGINT NULL, -- The ID in the referenced table (e.g., invoices.id)
    reference_number VARCHAR(100), -- E.g., Invoice number INV-001, PO number

    -- Amount & Currency
    total_amount DECIMAL(12,2) NOT NULL, -- Overall transaction amount, for validation against entries sum
    currency_id INT NOT NULL, -- References currencies(id)
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,

    -- Status
    status generic_status_enum DEFAULT 'DRAFT', -- E.g., DRAFT, POSTED, CANCELLED
    posted_at TIMESTAMP NULL,
    posted_by BIGINT NULL, -- References users(id)

    -- Audit
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (posted_by) REFERENCES users(id),

    CONSTRAINT unique_transactions_transaction_number UNIQUE (tenant_id, transaction_number)
);

CREATE INDEX idx_transactions_tenant_date ON transactions(tenant_id, transaction_date);
CREATE INDEX idx_transactions_reference ON transactions(reference_type, reference_id);
CREATE INDEX idx_transactions_status ON transactions(status);


CREATE TABLE transaction_entries (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL, -- References transactions(id)
    account_id BIGINT NOT NULL, -- References accounts(id)

    -- Entry Details
    description VARCHAR(500), -- Can inherit from transaction description or be more specific
    debit_amount DECIMAL(12,2) DEFAULT 0,
    credit_amount DECIMAL(12,2) DEFAULT 0,

    -- Additional Info (for reporting/filtering)
    cost_center VARCHAR(100),
    project_code VARCHAR(100),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id)
    -- Consider adding a CHECK constraint: CHECK (debit_amount >= 0 AND credit_amount >= 0 AND debit_amount + credit_amount > 0 AND NOT (debit_amount > 0 AND credit_amount > 0))
    -- This ensures one is positive and the other is zero, and at least one has a value.
);

CREATE INDEX idx_transaction_entries_transaction_id ON transaction_entries(transaction_id);
CREATE INDEX idx_transaction_entries_account_id ON transaction_entries(account_id);
CREATE INDEX idx_transaction_entries_amounts ON transaction_entries(debit_amount, credit_amount);


-- =====================================================
-- EXPENSE MANAGEMENT
-- =====================================================

CREATE TABLE expense_categories (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    account_id BIGINT NULL, -- Optional link to a default expense account in the chart of accounts
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,

    CONSTRAINT unique_expense_categories_name_per_tenant UNIQUE (tenant_id, name)
);

CREATE INDEX idx_expense_categories_tenant_is_active ON expense_categories(tenant_id, is_active);


CREATE TABLE expenses (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    branch_id BIGINT NULL, -- References branches(id)

    -- Expense Details
    expense_number VARCHAR(50) NOT NULL,
    expense_date DATE NOT NULL,
    description TEXT NOT NULL,

    -- Categorization
    category_id BIGINT NULL, -- References expense_categories(id)
    account_id BIGINT NOT NULL, -- References accounts(id) (The specific expense account used)

    -- Supplier/Vendor (Optional)
    supplier_id BIGINT NULL, -- References suppliers(id)
    supplier_name VARCHAR(255), -- Denormalized if no supplier_id, or for quick reference
    supplier_document VARCHAR(20), -- Denormalized

    -- Invoice Information (from supplier)
    supplier_invoice_number VARCHAR(100),
    invoice_date DATE,

    -- Amounts
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL, -- Should be subtotal + tax_amount
    currency_id INT NOT NULL, -- References currencies(id)

    -- Payment
    payment_method payment_method_enum DEFAULT 'CASH',
    payment_status payment_status_enum DEFAULT 'PAID', -- Defaulting to PAID as per original schema for expenses

    -- Approval Workflow
    requires_approval BOOLEAN DEFAULT FALSE,
    approved_by BIGINT NULL, -- References users(id)
    approved_at TIMESTAMP NULL,

    -- Attachments
    receipt_url VARCHAR(500),
    attachments JSONB,

    -- Status
    status generic_status_enum DEFAULT 'DRAFT', -- E.g., DRAFT, PENDING_APPROVAL, APPROVED, PAID, CANCELLED

    -- Audit
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES expense_categories(id) ON DELETE SET NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id),

    CONSTRAINT unique_expenses_expense_number UNIQUE (tenant_id, expense_number)
    -- Consider CHECK (total_amount = subtotal + tax_amount)
);

CREATE INDEX idx_expenses_tenant_date ON expenses(tenant_id, expense_date);
CREATE INDEX idx_expenses_category_id ON expenses(category_id);
CREATE INDEX idx_expenses_supplier_id ON expenses(supplier_id);
CREATE INDEX idx_expenses_payment_status ON expenses(payment_status);


-- =====================================================
-- QUOTATIONS MANAGEMENT
-- =====================================================

CREATE TABLE quotations (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,

    -- Quote Details
    quote_number VARCHAR(50) NOT NULL,
    quote_date DATE NOT NULL,
    valid_until DATE NOT NULL,

    -- Customer Info
    customer_id BIGINT NULL, -- References customers(id)
    customer_name VARCHAR(255) NOT NULL, -- Denormalized for historical record if customer details change
    customer_email VARCHAR(255),
    customer_phone VARCHAR(20),

    -- Amounts
    subtotal DECIMAL(12,2) NOT NULL,
    total_discounts DECIMAL(12,2) DEFAULT 0,
    total_tax_amount DECIMAL(12,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL, -- Should be subtotal - total_discounts + total_tax_amount
    currency_id INT NOT NULL, -- References currencies(id)

    -- Terms
    payment_terms VARCHAR(500),
    delivery_terms VARCHAR(500),
    notes TEXT,

    -- Status & Conversion
    status generic_status_enum DEFAULT 'DRAFT', -- E.g., DRAFT, SENT, ACCEPTED, REJECTED, EXPIRED, CONVERTED
    converted_to_invoice_id BIGINT NULL, -- References invoices(id)

    -- Audit
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (converted_to_invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),

    CONSTRAINT unique_quotations_quote_number UNIQUE (tenant_id, quote_number)
    -- Consider CHECK (total_amount = subtotal - total_discounts + total_tax_amount)
);

CREATE INDEX idx_quotations_tenant_date ON quotations(tenant_id, quote_date);
CREATE INDEX idx_quotations_customer_id ON quotations(customer_id);
CREATE INDEX idx_quotations_status ON quotations(status);


CREATE TABLE quotation_items (
    id BIGSERIAL PRIMARY KEY,
    quotation_id BIGINT NOT NULL, -- References quotations(id)
    product_id BIGINT NULL, -- References products(id)

    -- Product Info (Denormalized for historical accuracy)
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT,
    unit_code VARCHAR(10) NOT NULL, -- Consider if this should reference sunat_units.sunat_code

    -- Quantities & Pricing
    quantity DECIMAL(12,3) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0, -- Candidate for generated column

    -- Tax
    tax_type_id INT NOT NULL, -- References sunat_tax_types(id)
    tax_rate DECIMAL(5,2) NOT NULL, -- Candidate for denormalization or calculation
    tax_amount DECIMAL(12,2) NOT NULL, -- Candidate for generated column

    -- Line Totals
    line_subtotal DECIMAL(12,2) NOT NULL, -- Candidate for generated column
    line_total DECIMAL(12,2) NOT NULL, -- Candidate for generated column

    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- No updated_at field in original schema that needs ON UPDATE trigger

    FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id)
);

CREATE INDEX idx_quotation_items_quotation_id ON quotation_items(quotation_id);
CREATE INDEX idx_quotation_items_product_id ON quotation_items(product_id);


-- =====================================================
-- CASH REGISTER MANAGEMENT (for Retail)
-- =====================================================

CREATE TABLE cash_registers (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    branch_id BIGINT NULL, -- References branches(id)
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50) NOT NULL, -- E.g., CR001, POS01
    location VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,

    CONSTRAINT unique_cash_registers_code_per_tenant UNIQUE (tenant_id, code)
);

CREATE INDEX idx_cash_registers_tenant_is_active ON cash_registers(tenant_id, is_active);


CREATE TABLE cash_register_sessions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cash_register_id BIGINT NOT NULL, -- References cash_registers(id)
    user_id BIGINT NOT NULL, -- References users(id) who opened the session

    -- Session Details
    session_number VARCHAR(50) NOT NULL, -- E.g., SESS-CR001-20231026-001
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,

    -- Opening Amounts
    opening_cash DECIMAL(12,2) DEFAULT 0,
    opening_notes TEXT,

    -- Closing Amounts
    closing_cash DECIMAL(12,2) DEFAULT 0, -- Actual cash counted at closing
    expected_cash DECIMAL(12,2) DEFAULT 0, -- Calculated: opening_cash + sales - refunds - expenses
    cash_difference DECIMAL(12,2) GENERATED ALWAYS AS (closing_cash - expected_cash) STORED,
    closing_notes TEXT,

    -- Session Totals (These would be calculated and stored at closing, possibly by a trigger or application logic)
    total_sales DECIMAL(12,2) DEFAULT 0,
    total_refunds DECIMAL(12,2) DEFAULT 0,
    total_expenses DECIMAL(12,2) DEFAULT 0,

    -- Status
    status cash_register_session_status_enum DEFAULT 'OPEN',
    closed_by BIGINT NULL, -- References users(id) who closed the session

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (cash_register_id) REFERENCES cash_registers(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (closed_by) REFERENCES users(id),

    CONSTRAINT unique_cash_reg_sessions_session_number UNIQUE (tenant_id, session_number)
);

CREATE INDEX idx_cash_reg_sessions_tenant_register ON cash_register_sessions(tenant_id, cash_register_id);
CREATE INDEX idx_cash_reg_sessions_status ON cash_register_sessions(status);
CREATE INDEX idx_cash_reg_sessions_opened_at ON cash_register_sessions(opened_at);


-- =====================================================
-- PAYMENT MANAGEMENT
-- =====================================================

CREATE TABLE payment_methods (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL, -- E.g., "Cash", "Visa Card", "Yape"
    code VARCHAR(20) NOT NULL, -- E.g., CASH, VISA, YAPE

    -- Configuration
    method_type payment_method_type_enum NOT NULL, -- E.g., CASH, BANK_TRANSFER, CARD, DIGITAL_WALLET
    requires_authorization BOOLEAN DEFAULT FALSE,
    has_fees BOOLEAN DEFAULT FALSE,
    fee_percentage DECIMAL(5,2) DEFAULT 0,
    fee_fixed_amount DECIMAL(12,2) DEFAULT 0,

    -- Account Mapping (Optional: links to a specific bank account in the chart of accounts)
    account_id BIGINT NULL, -- References accounts(id)

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- No updated_at that needs ON UPDATE trigger

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,

    CONSTRAINT unique_payment_methods_code_per_tenant UNIQUE (tenant_id, code)
);

CREATE INDEX idx_payment_methods_tenant_is_active ON payment_methods(tenant_id, is_active);


CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,

    -- Payment Details
    payment_number VARCHAR(50) NOT NULL, -- E.g., PAY-0001
    payment_date DATE NOT NULL,

    -- Reference (Polymorphic: INVOICE, PURCHASE, EXPENSE, ADVANCE, REFUND)
    reference_type reference_type_enum NOT NULL,
    reference_id BIGINT NOT NULL, -- ID of the invoice, purchase order, etc.

    -- Customer/Supplier (Polymorphic based on entity_type)
    entity_type payment_entity_type_enum NOT NULL,
    entity_id BIGINT NULL, -- customer_id or supplier_id. Could be NULL for advance payments not yet allocated.
    entity_name VARCHAR(255) NOT NULL, -- Denormalized for quick reference

    -- Payment Method & Amount
    payment_method_id BIGINT NOT NULL, -- References payment_methods(id)
    amount DECIMAL(12,2) NOT NULL,
    currency_id INT NOT NULL, -- References currencies(id)
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,

    -- Additional Details
    reference_number VARCHAR(100), -- Check number, transfer reference, authorization code, etc.
    authorization_code VARCHAR(100), -- Specifically for card transactions if needed
    notes TEXT,

    -- Status
    status generic_status_enum DEFAULT 'CONFIRMED', -- E.g., PENDING, CONFIRMED, CANCELLED

    -- Audit
    created_by BIGINT NOT NULL, -- References users(id)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Trigger will handle ON UPDATE

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    -- Note: No direct FK for entity_id due to its polymorphic nature. Application logic must ensure integrity.
    -- Or, use separate nullable FK columns for customer_id and supplier_id.

    CONSTRAINT unique_payments_payment_number UNIQUE (tenant_id, payment_number)
);

CREATE INDEX idx_payments_tenant_date ON payments(tenant_id, payment_date);
CREATE INDEX idx_payments_reference ON payments(reference_type, reference_id);
CREATE INDEX idx_payments_entity ON payments(entity_type, entity_id);
CREATE INDEX idx_payments_payment_method_id ON payments(payment_method_id);


-- =====================================================
-- AUDIT & ACTIVITY LOGS
-- =====================================================

CREATE TABLE activity_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NULL, -- User who performed the action. NULL if system action.

    -- Activity Details
    activity_type VARCHAR(50) NOT NULL, -- E.g., "USER_LOGIN", "INVOICE_CREATED", "PRODUCT_UPDATED"
    entity_type VARCHAR(50) NOT NULL, -- E.g., "USER", "INVOICE", "PRODUCT"
    entity_id BIGINT NULL, -- ID of the affected entity

    -- Changes
    action activity_log_action_enum NOT NULL, -- CREATE, UPDATE, DELETE, VIEW, EXPORT, IMPORT
    old_values JSONB NULL, -- Stores previous state of changed fields (for UPDATE)
    new_values JSONB NULL, -- Stores new state of changed fields (for CREATE, UPDATE)
    changes_summary TEXT, -- Human-readable summary of changes

    -- Context
    ip_address VARCHAR(45),
    user_agent TEXT,
    session_id VARCHAR(255), -- Link to user's session if applicable

    -- Additional Info
    metadata JSONB NULL, -- For any other relevant structured data

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- No updated_at field

    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    -- No FK for entity_id as it's polymorphic
);

CREATE INDEX idx_activity_logs_tenant_date ON activity_logs(tenant_id, created_at DESC);
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_user_activity ON activity_logs(user_id, activity_type);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);
