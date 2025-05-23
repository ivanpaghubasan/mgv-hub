-- 1. Roles Table
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

-- 2. Users Table
-- Central table for all individuals who can log into the system.
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES roles(id), -- Links to the role of the user
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Store bcrypt hash of the password
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    address_line1 VARCHAR(255), -- Could be the mailing address, not necessarily property
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    zip_code VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE NOT NULL, -- For deactivating users
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster email lookups during login
CREATE INDEX idx_users_email ON users (email);

-- 3. Properties Table
-- Details about each property in the subdivision.
CREATE TABLE properties (
    id BIGSERIAL PRIMARY KEY,
    property_number VARCHAR(50) UNIQUE NOT NULL, -- e.g., "Lot 10 Block 5", "Unit 20A"
    address VARCHAR(255) UNIQUE NOT NULL, -- Full street address within the subdivision
    size_sqm DECIMAL(10, 2), -- Size in square meters
    property_type VARCHAR(50), -- e.g., 'Residential', 'Commercial', 'Vacant Lot'
    status VARCHAR(50) DEFAULT 'Occupied' NOT NULL, -- e.g., 'Occupied', 'Vacant', 'Under Construction'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster property number lookups
CREATE INDEX idx_properties_property_number ON properties (property_number);

-- 4. Property Occupants Table
-- Links users (homeowners or tenants) to properties, capturing their relationship and validity period.
CREATE TABLE property_occupants (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    property_id BIGINT NOT NULL REFERENCES properties(id),
    occupant_type VARCHAR(50) NOT NULL, -- 'Owner', 'Tenant'
    start_date DATE NOT NULL,
    end_date DATE, -- NULL if current occupant
    is_primary_owner BOOLEAN DEFAULT FALSE, -- For properties with multiple owners
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, property_id, occupant_type, start_date) -- Prevents duplicate active relationships
);

-- Index for faster lookups by user and property
CREATE INDEX idx_property_occupants_user_property ON property_occupants (user_id, property_id);

-- 5. Fee Types Table
-- Defines the types of fees.
CREATE TABLE fee_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL, -- e.g., 'Monthly Dues', 'Special Assessment', 'Maintenance Fee'
    description TEXT,
    default_amount DECIMAL(10, 2) NOT NULL, -- A default amount, can be overridden per property_fee
    recurrence_type VARCHAR(50) NOT NULL, -- e.g., 'Monthly', 'Quarterly', 'Annually', 'One-Time'
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Initial Fee Types Data (Seed this)
INSERT INTO fee_types (name, default_amount, recurrence_type) VALUES
('Monthly Dues', 500.00, 'Monthly'),
('Special Assessment', 1000.00, 'One-Time');


-- 6. Property Fees (Actual Due Amounts)
-- Records specific fee amounts charged to a property for a given period.
CREATE TABLE property_fees (
    id BIGSERIAL PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(id),
    fee_type_id BIGINT NOT NULL REFERENCES fee_types(id),
    billed_amount DECIMAL(10, 2) NOT NULL, -- The actual amount charged for this instance
    due_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'Outstanding' NOT NULL, -- 'Outstanding', 'Paid', 'Overdue', 'Waived'
    billing_period_start DATE, -- For recurring fees (e.g., start of month for monthly dues)
    billing_period_end DATE,   -- For recurring fees (e.g., end of month for monthly dues)
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (property_id, fee_type_id, due_date) -- Prevents duplicate bills for the same fee/property/period
);

-- Index for faster lookups by property and due date
CREATE INDEX idx_property_fees_property_due_date ON property_fees (property_id, due_date);


-- 7. Payments Table
-- Records actual payments made by homeowners.
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id), -- User who made the payment
    property_fee_id BIGINT REFERENCES property_fees(id), -- The specific fee being paid (can be NULL if it's an overpayment or general credit)
    amount_paid DECIMAL(10, 2) NOT NULL,
    payment_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL, -- 'GCash', 'Bank Transfer', 'Cash', 'Credit Card'
    transaction_id VARCHAR(255) UNIQUE, -- Transaction ID from payment gateway (e.g., GCash, PayMongo)
    status VARCHAR(50) NOT NULL, -- 'Pending', 'Completed', 'Failed', 'Refunded'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups by user and date
CREATE INDEX idx_payments_user_date ON payments (user_id, payment_date);


-- 8. Payment Receipts Table
-- Stores details or links to digital receipts.
CREATE TABLE payment_receipts (
    id BIGSERIAL PRIMARY KEY,
    payment_id BIGINT UNIQUE NOT NULL REFERENCES payments(id), -- One receipt per payment
    receipt_number VARCHAR(100) UNIQUE, -- Unique receipt identifier
    receipt_url TEXT, -- URL to the digital receipt if hosted externally
    receipt_data JSONB, -- Store JSON data from payment gateway if needed
    generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- 9. News Table
-- For general news articles or updates.
CREATE TABLE news (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL REFERENCES users(id), -- Admin who posted the news
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    published_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 10. Announcements Table
-- For time-sensitive announcements.
CREATE TABLE announcements (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL REFERENCES users(id), -- Admin who posted the announcement
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    published_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ, -- When the announcement is no longer relevant
    is_active BOOLEAN DEFAULT TRUE NOT NULL, -- Can be manually deactivated
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 11. Contact Types Table
-- Defines categories for general contacts.
CREATE TABLE contact_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL -- e.g., 'HOA Office', 'Emergency', 'Security'
);

-- Initial Contact Types Data (Seed this)
INSERT INTO contact_types (name) VALUES
('HOA Office'),
('Emergency Services'),
('Security');


-- 12. Contacts Table
-- Stores general contact information for the HOA.
CREATE TABLE contacts (
    id BIGSERIAL PRIMARY KEY,
    contact_type_id BIGINT NOT NULL REFERENCES contact_types(id),
    name VARCHAR(255) NOT NULL, -- e.g., 'HOA President', 'Subdivision Emergency Hotline'
    phone_number VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 13. Admin Requests Table
-- Manages requests from homeowners to modify their details.
CREATE TABLE admin_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id), -- User who made the request
    request_type VARCHAR(100) NOT NULL, -- e.g., 'Update Personal Info', 'Update Property Details'
    current_data JSONB, -- Snapshot of data before change (optional, for auditing)
    requested_changes JSONB NOT NULL, -- JSON object describing the requested changes (e.g., {'first_name': 'NewName', 'phone_number': 'NewPhone'})
    status VARCHAR(50) DEFAULT 'Pending' NOT NULL, -- 'Pending', 'Approved', 'Rejected', 'Cancelled'
    requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_by_admin_id BIGINT REFERENCES users(id), -- Admin who reviewed the request
    reviewed_at TIMESTAMPTZ,
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups by user and status
CREATE INDEX idx_admin_requests_user_status ON admin_requests (user_id, status);