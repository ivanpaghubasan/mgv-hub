-- Drop tables in reverse order of dependencies to avoid foreign key errors
-- Or use DROP TABLE IF EXISTS table_name CASCADE; (use CASCADE with extreme caution!)
DROP TABLE IF EXISTS payment_receipts;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS property_fees;
DROP TABLE IF EXISTS news;
DROP TABLE IF EXISTS EXISTS announcements;
DROP TABLE IF EXISTS admin_requests;
DROP TABLE IF EXISTS property_occupants;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS fee_types;
DROP TABLE IF EXISTS contacts;
DROP TABLE IF EXISTS contact_types;
DROP TABLE IF EXISTS roles;

-- 1. Roles Table (No Change)
-- Defines user roles within the system.
CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL -- e.g., 'Admin', 'Homeowner', 'Tenant'
);

-- Initial Roles Data (Seed this)
INSERT INTO roles (name) VALUES
('Admin'),
('Homeowner'),
('Tenant');


-- 2. Accounts Table (NEW: For Login Credentials & Roles)
-- Central table for all individuals who can log into the system.
CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES roles(id), -- Links to the role of the account
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Store bcrypt hash of the password
    password_change_required BOOLEAN DEFAULT FALSE NOT NULL, -- NEW: Flag for forced password change
    is_active BOOLEAN DEFAULT TRUE NOT NULL, -- For deactivating accounts
    last_login_at TIMESTAMPTZ, -- Optional: Track last login
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Assuming 'Admin' role_id is 1
INSERT INTO accounts (role_id, email, password_hash, password_change_required, is_active)
VALUES (1, 'admin@mgv.com', '$2y$10$Z8yS9f/iuA/xL5bKrYkace79kFv.IDUFFXDZRCrTCl4WnnqrW4uaO', TRUE, TRUE);
-- password changeMe123

-- Index for faster email lookups during login
CREATE INDEX idx_accounts_email ON accounts (email);


-- 3. User Profiles Table (NEW: For Personal Details)
-- Stores personal details for each account. One-to-one relationship with 'accounts'.
CREATE TABLE user_profiles (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT UNIQUE NOT NULL REFERENCES accounts(id), -- Links to the associated account
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    address_line1 VARCHAR(255), -- Could be the mailing address, not necessarily property
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    zip_code VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- 4. Properties Table (No Change)
-- Details about each property in the subdivision.
CREATE TABLE properties (
    id BIGSERIAL PRIMARY KEY,
    property_number VARCHAR(50) UNIQUE NOT NULL, -- e.g., "Lot 10 Block 5", "Unit 20A"
    address VARCHAR(255) UNIQUE NOT NULL, -- Full street address within the subdivision
    size_sqm DECIMAL(10, 2), -- Size in square meters
    property_type VARCHAR(50), -- e.g., 'Residential', 'Commercial', 'Vacant Lot'
    status VARCHAR(50) DEFAULT 'Occupied' NOT NULL, -- e.g., 'Occupied', 'Vacant', 'Under Construction'
    description TEXT,
    created_at TIMESTamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTamptz DEFAULT CURRENT_TIMESTAMP
);


-- 5. Property Occupants Table (UPDATED: References user_profiles.id)
-- Links users (homeowners or tenants) to properties, capturing their relationship and validity period.
CREATE TABLE property_occupants (
    id BIGSERIAL PRIMARY KEY,
    user_profile_id BIGINT NOT NULL REFERENCES user_profiles(id), -- UPDATED: References the profile, not the account
    property_id BIGINT NOT NULL REFERENCES properties(id),
    occupant_type VARCHAR(50) NOT NULL, -- 'Owner', 'Tenant'
    start_date DATE NOT NULL,
    end_date DATE, -- NULL if current occupant
    is_primary_owner BOOLEAN DEFAULT FALSE, -- For properties with multiple owners
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_profile_id, property_id, occupant_type, start_date) -- Prevents duplicate active relationships
);

-- Index for faster lookups by user profile and property
CREATE INDEX idx_property_occupants_user_profile_property ON property_occupants (user_profile_id, property_id);


-- 6. Fee Types Table (No Change)
CREATE TABLE fee_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    default_amount DECIMAL(10, 2) NOT NULL,
    recurrence_type VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Initial Fee Types Data (Seed this)
-- INSERT INTO fee_types (name, default_amount, recurrence_type) VALUES
-- ('Monthly Dues', 500.00, 'Monthly'),
-- ('Special Assessment', 1000.00, 'One-Time');


-- 7. Property Fees (Actual Due Amounts) (No Change)
CREATE TABLE property_fees (
    id BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(id),
    fee_type_id BIGINT NOT NULL REFERENCES fee_types(id),
    billed_amount DECIMAL(10, 2) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'Outstanding' NOT NULL,
    billing_period_start DATE,
    billing_period_end DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (property_id, fee_type_id, due_date)
);

-- 8. Payments Table (UPDATED: References accounts.id)
-- Records actual payments made by homeowners.
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id), -- UPDATED: References the account who made the payment
    property_fee_id BIGINT REFERENCES property_fees(id), -- The specific fee being paid (can be NULL for overpayment/credit)
    amount_paid DECIMAL(10, 2) NOT NULL,
    payment_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL, -- 'GCash', 'Bank Transfer', 'Cash', 'Credit Card'
    transaction_id VARCHAR(255) UNIQUE, -- Transaction ID from payment gateway (e.g., GCash, PayMongo)
    status VARCHAR(50) NOT NULL, -- 'Pending', 'Completed', 'Failed', 'Refunded'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups by account and date
CREATE INDEX idx_payments_account_date ON payments (account_id, payment_date);


-- 9. Payment Receipts Table (No Change)
CREATE TABLE payment_receipts (
    id BIGSERIAL PRIMARY KEY,
    payment_id BIGINT UNIQUE NOT NULL REFERENCES payments(id),
    receipt_number VARCHAR(100) UNIQUE,
    receipt_url TEXT,
    receipt_data JSONB,
    generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- 10. News Table (UPDATED: References accounts.id for admin_id)
CREATE TABLE news (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL REFERENCES accounts(id), -- UPDATED: Admin account who posted the news
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    published_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 11. Announcements Table (UPDATED: References accounts.id for admin_id)
CREATE TABLE announcements (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL REFERENCES accounts(id), -- UPDATED: Admin account who posted the announcement
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    published_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- 12. Contact Types Table (No Change)
CREATE TABLE contact_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Initial Contact Types Data (Seed this)
-- INSERT INTO contact_types (name) VALUES
-- ('HOA Office'),
-- ('Emergency Services'),
-- ('Security');


-- 13. Contacts Table (No Change)
CREATE TABLE contacts (
    id BIGSERIAL PRIMARY KEY,
    contact_type_id BIGINT NOT NULL REFERENCES contact_types(id),
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- 14. Admin Requests Table (UPDATED: References accounts.id for user_id and reviewed_by_admin_id)
-- Manages requests from homeowners to modify their details.
CREATE TABLE admin_requests (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id), -- UPDATED: Account who made the request
    request_type VARCHAR(100) NOT NULL, -- e.g., 'Update Personal Info', 'Update Property Details'
    current_data JSONB, -- Snapshot of data before change (optional, for auditing)
    requested_changes JSONB NOT NULL, -- JSON object describing the requested changes (e.g., {'first_name': 'NewName', 'phone_number': 'NewPhone'})
    status VARCHAR(50) DEFAULT 'Pending' NOT NULL, -- 'Pending', 'Approved', 'Rejected', 'Cancelled'
    requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_by_admin_account_id BIGINT REFERENCES accounts(id), -- UPDATED: Admin account who reviewed the request
    reviewed_at TIMESTAMPTZ,
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups by account and status
CREATE INDEX idx_admin_requests_account_status ON admin_requests (account_id, status);