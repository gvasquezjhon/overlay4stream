# PostgreSQL Schema for SaaS Billing System

This directory contains the SQL scripts to set up the PostgreSQL database schema for the multi-tenant SaaS billing system.

## Execution Order

The scripts should be executed in the following order to ensure all dependencies are met (types created before tables, tables before triggers and indexes, etc.):

1.  **`00_types.sql`**: Defines all custom `ENUM` types used throughout the schema. This *must* be run first.
2.  **`01_tables.sql`**: Creates all table structures, including primary keys, basic constraints (NOT NULL, UNIQUE, CHECK), and foreign key relationships.
3.  **`02_triggers.sql`**: Defines trigger functions and applies triggers to tables. This includes:
    *   A generic trigger to automatically update `updated_at` (or `last_updated`) columns on row updates.
    *   A specific trigger to populate the `invoices.full_number` generated column.
4.  **`03_indexes.sql`**: Creates additional indexes, including:
    *   Full-Text Search (FTS) indexes for relevant tables (e.g., `products`, `customers`).
    *   Composite indexes for performance optimization based on common query patterns.
5.  **`04_initial_data.sql`**: Inserts essential seed data into lookup tables like `document_types`, `sunat_tax_types`, `sunat_units`, and `currencies`.

## Notes

*   Ensure you have the necessary privileges to create types, tables, triggers, and insert data in your PostgreSQL database.
*   It's recommended to run these scripts within a transaction if your PostgreSQL client supports it, to ensure atomicity, especially for `01_tables.sql`.
*   Review the scripts, particularly `03_indexes.sql`, to ensure the indexes align with your specific query patterns and performance needs. Some example or complex indexes might be commented out or may require adjustments.
*   The schema conversion from MySQL involved changes such as:
    *   `AUTO_INCREMENT` to `SERIAL` or `BIGSERIAL`.
    *   Removal of `UNSIGNED` integer types.
    *   MySQL `ENUM` definitions converted to PostgreSQL `CREATE TYPE ... AS ENUM`.
    *   `ON UPDATE CURRENT_TIMESTAMP` behavior implemented via triggers.
    *   `FULLTEXT` indexes converted to PostgreSQL's `tsvector` with `GIN` indexes.
    *   `JSON` types generally converted to `JSONB` for better performance.
    *   `LONGTEXT` converted to `TEXT`.
