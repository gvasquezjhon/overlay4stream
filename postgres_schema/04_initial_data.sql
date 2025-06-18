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
-- Note: The 'applies_to' ENUM column is not included in this sample data from the original script.
-- If it were, its values would need to match the 'sunat_tax_applies_to_enum' type.
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
-- The 'last_updated' column will be set by its DEFAULT CURRENT_TIMESTAMP or trigger.
INSERT INTO currencies (iso_code, name, symbol, is_base_currency, is_active) VALUES
('PEN', 'Sol Peruano', 'S/', TRUE, TRUE),
('USD', 'Dólar Americano', '$', FALSE, TRUE),
('EUR', 'Euro', '€', FALSE, TRUE);
