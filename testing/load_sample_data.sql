DROP TABLE IF EXISTS auto_deidentifier_logs;
DROP TABLE IF EXISTS configurations;
DROP TABLE IF EXISTS donors;
DROP TABLE IF EXISTS volunteer_shifts;
DROP TABLE IF EXISTS grant_applications;

CREATE TABLE configurations (
    configuration_name      TEXT PRIMARY KEY,
    table_name              VARCHAR NOT NULL,
    sensitive_columns       TEXT[],
    identifiers             TEXT[],
    method                  VARCHAR(255) DEFAULT 'default'

    CONSTRAINT check_method_type
        CHECK (method IN ('default', 'censor', 'scramble'))
    CONSTRAINT identifiers_not_empty
        CHECK (cardinality(identifiers) > 0)
);

CREATE TABLE auto_deidentifier_logs (
    log_id UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    time                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    configuration_name      TEXT REFERENCES configurations(configuration_name),
    table_name              TEXT,
    type                    TEXT,
    details                 TEXT,

    CONSTRAINT check_log_type
        CHECK (type IN ('success', 'error', 'warning'))
);

-- 1. DONOR DATABASE (High PII Density)
-- Used for testing masking on names, emails, and financial markers.
CREATE TABLE donors (
    donor_id UUID           PRIMARY KEY,
    first_name              VARCHAR(50),
    last_name               VARCHAR(50),
    email                   VARCHAR(100),
    phone_number            VARCHAR(20),
    date_of_birth           DATE,
    total_donations_usd     DECIMAL(10, 2),
    last_contact_date       DATE,
    opt_in_newsletter       BOOLEAN
);

-- 2. VOLUNTEER LOGS (Transactional / Temporal Data)
-- Used for testing filtering/sorting based on "Last Active" dates.
CREATE TABLE volunteer_shifts (
    shift_id                SERIAL PRIMARY KEY,
    volunteer_full_name     VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    shift_date              DATE,
    hours_worked            DECIMAL(4, 2),
    location_site           VARCHAR(100),
    supervisor_notes        TEXT
);

-- 3. GRANT APPLICATIONS (Sensitive Narrative Data)
-- Used for testing redaction within text fields and social identifiers.
CREATE TABLE grant_applications (
    app_id                  INT PRIMARY KEY,
    applicant_ssn_last4     VARCHAR(4),
    household_income        INT,
    street_address          VARCHAR(255),
    city                    VARCHAR(100),
    postal_code             VARCHAR(20),
    application_status      VARCHAR(20),
    submission_timestamp    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO configurations (configuration_name, table_name, sensitive_columns, identifiers)
VALUES
('donors-example-config', 'donors', ARRAY['first_name', 'last_name', 'email', 'phone_number', 'date_of_birth'], ARRAY['donor_id']),
('bad-config-missing-table', 'not_a_table', ARRAY['first_name', 'last_name', 'email', 'phone_number', 'date_of_birth'], ARRAY['donor_id']),
('volunteer_shifts-example-config', 'volunteer_shifts', ARRAY['volunteer_full_name', 'emergency_contact_phone'], ARRAY['shift_id']),
('grant_applications-example-config', 'grant_applications', ARRAY['applicant_ssn_last4', 'street_address', 'postal_code', 'city'], ARRAY['app_id']);

INSERT INTO donors (donor_id, first_name, last_name, email, phone_number, date_of_birth, total_donations_usd, last_contact_date, opt_in_newsletter)
VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Jane', 'Doe', 'jane.doe@email.com', '555-0101', '1985-05-12', 1500.00, '2023-11-20', TRUE),
('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'John', 'Smith', 'jsmith123@provider.net', '555-0102', '1990-02-28', 50.00, '2025-01-15', FALSE),
('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Alice', 'Vance', 'avance@charity.org', '555-0999', '1972-08-30', 4200.50, '2024-06-10', TRUE),
('d3e4f5a6-b7c8-4d9e-8f1a-2b3c4d5e6f7a', 'Robert', 'Miller', 'bob.miller@webmail.com', '555-0103', '1965-12-01', 120.00, '2021-05-22', FALSE),
('e5f6c7d8-a9b0-4c1d-8e3f-4a5b6c7d8e9f', 'Sarah', 'Connor', 'sconnor@cyber.com', '555-1984', '1984-11-01', 0.00, '2024-12-01', TRUE),
('f1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c', 'Michael', 'Scott', 'm.scott@dundermifflin.com', '555-0105', '1975-03-15', 250.00, '2023-08-14', TRUE),
('a1234567-b89c-4d0e-8f1a-2b3c4d5e6f7a', 'Pam', 'Beesly', 'pam.art@paints.com', '555-0106', '1979-03-25', 500.00, '2025-01-20', TRUE),
('b2345678-c90d-4e1f-8a2b-3c4d5e6f7a8b', 'Jim', 'Halpert', 'bigtune@sports.com', '555-0107', '1978-10-01', 1000.00, '2024-11-30', FALSE),
('c3456789-d01e-4f2a-8b3c-4d5e6f7a8b9c', 'Angela', 'Martin', 'cats@accountants.org', '555-0108', '1971-06-25', 15000.00, '2025-02-01', TRUE),
('d4567890-e12f-4a3b-8c4d-5e6f7a8b9c0d', 'Kevin', 'Malone', 'chili.king@scranton.net', '555-0109', '1972-01-01', 10.00, '2022-04-12', FALSE),
('e5678901-f23a-4b4c-8d5e-6f7a8b9c0d1e', 'Oscar', 'Martinez', 'actually@rational.org', '555-0110', '1970-11-18', 300.00, '2024-09-15', TRUE),
('f6789012-a34b-4c5d-8e6f-7a8b9c0d1e2f', 'Stanley', 'Hudson', 'pretzel@day.com', '555-0111', '1958-07-09', 20.00, '2021-12-25', FALSE),
('a7890123-b45c-4d6e-8f7a-8b9c0d1e2f3a', 'Phyllis', 'Vance', 'phyllis@vancerefrig.com', '555-0112', '1961-02-14', 2500.00, '2024-05-19', TRUE),
('b8901234-c56d-4e7f-8a8b-9c0d1e2f3a4b', 'Ryan', 'Howard', 'temp@wunderkind.com', '555-0113', '1982-05-05', 0.00, '2023-01-10', TRUE),
('c9012345-d67e-4f8a-8b9c-0d1e2f3a4b5c', 'Kelly', 'Kapoor', 'shopping@fashion.in', '555-0114', '1980-02-05', 450.00, '2024-12-25', TRUE),
('d0123456-e78f-4a9b-8c0d-1e2f3a4b5c6d', 'Toby', 'Flenderson', 'hr@scranton.gov', '555-0115', '1970-02-22', 100.00, '2020-10-10', FALSE),
('e1234567-f89a-4b0c-8d1e-2f3a4b5c6d7e', 'Meredith', 'Palmer', 'party@supplies.net', '555-0116', '1965-06-06', 75.00, '2024-08-08', TRUE),
('f2345678-a90b-4c1d-8e2f-3a4b5c6d7e8f', 'Creed', 'Bratton', 'unknown@nobody.knows', '555-0000', '1943-02-08', 5.00, '2019-01-01', FALSE),
('a3456789-b01c-4d2e-8f3a-4b5c6d7e8f9a', 'Darryl', 'Philbin', 'warehouse@logistics.com', '555-0118', '1975-10-25', 600.00, '2025-01-10', TRUE),
('b4567890-c12d-4e3f-8a4b-5c6d7e8f9a0b', 'Erin', 'Hannon', 'frontdesk@reception.org', '555-0119', '1986-04-12', 150.00, '2024-10-15', TRUE);

INSERT INTO volunteer_shifts (volunteer_full_name, emergency_contact_phone, shift_date, hours_worked, location_site, supervisor_notes)
VALUES
('Michael Scott', '555-9876', '2025-01-10', 4.5, 'Downtown Soup Kitchen', 'Arrived early, very helpful.'),
('Pam Beesly', '555-4321', '2025-01-11', 3.0, 'Community Garden', 'Handled the heavy lifting well.'),
('Dwight Schrute', '555-0000', '2025-01-12', 8.0, 'Beet Farm Outreach', 'Efficiency was high, but lacked soft skills.'),
('Jim Halpert', '555-1111', '2025-01-15', 2.0, 'Youth Center', 'Engaged with the kids well.'),
('Angela Martin', '555-2222', '2025-01-16', 4.0, 'Animal Shelter', 'Very strict about the cleaning protocols.'),
('Kevin Malone', '555-3333', '2025-01-17', 5.5, 'Downtown Soup Kitchen', 'Good with the ladle, dropped one pot though.'),
('Oscar Martinez', '555-4444', '2025-01-18', 3.5, 'Tax Help Clinic', 'Invaluable help with filings.'),
('Stanley Hudson', '555-5555', '2025-01-20', 2.0, 'Community Garden', 'Mostly sat on the bench, but did some weeding.'),
('Phyllis Vance', '555-6666', '2025-01-22', 4.0, 'Knitting Circle', 'Great teacher for the new members.'),
('Ryan Howard', '555-7777', '2025-01-25', 1.0, 'Tech Lab', 'Left early for a meeting.'),
('Kelly Kapoor', '555-8888', '2025-01-26', 6.0, 'Customer Service Desk', 'Talked a lot but solved many issues.'),
('Toby Flenderson', '555-9999', '2025-01-27', 4.0, 'Counseling Center', 'Quiet and effective.'),
('Meredith Palmer', '555-1212', '2025-01-28', 5.0, 'Event Cleanup', 'Found some leftover beverages.'),
('Creed Bratton', '555-1313', '2025-01-30', 2.0, 'Unknown Site', 'We are not sure what he actually did.'),
('Darryl Philbin', '555-1414', '2025-02-01', 6.5, 'Warehouse Logistics', 'Organized the entire inventory.'),
('Erin Hannon', '555-1515', '2025-02-02', 4.0, 'Hospital Reception', 'Brightened everyones day.'),
('Andy Bernard', '555-1616', '2025-02-03', 3.0, 'Music Workshop', 'A bit loud with the banjo.'),
('Nellie Bertram', '555-1717', '2025-02-04', 4.5, 'Downtown Soup Kitchen', 'Very enthusiastic.'),
('Gabe Lewis', '555-1818', '2025-02-05', 2.5, 'Night Shift Security', 'A bit creepy but followed rules.'),
('Clark Green', '555-1919', '2025-02-06', 5.0, 'Tech Lab', 'Handled hardware repairs.');

INSERT INTO grant_applications (app_id, applicant_ssn_last4, household_income, street_address, city, postal_code, application_status)
VALUES
(101, '4422', 45000, '123 Maple St', 'Springfield', '62704', 'Approved'),
(102, '8811', 32000, '456 Oak Ln', 'Shelbyville', '62705', 'Pending'),
(103, '1199', 15000, '789 Pine Rd', 'Capital City', '62701', 'Denied'),
(104, '3344', 60000, '101 Cedar Blvd', 'Ogdenville', '62702', 'Approved'),
(105, '5566', 22000, '202 Birch Ct', 'North Haverbrook', '62703', 'Reviewing'),
(106, '7788', 35000, '303 Elm Wy', 'Springfield', '62704', 'Approved'),
(107, '9900', 12000, '404 Walnut Dr', 'Shelbyville', '62705', 'Pending'),
(108, '2233', 52000, '505 Cherry Ln', 'Capital City', '62701', 'Approved'),
(109, '4455', 28000, '606 Ash Ave', 'Ogdenville', '62702', 'Reviewing'),
(110, '6677', 41000, '707 Poplar Ter', 'North Haverbrook', '62703', 'Denied'),
(111, '8899', 19000, '808 Spruce St', 'Springfield', '62704', 'Pending'),
(112, '1122', 75000, '909 Willow Rd', 'Shelbyville', '62705', 'Approved'),
(113, '3355', 33000, '111 Aspen Dr', 'Capital City', '62701', 'Reviewing'),
(114, '5577', 25000, '222 Beech St', 'Ogdenville', '62702', 'Denied'),
(115, '7799', 48000, '333 Sycamore Ln', 'North Haverbrook', '62703', 'Approved'),
(116, '9911', 54000, '444 Hickory Ave', 'Springfield', '62704', 'Pending'),
(117, '2244', 31000, '555 Redwood Ct', 'Shelbyville', '62705', 'Approved'),
(118, '4466', 27000, '666 Sequoia Dr', 'Capital City', '62701', 'Reviewing'),
(119, '6688', 14000, '777 Juniper Wy', 'Ogdenville', '62702', 'Denied'),
(120, '0099', 28000, '789 Pine Rd', 'Capital City', '62701', 'Denied');
