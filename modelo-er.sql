-- =====================================================
-- ENHANCED MULTI-TENANT SAAS DATABASE SCHEMA
-- Sistema de Gestión Comercial con Facturación Electrónica
-- Autor: Sistema SaaS ERP
-- Fecha: Junio 2025
-- Versión: 1.0
-- =====================================================

-- =====================================================
-- CORE MULTI-TENANCY & BUSINESS SETUP
-- =====================================================

CREATE TABLE tenants (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    ruc VARCHAR(11) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    district VARCHAR(100),
    province VARCHAR(100),
    department VARCHAR(100),
    tax_regime ENUM('RUS', 'RER', 'GENERAL', 'MYPE') NOT NULL,
    business_type ENUM('GENERAL', 'RESTAURANT', 'RETAIL', 'SERVICE') DEFAULT 'GENERAL',
    
    -- SUNAT Integration
    sunat_environment ENUM('BETA', 'PRODUCTION') DEFAULT 'BETA',
    sunat_certificate_path VARCHAR(500),
    sunat_certificate_password VARCHAR(255),
    sunat_ruc_user VARCHAR(50),
    sunat_ruc_password VARCHAR(255),
    
    -- Subscription & Billing
    subscription_plan ENUM('NRUS', 'PROFESSIONAL', 'ENTERPRISE') DEFAULT 'NRUS',
    monthly_price DECIMAL(8,2) DEFAULT 69.00,
    trial_ends_at TIMESTAMP NULL,
    billing_cycle ENUM('MONTHLY', 'YEARLY') DEFAULT 'MONTHLY',
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_slug (slug),
    INDEX idx_ruc (ruc),
    INDEX idx_subscription (subscription_plan, is_active)
);

-- =====================================================
-- USER MANAGEMENT & PERMISSIONS
-- =====================================================

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dni VARCHAR(8),
    phone VARCHAR(20),
    
    -- Role & Permissions
    role ENUM('OWNER', 'ADMIN', 'ACCOUNTANT', 'SELLER', 'VIEWER') NOT NULL,
    permissions JSON, -- Granular permissions
    branch_access JSON, -- Array of branch IDs user can access
    
    -- Status & Activity
    is_active BOOLEAN DEFAULT TRUE,
    email_verified_at TIMESTAMP NULL,
    last_login_at TIMESTAMP NULL,
    password_reset_token VARCHAR(255),
    password_reset_expires_at TIMESTAMP NULL,
    
    -- Audit
    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_email_per_tenant (tenant_id, email),
    INDEX idx_tenant_role (tenant_id, role),
    INDEX idx_active_users (tenant_id, is_active)
);

-- =====================================================
-- BUSINESS CONFIGURATION
-- =====================================================

CREATE TABLE branches (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
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
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    INDEX idx_tenant_active (tenant_id, is_active)
);

CREATE TABLE tenant_settings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    category ENUM('GENERAL', 'INVOICING', 'INVENTORY', 'ACCOUNTING', 'NOTIFICATIONS') NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    data_type ENUM('STRING', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'JSON') DEFAULT 'STRING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    UNIQUE KEY unique_setting_per_tenant (tenant_id, category, setting_key),
    INDEX idx_tenant_category (tenant_id, category)
);

-- =====================================================
-- SUNAT CONFIGURATION TABLES
-- =====================================================

CREATE TABLE document_types (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sunat_code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    is_credit_note BOOLEAN DEFAULT FALSE,
    is_debit_note BOOLEAN DEFAULT FALSE,
    requires_reference BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE sunat_tax_types (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sunat_code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    rate DECIMAL(5,2) NOT NULL,
    is_percentage BOOLEAN DEFAULT TRUE,
    is_included_in_price BOOLEAN DEFAULT TRUE,
    is_gratuita BOOLEAN DEFAULT FALSE,
    applies_to ENUM('PRODUCTS', 'SERVICES', 'BOTH') DEFAULT 'BOTH',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE sunat_units (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sunat_code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    symbol VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE currencies (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    iso_code CHAR(3) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,
    is_base_currency BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- =====================================================
-- PRODUCT MANAGEMENT
-- =====================================================

CREATE TABLE product_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    parent_id BIGINT UNSIGNED NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES product_categories(id) ON DELETE SET NULL,
    INDEX idx_tenant_parent (tenant_id, parent_id),
    INDEX idx_sort_order (sort_order)
);

CREATE TABLE products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    code VARCHAR(50) NOT NULL,
    barcode VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Classification
    category_id BIGINT UNSIGNED NULL,
    product_type ENUM('PRODUCT', 'SERVICE', 'DIGITAL') DEFAULT 'PRODUCT',
    unit_id INT UNSIGNED NOT NULL,
    tax_type_id INT UNSIGNED NOT NULL,
    
    -- Pricing
    cost_price DECIMAL(12,2) DEFAULT 0,
    sale_price DECIMAL(12,2) NOT NULL,
    wholesale_price DECIMAL(12,2),
    currency_id INT UNSIGNED NOT NULL,
    price_includes_tax BOOLEAN DEFAULT TRUE,
    
    -- Inventory Management
    track_inventory BOOLEAN DEFAULT TRUE,
    initial_stock DECIMAL(12,3) DEFAULT 0,
    current_stock DECIMAL(12,3) DEFAULT 0,
    reserved_stock DECIMAL(12,3) DEFAULT 0,
    min_stock_alert DECIMAL(12,3) DEFAULT 0,
    max_stock DECIMAL(12,3),
    
    -- Costing Method
    costing_method ENUM('FIFO', 'LIFO', 'AVERAGE', 'SPECIFIC') DEFAULT 'AVERAGE',
    
    -- Media & Presentation
    primary_image_url VARCHAR(500),
    gallery_images JSON,
    
    -- SEO & Online
    slug VARCHAR(255),
    meta_title VARCHAR(255),
    meta_description TEXT,
    tags JSON,
    
    -- Status & Audit
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE SET NULL,
    FOREIGN KEY (unit_id) REFERENCES sunat_units(id),
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE KEY unique_code_per_tenant (tenant_id, code),
    UNIQUE KEY unique_barcode_per_tenant (tenant_id, barcode),
    INDEX idx_tenant_active (tenant_id, is_active),
    INDEX idx_category (category_id),
    INDEX idx_stock_alerts (tenant_id, track_inventory, current_stock, min_stock_alert),
    FULLTEXT(name, description)
);

-- =====================================================
-- CUSTOMER MANAGEMENT
-- =====================================================

CREATE TABLE customers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    customer_code VARCHAR(50),
    
    -- Personal/Business Info
    customer_type ENUM('INDIVIDUAL', 'BUSINESS') NOT NULL,
    document_type ENUM('RUC', 'DNI', 'PASSPORT', 'OTHER') NOT NULL,
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
    company_size ENUM('SMALL', 'MEDIUM', 'LARGE'),
    
    -- Credit Management
    credit_limit DECIMAL(12,2) DEFAULT 0,
    credit_days INT DEFAULT 0,
    current_balance DECIMAL(12,2) DEFAULT 0,
    
    -- Preferences
    preferred_currency_id INT UNSIGNED,
    payment_terms VARCHAR(100),
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Status & Audit
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (preferred_currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE KEY unique_document_per_tenant (tenant_id, document_type, document_number),
    INDEX idx_tenant_active (tenant_id, is_active),
    INDEX idx_customer_type (customer_type),
    INDEX idx_credit_management (tenant_id, credit_limit, current_balance),
    FULLTEXT(business_name, first_name, last_name)
);

-- =====================================================
-- SUPPLIERS MANAGEMENT
-- =====================================================

CREATE TABLE suppliers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    supplier_code VARCHAR(50),
    
    -- Basic Info
    business_name VARCHAR(255) NOT NULL,
    document_type ENUM('RUC', 'DNI', 'PASSPORT', 'OTHER') NOT NULL,
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
    rating ENUM('A', 'B', 'C', 'D') DEFAULT 'C',
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE KEY unique_document_per_tenant (tenant_id, document_type, document_number),
    INDEX idx_tenant_active (tenant_id, is_active)
);

-- =====================================================
-- DOCUMENT SERIES MANAGEMENT
-- =====================================================

CREATE TABLE document_series (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    document_type_id INT UNSIGNED NOT NULL,
    
    series_prefix VARCHAR(10) NOT NULL,
    current_number BIGINT UNSIGNED DEFAULT 0,
    min_number BIGINT UNSIGNED DEFAULT 1,
    max_number BIGINT UNSIGNED DEFAULT 99999999,
    
    is_electronic BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (document_type_id) REFERENCES document_types(id),
    
    UNIQUE KEY unique_series_per_branch (tenant_id, branch_id, document_type_id, series_prefix),
    INDEX idx_tenant_active (tenant_id, is_active)
);

-- =====================================================
-- SALES & INVOICING
-- =====================================================

CREATE TABLE invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    
    -- Document Identification
    document_type_id INT UNSIGNED NOT NULL,
    series_id BIGINT UNSIGNED NOT NULL,
    document_number BIGINT UNSIGNED NOT NULL,
    full_number VARCHAR(20) GENERATED ALWAYS AS (CONCAT(
        (SELECT series_prefix FROM document_series WHERE id = series_id), 
        '-', 
        LPAD(document_number, 8, '0')
    )) STORED,
    
    -- Reference Document (for credit/debit notes)
    reference_invoice_id BIGINT UNSIGNED NULL,
    reference_type ENUM('CREDIT_NOTE', 'DEBIT_NOTE', 'RECTIFICATION') NULL,
    reference_reason TEXT,
    
    -- Customer Information
    customer_id BIGINT UNSIGNED NULL,
    customer_document_type ENUM('RUC', 'DNI', 'PASSPORT', 'OTHER') NOT NULL,
    customer_document_number VARCHAR(20) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_address TEXT,
    customer_email VARCHAR(255),
    
    -- Dates & Terms
    issue_date DATE NOT NULL,
    due_date DATE NULL,
    currency_id INT UNSIGNED NOT NULL,
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
    payment_method ENUM('CASH', 'TRANSFER', 'CARD', 'CHECK', 'CREDIT', 'YAPE', 'PLIN', 'OTHER') DEFAULT 'CASH',
    payment_status ENUM('PENDING', 'PARTIAL', 'PAID', 'OVERDUE', 'CANCELLED') DEFAULT 'PENDING',
    paid_amount DECIMAL(12,2) DEFAULT 0,
    outstanding_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    
    -- SUNAT Integration
    sunat_status ENUM('DRAFT', 'SENT', 'ACCEPTED', 'REJECTED', 'CANCELLED', 'ERROR') DEFAULT 'DRAFT',
    sunat_response_code VARCHAR(10),
    sunat_response_description TEXT,
    sunat_xml LONGTEXT,
    sunat_cdr_xml LONGTEXT,
    sunat_hash VARCHAR(255),
    sunat_sent_at TIMESTAMP NULL,
    
    -- Additional Information
    notes TEXT,
    internal_notes TEXT,
    terms_and_conditions TEXT,
    
    -- Status & Workflow
    status ENUM('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'SENT', 'CANCELLED', 'VOIDED') DEFAULT 'DRAFT',
    approved_by BIGINT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    
    -- Audit Trail
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (document_type_id) REFERENCES document_types(id),
    FOREIGN KEY (series_id) REFERENCES document_series(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (reference_invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id),
    
    UNIQUE KEY unique_document_number (tenant_id, series_id, document_number),
    INDEX idx_tenant_date (tenant_id, issue_date),
    INDEX idx_customer (customer_id),
    INDEX idx_payment_status (payment_status),
    INDEX idx_sunat_status (sunat_status),
    INDEX idx_outstanding (tenant_id, outstanding_amount),
    INDEX idx_full_number (full_number)
);

CREATE TABLE invoice_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NULL,
    
    -- Product Information (denormalized for historical accuracy)
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT,
    unit_code VARCHAR(10) NOT NULL,
    unit_name VARCHAR(50) NOT NULL,
    
    -- Quantities
    quantity DECIMAL(12,3) NOT NULL,
    
    -- Pricing
    unit_price DECIMAL(12,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Tax Information
    tax_type_id INT UNSIGNED NOT NULL,
    tax_rate DECIMAL(5,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL,
    
    -- Line Totals
    line_subtotal DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    
    -- Additional Information
    notes TEXT,
    sort_order INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id),
    
    INDEX idx_invoice (invoice_id),
    INDEX idx_product (product_id)
);

-- =====================================================
-- PURCHASE MANAGEMENT
-- =====================================================

CREATE TABLE purchase_orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    
    -- Document Info
    purchase_number VARCHAR(50) NOT NULL,
    supplier_invoice_number VARCHAR(100),
    
    -- Supplier Information
    supplier_id BIGINT UNSIGNED NULL,
    supplier_name VARCHAR(255) NOT NULL,
    supplier_document_type ENUM('RUC', 'DNI', 'OTHER') NOT NULL,
    supplier_document_number VARCHAR(20) NOT NULL,
    
    -- Dates & Terms
    order_date DATE NOT NULL,
    delivery_date DATE NULL,
    currency_id INT UNSIGNED NOT NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,
    
    -- Amounts
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_discounts DECIMAL(12,2) DEFAULT 0,
    total_tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    
    -- Payment
    payment_method ENUM('CASH', 'TRANSFER', 'CARD', 'CHECK', 'CREDIT', 'OTHER') DEFAULT 'CASH',
    payment_status ENUM('PENDING', 'PARTIAL', 'PAID', 'OVERDUE') DEFAULT 'PENDING',
    paid_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Status
    status ENUM('DRAFT', 'SENT', 'CONFIRMED', 'RECEIVED', 'CANCELLED') DEFAULT 'DRAFT',
    
    -- Additional Info
    notes TEXT,
    terms_and_conditions TEXT,
    
    -- Audit
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE KEY unique_purchase_number (tenant_id, purchase_number),
    INDEX idx_tenant_date (tenant_id, order_date),
    INDEX idx_supplier (supplier_id),
    INDEX idx_payment_status (payment_status)
);

CREATE TABLE purchase_order_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NULL,
    
    -- Product Info
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    unit_code VARCHAR(10) NOT NULL,
    
    -- Quantities
    quantity_ordered DECIMAL(12,3) NOT NULL,
    quantity_received DECIMAL(12,3) DEFAULT 0,
    
    -- Pricing
    unit_cost DECIMAL(12,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Tax
    tax_type_id INT UNSIGNED NOT NULL,
    tax_rate DECIMAL(5,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL,
    
    -- Line Totals
    line_subtotal DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    
    -- Status
    status ENUM('PENDING', 'PARTIAL', 'RECEIVED', 'CANCELLED') DEFAULT 'PENDING',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id),
    
    INDEX idx_purchase_order (purchase_order_id),
    INDEX idx_product (product_id)
);

-- =====================================================
-- INVENTORY MANAGEMENT
-- =====================================================

CREATE TABLE warehouses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    address TEXT,
    is_main_warehouse BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_code_per_tenant (tenant_id, code),
    INDEX idx_tenant_active (tenant_id, is_active)
);

CREATE TABLE stock_movements (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    
    -- Movement Classification
    movement_type ENUM('IN', 'OUT', 'TRANSFER', 'ADJUSTMENT') NOT NULL,
    movement_reason ENUM(
        'SALE', 'PURCHASE', 'RETURN', 'ADJUSTMENT', 
        'TRANSFER', 'INITIAL_STOCK', 'DAMAGED', 
        'EXPIRED', 'PROMOTION', 'SAMPLE'
    ) NOT NULL,
    
    -- Reference Documents
    reference_type ENUM('INVOICE', 'PURCHASE', 'TRANSFER', 'ADJUSTMENT', 'MANUAL') NOT NULL,
    reference_id BIGINT UNSIGNED NULL,
    reference_number VARCHAR(100),
    
    -- Movement Details
    quantity DECIMAL(12,3) NOT NULL,
    unit_cost DECIMAL(12,2) DEFAULT 0,
    total_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Stock Levels
    previous_stock DECIMAL(12,3) NOT NULL,
    new_stock DECIMAL(12,3) NOT NULL,
    
    -- Additional Information
    notes TEXT,
    expiry_date DATE NULL,
    batch_number VARCHAR(100),
    
    -- Timestamps
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NOT NULL,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    INDEX idx_tenant_product (tenant_id, product_id),
    INDEX idx_warehouse_product (warehouse_id, product_id),
    INDEX idx_movement_date (movement_date),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_movement_type (movement_type, movement_reason)
);

CREATE TABLE product_stock_by_warehouse (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    
    current_stock DECIMAL(12,3) DEFAULT 0,
    reserved_stock DECIMAL(12,3) DEFAULT 0,
    available_stock DECIMAL(12,3) GENERATED ALWAYS AS (current_stock - reserved_stock) STORED,
    
    average_cost DECIMAL(12,2) DEFAULT 0,
    last_cost DECIMAL(12,2) DEFAULT 0,
    
    last_movement_date TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_product_warehouse (tenant_id, warehouse_id, product_id),
    INDEX idx_stock_levels (tenant_id, current_stock),
    INDEX idx_low_stock (tenant_id, available_stock)
);

-- =====================================================
-- FINANCIAL MANAGEMENT
-- =====================================================

CREATE TABLE accounts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(200) NOT NULL,
    account_type ENUM('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE') NOT NULL,
    account_subtype VARCHAR(100),
    parent_account_id BIGINT UNSIGNED NULL,
    
    -- Configuration
    is_system_account BOOLEAN DEFAULT FALSE,
    is_bank_account BOOLEAN DEFAULT FALSE,
    bank_name VARCHAR(200),
    account_number VARCHAR(50),
    
    -- Balances
    opening_balance DECIMAL(15,2) DEFAULT 0,
    current_balance DECIMAL(15,2) DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_account_id) REFERENCES accounts(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_code_per_tenant (tenant_id, code),
    INDEX idx_tenant_type (tenant_id, account_type),
    INDEX idx_parent_account (parent_account_id)
);

CREATE TABLE transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    
    -- Transaction Details
    transaction_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    description TEXT NOT NULL,
    
    -- Reference
    reference_type ENUM('INVOICE', 'PURCHASE', 'EXPENSE', 'PAYMENT', 'TRANSFER', 'ADJUSTMENT', 'MANUAL') NOT NULL,
    reference_id BIGINT UNSIGNED NULL,
    reference_number VARCHAR(100),
    
    -- Amount & Currency
    total_amount DECIMAL(12,2) NOT NULL,
    currency_id INT UNSIGNED NOT NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,
    
    -- Status
    status ENUM('DRAFT', 'POSTED', 'CANCELLED') DEFAULT 'DRAFT',
    posted_at TIMESTAMP NULL,
    posted_by BIGINT UNSIGNED NULL,
    
    -- Audit
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (posted_by) REFERENCES users(id),
    
    UNIQUE KEY unique_transaction_number (tenant_id, transaction_number),
    INDEX idx_tenant_date (tenant_id, transaction_date),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_status (status)
);

CREATE TABLE transaction_entries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_id BIGINT UNSIGNED NOT NULL,
    account_id BIGINT UNSIGNED NOT NULL,
    
    -- Entry Details
    description VARCHAR(500),
    debit_amount DECIMAL(12,2) DEFAULT 0,
    credit_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Additional Info
    cost_center VARCHAR(100),
    project_code VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    
    INDEX idx_transaction (transaction_id),
    INDEX idx_account (account_id),
    INDEX idx_amounts (debit_amount, credit_amount)
);

-- =====================================================
-- EXPENSE MANAGEMENT
-- =====================================================

CREATE TABLE expense_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    account_id BIGINT UNSIGNED NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_name_per_tenant (tenant_id, name),
    INDEX idx_tenant_active (tenant_id, is_active)
);

CREATE TABLE expenses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    
    -- Expense Details
    expense_number VARCHAR(50) NOT NULL,
    expense_date DATE NOT NULL,
    description TEXT NOT NULL,
    
    -- Categorization
    category_id BIGINT UNSIGNED NULL,
    account_id BIGINT UNSIGNED NOT NULL,
    
    -- Supplier/Vendor
    supplier_id BIGINT UNSIGNED NULL,
    supplier_name VARCHAR(255),
    supplier_document VARCHAR(20),
    
    -- Invoice Information
    supplier_invoice_number VARCHAR(100),
    invoice_date DATE,
    
    -- Amounts
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    currency_id INT UNSIGNED NOT NULL,
    
    -- Payment
    payment_method ENUM('CASH', 'TRANSFER', 'CARD', 'CHECK', 'OTHER') DEFAULT 'CASH',
    payment_status ENUM('PENDING', 'PAID') DEFAULT 'PAID',
    
    -- Approval Workflow
    requires_approval BOOLEAN DEFAULT FALSE,
    approved_by BIGINT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    
    -- Attachments
    receipt_url VARCHAR(500),
    attachments JSON,
    
    -- Status
    status ENUM('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'PAID', 'CANCELLED') DEFAULT 'DRAFT',
    
    -- Audit
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES expense_categories(id) ON DELETE SET NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id),
    
    UNIQUE KEY unique_expense_number (tenant_id, expense_number),
    INDEX idx_tenant_date (tenant_id, expense_date),
    INDEX idx_category (category_id),
    INDEX idx_supplier (supplier_id),
    INDEX idx_payment_status (payment_status)
);

-- =====================================================
-- QUOTATIONS MANAGEMENT
-- =====================================================

CREATE TABLE quotations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    
    -- Quote Details
    quote_number VARCHAR(50) NOT NULL,
    quote_date DATE NOT NULL,
    valid_until DATE NOT NULL,
    
    -- Customer Info
    customer_id BIGINT UNSIGNED NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(20),
    
    -- Amounts
    subtotal DECIMAL(12,2) NOT NULL,
    total_discounts DECIMAL(12,2) DEFAULT 0,
    total_tax_amount DECIMAL(12,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    currency_id INT UNSIGNED NOT NULL,
    
    -- Terms
    payment_terms VARCHAR(500),
    delivery_terms VARCHAR(500),
    notes TEXT,
    
    -- Status & Conversion
    status ENUM('DRAFT', 'SENT', 'ACCEPTED', 'REJECTED', 'EXPIRED', 'CONVERTED') DEFAULT 'DRAFT',
    converted_to_invoice_id BIGINT UNSIGNED NULL,
    
    -- Audit
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (converted_to_invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE KEY unique_quote_number (tenant_id, quote_number),
    INDEX idx_tenant_date (tenant_id, quote_date),
    INDEX idx_customer (customer_id),
    INDEX idx_status (status)
);

CREATE TABLE quotation_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    quotation_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NULL,
    
    -- Product Info
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT,
    unit_code VARCHAR(10) NOT NULL,
    
    -- Quantities & Pricing
    quantity DECIMAL(12,3) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Tax
    tax_type_id INT UNSIGNED NOT NULL,
    tax_rate DECIMAL(5,2) NOT NULL,
    tax_amount DECIMAL(12,2) NOT NULL,
    
    -- Line Totals
    line_subtotal DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY (tax_type_id) REFERENCES sunat_tax_types(id),
    
    INDEX idx_quotation (quotation_id),
    INDEX idx_product (product_id)
);

-- =====================================================
-- CASH REGISTER MANAGEMENT (for Retail)
-- =====================================================

CREATE TABLE cash_registers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED NULL,
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50) NOT NULL,
    location VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_code_per_tenant (tenant_id, code),
    INDEX idx_tenant_active (tenant_id, is_active)
);

CREATE TABLE cash_register_sessions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    cash_register_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    
    -- Session Details
    session_number VARCHAR(50) NOT NULL,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    
    -- Opening Amounts
    opening_cash DECIMAL(12,2) DEFAULT 0,
    opening_notes TEXT,
    
    -- Closing Amounts
    closing_cash DECIMAL(12,2) DEFAULT 0,
    expected_cash DECIMAL(12,2) DEFAULT 0,
    cash_difference DECIMAL(12,2) GENERATED ALWAYS AS (closing_cash - expected_cash) STORED,
    closing_notes TEXT,
    
    -- Session Totals
    total_sales DECIMAL(12,2) DEFAULT 0,
    total_refunds DECIMAL(12,2) DEFAULT 0,
    total_expenses DECIMAL(12,2) DEFAULT 0,
    
    -- Status
    status ENUM('OPEN', 'CLOSED') DEFAULT 'OPEN',
    closed_by BIGINT UNSIGNED NULL,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (cash_register_id) REFERENCES cash_registers(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (closed_by) REFERENCES users(id),
    
    UNIQUE KEY unique_session_number (tenant_id, session_number),
    INDEX idx_tenant_register (tenant_id, cash_register_id),
    INDEX idx_status (status),
    INDEX idx_opened_at (opened_at)
);

-- =====================================================
-- PAYMENT MANAGEMENT
-- =====================================================

CREATE TABLE payment_methods (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL,
    
    -- Configuration
    method_type ENUM('CASH', 'BANK_TRANSFER', 'CARD', 'DIGITAL_WALLET', 'CHECK', 'CREDIT', 'OTHER') NOT NULL,
    requires_authorization BOOLEAN DEFAULT FALSE,
    has_fees BOOLEAN DEFAULT FALSE,
    fee_percentage DECIMAL(5,2) DEFAULT 0,
    fee_fixed_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Account Mapping
    account_id BIGINT UNSIGNED NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_code_per_tenant (tenant_id, code),
    INDEX idx_tenant_active (tenant_id, is_active)
);

CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    
    -- Payment Details
    payment_number VARCHAR(50) NOT NULL,
    payment_date DATE NOT NULL,
    
    -- Reference
    reference_type ENUM('INVOICE', 'PURCHASE', 'EXPENSE', 'ADVANCE', 'REFUND') NOT NULL,
    reference_id BIGINT UNSIGNED NOT NULL,
    
    -- Customer/Supplier
    entity_type ENUM('CUSTOMER', 'SUPPLIER') NOT NULL,
    entity_id BIGINT UNSIGNED NULL,
    entity_name VARCHAR(255) NOT NULL,
    
    -- Payment Method & Amount
    payment_method_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency_id INT UNSIGNED NOT NULL,
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,
    
    -- Additional Details
    reference_number VARCHAR(100), -- Check number, transfer reference, etc.
    authorization_code VARCHAR(100),
    notes TEXT,
    
    -- Status
    status ENUM('PENDING', 'CONFIRMED', 'CANCELLED') DEFAULT 'CONFIRMED',
    
    -- Audit
    created_by BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    UNIQUE KEY unique_payment_number (tenant_id, payment_number),
    INDEX idx_tenant_date (tenant_id, payment_date),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_payment_method (payment_method_id)
);

-- =====================================================
-- REPORTS & ANALYTICS
-- =====================================================

CREATE TABLE report_templates (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NULL, -- NULL for system templates
    name VARCHAR(200) NOT NULL,
    description TEXT,
    report_type VARCHAR(100) NOT NULL,
    
    -- Configuration
    template_config JSON,
    sql_query TEXT,
    
    -- Permissions
    is_system_template BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT FALSE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    
    INDEX idx_tenant_type (tenant_id, report_type),
    INDEX idx_system_templates (is_system_template, is_active)
);

-- =====================================================
-- AUDIT & ACTIVITY LOGS
-- =====================================================

CREATE TABLE activity_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    
    -- Activity Details
    activity_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT UNSIGNED NULL,
    
    -- Changes
    action ENUM('CREATE', 'UPDATE', 'DELETE', 'VIEW', 'EXPORT', 'IMPORT') NOT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    changes_summary TEXT,
    
    -- Context
    ip_address VARCHAR(45),
    user_agent TEXT,
    session_id VARCHAR(255),
    
    -- Additional Info
    metadata JSON,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_tenant_date (tenant_id, created_at),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_user_activity (user_id, activity_type),
    INDEX idx_action (action)
);

-- =====================================================
-- SUNAT INTEGRATION LOGS
-- =====================================================

CREATE TABLE sunat_integration_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT UNSIGNED NOT NULL,
    invoice_id BIGINT UNSIGNED NULL,
    
    -- Request Details
    operation_type ENUM('SEND_DOCUMENT', 'GET_STATUS', 'GET_CDR', 'VOID_DOCUMENT', 'SUMMARY') NOT NULL,
    endpoint_url VARCHAR(500),
    request_method VARCHAR(10),
    request_headers JSON,
    request_body LONGTEXT,
    
    -- Response Details
    response_status_code INT,
    response_headers JSON,
    response_body LONGTEXT,
    
    -- SUNAT Specific
    sunat_ticket VARCHAR(100),
    sunat_response_code VARCHAR(10),
    sunat_response_description TEXT,
    
    -- Performance & Error Tracking
    duration_ms INT UNSIGNED,
    is_successful BOOLEAN NOT NULL,
    error_message TEXT,
    retry_count INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    
    INDEX idx_tenant_date (tenant_id, created_at),
    INDEX idx_invoice (invoice_id),
    INDEX idx_operation (operation_type),
    INDEX idx_success (is_successful),
    INDEX idx_sunat_ticket (sunat_ticket)
);

-- =====================================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- =====================================================

-- Composite indexes for common queries
CREATE INDEX idx_invoices_tenant_status_date ON invoices(tenant_id, status, issue_date);
CREATE INDEX idx_invoices_customer_date ON invoices(customer_id, issue_date DESC);
CREATE INDEX idx_invoices_payment_status_due ON invoices(payment_status, due_date);

CREATE INDEX idx_products_tenant_category_active ON products(tenant_id, category_id, is_active);
CREATE INDEX idx_products_tenant_stock_tracking ON products(tenant_id, track_inventory, current_stock);

CREATE INDEX idx_stock_movements_product_date ON stock_movements(product_id, movement_date DESC);
CREATE INDEX idx_stock_movements_warehouse_type ON stock_movements(warehouse_id, movement_type, movement_date);

CREATE INDEX idx_transactions_tenant_type_date ON transactions(tenant_id, reference_type, transaction_date);
CREATE INDEX idx_expenses_tenant_category_date ON expenses(tenant_id, category_id, expense_date);

-- =====================================================
-- INITIAL DATA SETUP
-- =====================================================

-- Insert default document types
INSERT INTO document_types (sunat_code, name, description, is_active) VALUES
('01', 'Factura', 'Factura electrónica', TRUE),
('03', 'Boleta de Venta', 'Boleta de venta electrónica', TRUE),
('07', 'Nota de Crédito', 'Nota de crédito electrónica', TRUE),
('08', 'Nota de Débito', 'Nota de débito electrónica', TRUE),
('09', 'Guía de Remisión', 'Guía de remisión electrónica', TRUE),
('20', 'Comprobante de Retención', 'Comprobante de retención', TRUE),
('40', 'Comprobante de Percepción', 'Comprobante de percepción', TRUE);

-- Insert SUNAT tax types
INSERT INTO sunat_tax_types (sunat_code, name, rate, is_gratuita, is_active) VALUES
('1000', 'IGV', 18.00, FALSE, TRUE),
('9997', 'Exonerado', 0.00, FALSE, TRUE),
('9998', 'Inafecto', 0.00, FALSE, TRUE),
('9996', 'Gratuita', 0.00, TRUE, TRUE),
('9995', 'Exportación', 0.00, FALSE, TRUE);

-- Insert common SUNAT units
INSERT INTO sunat_units (sunat_code, name, symbol, is_active) VALUES
('NIU', 'UNIDAD', 'UND', TRUE),
('KGM', 'KILOGRAMO', 'KG', TRUE),
('GRM', 'GRAMO', 'GR', TRUE),
('LTR', 'LITRO', 'L', TRUE),
('MTR', 'METRO', 'M', TRUE),
('MTK', 'METRO CUADRADO', 'M²', TRUE),
('ZZ', 'SERVICIO', 'SERV', TRUE),
('DZN', 'DOCENA', 'DOC', TRUE),
('PA', 'PAQUETE', 'PAQ', TRUE),
('BG', 'BOLSA', 'BOL', TRUE);

-- Insert default currencies
INSERT INTO currencies (iso_code, name, symbol, is_base_currency, is_active) VALUES
('PEN', 'Sol Peruano', 'S/', TRUE, TRUE),
('USD', 'Dólar Americano', '$', FALSE, TRUE),
('EUR', 'Euro', '€', FALSE, TRUE);
