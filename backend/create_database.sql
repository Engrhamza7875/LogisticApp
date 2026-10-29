-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SabCargoDB')
BEGIN
    CREATE DATABASE SabCargoDB;
END
GO

USE SabCargoDB;
GO

-- Create Users table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
BEGIN
    CREATE TABLE Users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        fullName NVARCHAR(255) NOT NULL,
        email NVARCHAR(255) UNIQUE NOT NULL,
        phone NVARCHAR(20),
        pin NVARCHAR(10),
        createdAt DATETIME2 DEFAULT GETDATE(),
        updatedAt DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Add columns if they don't exist (for existing tables)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'phone')
BEGIN
    ALTER TABLE Users ADD phone NVARCHAR(20);
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'pin')
BEGIN
    ALTER TABLE Users ADD pin NVARCHAR(10);
END
GO

-- Auth extensions (keep existing structure, only extend)
-- Add verification + hashed PIN columns (supports both legacy 'id' and newer 'Id' naming setups)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'IsVerified')
BEGIN
    ALTER TABLE Users ADD IsVerified BIT NOT NULL CONSTRAINT DF_Users_IsVerified DEFAULT 0;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PinHash')
BEGIN
    ALTER TABLE Users ADD PinHash NVARCHAR(255) NULL;
END
GO

-- OTP table (one active OTP per user enforced by logic)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='UserOtps' AND xtype='U')
BEGIN
    CREATE TABLE UserOtps (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        OtpHash NVARCHAR(255) NOT NULL,
        ExpiresAt DATETIME2 NOT NULL,
        Used BIT NOT NULL CONSTRAINT DF_UserOtps_Used DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_UserOtps_CreatedAt DEFAULT GETDATE()
    );
END
GO

-- Helpful index for latest OTP lookup
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_UserOtps_UserId_CreatedAt'
      AND object_id = OBJECT_ID('UserOtps')
)
BEGIN
    CREATE INDEX IX_UserOtps_UserId_CreatedAt
    ON UserOtps(UserId, CreatedAt DESC);
END
GO

-- Insert sample data if table is empty
IF NOT EXISTS (SELECT 1 FROM Users)
BEGIN
    INSERT INTO Users (fullName, email, phone, pin) VALUES
    ('John Doe', 'john@example.com', '+1234567890', '123456'),
    ('Jane Smith', 'jane@example.com', '+1987654321', '654321'),
    ('Bob Johnson', 'bob@example.com', '+1122334455', '111111');
END
GO

-- Create Shipments table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Shipments' AND xtype='U')
BEGIN
    CREATE TABLE Shipments (
        id INT IDENTITY(1,1) PRIMARY KEY,
        shipmentData NVARCHAR(MAX) NOT NULL,
        userEmail NVARCHAR(255),
        createdAt DATETIME2 DEFAULT GETDATE(),
        syncedAt DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Create Bookings table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Bookings' AND xtype='U')
BEGIN
    CREATE TABLE Bookings (
        id INT IDENTITY(1,1) PRIMARY KEY,
        bookingData NVARCHAR(MAX) NOT NULL,
        userEmail NVARCHAR(255),
        createdAt DATETIME2 DEFAULT GETDATE(),
        syncedAt DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Create Missions table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Missions' AND xtype='U')
BEGIN
    CREATE TABLE Missions (
        id INT IDENTITY(1,1) PRIMARY KEY,
        missionId NVARCHAR(255) NOT NULL,
        status NVARCHAR(50) NOT NULL,
        userEmail NVARCHAR(255),
        createdAt DATETIME2 DEFAULT GETDATE(),
        syncedAt DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Create SystemRoles Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SystemRoles' AND xtype='U')
BEGIN
    CREATE TABLE SystemRoles (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        RoleName NVARCHAR(50) UNIQUE NOT NULL, -- 'User', 'Admin', 'SuperAdmin'
        Description NVARCHAR(255)
    );
    -- Insert Default Roles
    INSERT INTO SystemRoles (RoleName, Description) VALUES
    ('User', 'Standard user with personal access'),
    ('Admin', 'Operations staff with management capability'),
    ('SuperAdmin', 'System owner with full capabilities');
END
GO

-- Create Permissions Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Permissions' AND xtype='U')
BEGIN
    CREATE TABLE Permissions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PermissionName NVARCHAR(100) UNIQUE NOT NULL,
        Description NVARCHAR(255)
    );
    -- Insert Default Permissions
    INSERT INTO Permissions (PermissionName, Description) VALUES 
    ('MANAGE_SHIPMENTS', 'Create, update, delete shipments'),
    ('MANAGE_USERS', 'View user data and reset access'),
    ('MANAGE_SYSTEM', 'Modify global settings and admin rights');
END
GO

-- Create RolePermissions Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RolePermissions' AND xtype='U')
BEGIN
    CREATE TABLE RolePermissions (
        RoleId INT FOREIGN KEY REFERENCES SystemRoles(Id),
        PermissionId INT FOREIGN KEY REFERENCES Permissions(Id),
        PRIMARY KEY (RoleId, PermissionId)
    );
END
GO

-- Create SystemLogs Table for Audit
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SystemLogs' AND xtype='U')
BEGIN
    CREATE TABLE SystemLogs (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserEmail NVARCHAR(255) NULL,
        Action NVARCHAR(100) NOT NULL,
        Details NVARCHAR(MAX),
        CreatedAt DATETIME2 DEFAULT GETDATE()
    );
END
GO
-- Create Admins Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Admins' AND xtype='U')
BEGIN
    CREATE TABLE Admins (
        Id NVARCHAR(100) PRIMARY KEY,
        FullName NVARCHAR(255) NOT NULL,
        Email NVARCHAR(255) UNIQUE NOT NULL,
        Phone NVARCHAR(50),
        Role NVARCHAR(50) NOT NULL, -- 'admin', 'superAdmin'
        Branch NVARCHAR(255),
        IsActive BIT DEFAULT 1,
        PermissionsJson NVARCHAR(MAX),
        CreatedAt DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Create SystemSettings Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SystemSettings' AND xtype='U')
BEGIN
    CREATE TABLE SystemSettings (
        SettingKey NVARCHAR(100) PRIMARY KEY,
        SettingValue NVARCHAR(MAX) NOT NULL,
        UpdatedAt DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Seed Default SuperAdmins
IF NOT EXISTS (SELECT * FROM Admins WHERE Email = 'engrhamza787@gmail.com')
BEGIN
    INSERT INTO Admins (Id, FullName, Email, Phone, Role, Branch, IsActive, PermissionsJson)
    VALUES ('A001', 'Hamza Engineer', 'engrhamza787@gmail.com', '+966 50 123 4567', 'superAdmin', 'Head Office (Al Olaya)', 1, '["MANAGE_SHIPMENTS","MANAGE_USERS","MANAGE_SYSTEM"]')
END

IF NOT EXISTS (SELECT * FROM Admins WHERE Email = 'freelancing.fiver001@gmail.com')
BEGIN
    INSERT INTO Admins (Id, FullName, Email, Phone, Role, Branch, IsActive, PermissionsJson)
    VALUES ('A002', 'Fiverr Support', 'freelancing.fiver001@gmail.com', '+966 50 000 0001', 'superAdmin', 'Global Ops', 1, '["MANAGE_SHIPMENTS","MANAGE_USERS","MANAGE_SYSTEM"]')
END
GO

-- Seed Default Settings
IF NOT EXISTS (SELECT * FROM SystemSettings WHERE SettingKey = 'global_business_rules')
BEGIN
    INSERT INTO SystemSettings (SettingKey, SettingValue)
    VALUES ('global_business_rules', '{"shippingRate":30.0,"activeRoutes":["Pakistan","Bangladesh","India","Philippines","UAE","UK","USA"],"cargoServices":[]}')
END
GO

-- ==========================================================
-- GOVERNANCE EXTENSION: IsActive, Services, Notifications
-- ==========================================================

-- Add IsActive to Users (idempotent migration)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'IsActive')
BEGIN
    ALTER TABLE Users ADD IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1;
END
GO

-- Services Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Services' AND xtype='U')
BEGIN
    CREATE TABLE Services (
        Id          INT           PRIMARY KEY IDENTITY(1,1),
        ServiceName NVARCHAR(255) NOT NULL,
        Description NVARCHAR(MAX),
        IconCode    INT,
        ColorValue  BIGINT,
        IsActive    BIT NOT NULL CONSTRAINT DF_Services_IsActive DEFAULT 1,
        CreatedAt   DATETIME2 NOT NULL CONSTRAINT DF_Services_CreatedAt DEFAULT GETDATE()
    );
    INSERT INTO Services (ServiceName, Description, IsActive) VALUES
    ('Air Freight',  'Express 24-48h air transit.', 1),
    ('Sea Freight',  'Cost-effective bulk sea shipping.', 1),
    ('Land Freight', 'Door-to-door road freight.', 1);
END
GO

-- Notifications Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Notifications' AND xtype='U')
BEGIN
    CREATE TABLE Notifications (
        Id         INT           PRIMARY KEY IDENTITY(1,1),
        Title      NVARCHAR(255) NOT NULL,
        Body       NVARCHAR(MAX) NOT NULL,
        SentBy     NVARCHAR(255),
        SentAt     DATETIME2 NOT NULL CONSTRAINT DF_Notifications_SentAt DEFAULT GETDATE(),
        TargetRole NVARCHAR(50)  NOT NULL CONSTRAINT DF_Notifications_TargetRole DEFAULT 'All'
    );
    CREATE INDEX IX_Notifications_SentAt ON Notifications(SentAt DESC);
END
GO
