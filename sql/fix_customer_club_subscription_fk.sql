-- Fix customer_club_subscription foreign key
-- This script corrects the foreign key constraint that was incorrectly pointing to [user] table
-- It should point to customer table instead

USE adalana_db;
GO

-- Remove incorrect foreign key that references [user] table
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_ccs_customer')
BEGIN
    ALTER TABLE customer_club_subscription
    DROP CONSTRAINT fk_ccs_customer;
    PRINT 'Dropped incorrect foreign key fk_ccs_customer';
END
ELSE
BEGIN
    PRINT 'Foreign key fk_ccs_customer does not exist';
END
GO

-- Add correct foreign key that references customer table
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_ccs_customer')
BEGIN
    ALTER TABLE customer_club_subscription
    ADD CONSTRAINT fk_ccs_customer FOREIGN KEY (customer_id) 
        REFERENCES customer(id) ON DELETE NO ACTION;
    PRINT 'Created correct foreign key fk_ccs_customer pointing to customer table';
END
ELSE
BEGIN
    PRINT 'Foreign key fk_ccs_customer already exists';
END
GO

