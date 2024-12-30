/*******************************************************************************
   Chinook Database - Version 1.4
   Script: Chinook_MSSQL.sql
   Description: Creates and populates the Chinook database.
   DB Server: Microsoft SQL Server
   Original Author: Luis Rocha
   Converted by: Claude
   License: http://www.codeplex.com/ChinookDatabase/license
********************************************************************************/

/*******************************************************************************
   Create Tables
********************************************************************************/
CREATE TABLE Album
(
    AlbumId INT NOT NULL,
    Title NVARCHAR(160) NOT NULL,
    ArtistId INT NOT NULL,
    CONSTRAINT PK_Album PRIMARY KEY (AlbumId)
);

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The record of all albums',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = 'Album';

CREATE TABLE Artist
(
    ArtistId INT NOT NULL,
    Name NVARCHAR(120) NULL,
    CONSTRAINT PK_Artist PRIMARY KEY (ArtistId)
);

EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'The record of all artists',
    @level0type = N'SCHEMA', @level0name = 'dbo',
    @level1type = N'TABLE',  @level1name = 'Artist';

CREATE TABLE Customer
(
    CustomerId INT NOT NULL,
    FirstName NVARCHAR(40) NOT NULL,
    LastName NVARCHAR(20) NOT NULL,
    Company NVARCHAR(80) NULL,
    Address NVARCHAR(70) NULL,
    City NVARCHAR(40) NULL,
    State NVARCHAR(40) NULL,
    Country NVARCHAR(40) NULL,
    PostalCode NVARCHAR(10) NULL,
    Phone NVARCHAR(24) NULL,
    Fax NVARCHAR(24) NULL,
    Email NVARCHAR(60) NOT NULL,
    SupportRepId INT NULL,
    CONSTRAINT PK_Customer PRIMARY KEY (CustomerId)
);

CREATE TABLE Employee
(
    EmployeeId INT NOT NULL,
    LastName NVARCHAR(20) NOT NULL,
    FirstName NVARCHAR(20) NOT NULL,
    Title NVARCHAR(30) NULL,
    ReportsTo INT NULL,
    BirthDate DATETIME NULL,
    HireDate DATETIME NULL,
    Address NVARCHAR(70) NULL,
    City NVARCHAR(40) NULL,
    State NVARCHAR(40) NULL,
    Country NVARCHAR(40) NULL,
    PostalCode NVARCHAR(10) NULL,
    Phone NVARCHAR(24) NULL,
    Fax NVARCHAR(24) NULL,
    Email NVARCHAR(60) NULL,
    CONSTRAINT PK_Employee PRIMARY KEY (EmployeeId)
);

CREATE TABLE Genre
(
    GenreId INT NOT NULL,
    Name NVARCHAR(120) NULL,
    CONSTRAINT PK_Genre PRIMARY KEY (GenreId)
);

CREATE TABLE Invoice
(
    InvoiceId INT NOT NULL,
    CustomerId INT NOT NULL,
    InvoiceDate DATETIME NOT NULL,
    BillingAddress NVARCHAR(70) NULL,
    BillingCity NVARCHAR(40) NULL,
    BillingState NVARCHAR(40) NULL,
    BillingCountry NVARCHAR(40) NULL,
    BillingPostalCode NVARCHAR(10) NULL,
    Total DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Invoice PRIMARY KEY (InvoiceId)
);

CREATE TABLE InvoiceLine
(
    InvoiceLineId INT NOT NULL,
    InvoiceId INT NOT NULL,
    TrackId INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    CONSTRAINT PK_InvoiceLine PRIMARY KEY (InvoiceLineId)
);

CREATE TABLE MediaType
(
    MediaTypeId INT NOT NULL,
    Name NVARCHAR(120) NULL,
    CONSTRAINT PK_MediaType PRIMARY KEY (MediaTypeId)
);

CREATE TABLE Playlist
(
    PlaylistId INT NOT NULL,
    Name NVARCHAR(120) NULL,
    CONSTRAINT PK_Playlist PRIMARY KEY (PlaylistId)
);

CREATE TABLE PlaylistTrack
(
    PlaylistId INT NOT NULL,
    TrackId INT NOT NULL,
    CONSTRAINT PK_PlaylistTrack PRIMARY KEY (PlaylistId, TrackId)
);

CREATE TABLE Track
(
    TrackId INT NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    AlbumId INT NULL,
    MediaTypeId INT NOT NULL,
    GenreId INT NULL,
    Composer NVARCHAR(220) NULL,
    Milliseconds INT NOT NULL,
    Bytes INT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Track PRIMARY KEY (TrackId)
);

/*******************************************************************************
   Create Foreign Keys
********************************************************************************/
ALTER TABLE Album ADD CONSTRAINT FK_AlbumArtistId
    FOREIGN KEY (ArtistId) REFERENCES Artist (ArtistId);

CREATE INDEX IFK_AlbumArtistId ON Album (ArtistId);

ALTER TABLE Customer ADD CONSTRAINT FK_CustomerSupportRepId
    FOREIGN KEY (SupportRepId) REFERENCES Employee (EmployeeId);

CREATE INDEX IFK_CustomerSupportRepId ON Customer (SupportRepId);

ALTER TABLE Employee ADD CONSTRAINT FK_EmployeeReportsTo
    FOREIGN KEY (ReportsTo) REFERENCES Employee (EmployeeId);

CREATE INDEX IFK_EmployeeReportsTo ON Employee (ReportsTo);

ALTER TABLE Invoice ADD CONSTRAINT FK_InvoiceCustomerId
    FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId);

CREATE INDEX IFK_InvoiceCustomerId ON Invoice (CustomerId);

ALTER TABLE InvoiceLine ADD CONSTRAINT FK_InvoiceLineInvoiceId
    FOREIGN KEY (InvoiceId) REFERENCES Invoice (InvoiceId);

CREATE INDEX IFK_InvoiceLineInvoiceId ON InvoiceLine (InvoiceId);

ALTER TABLE InvoiceLine ADD CONSTRAINT FK_InvoiceLineTrackId
    FOREIGN KEY (TrackId) REFERENCES Track (TrackId);

CREATE INDEX IFK_InvoiceLineTrackId ON InvoiceLine (TrackId);

ALTER TABLE PlaylistTrack ADD CONSTRAINT FK_PlaylistTrackPlaylistId
    FOREIGN KEY (PlaylistId) REFERENCES Playlist (PlaylistId);

ALTER TABLE PlaylistTrack ADD CONSTRAINT FK_PlaylistTrackTrackId
    FOREIGN KEY (TrackId) REFERENCES Track (TrackId);

CREATE INDEX IFK_PlaylistTrackTrackId ON PlaylistTrack (TrackId);

ALTER TABLE Track ADD CONSTRAINT FK_TrackAlbumId
    FOREIGN KEY (AlbumId) REFERENCES Album (AlbumId);

CREATE INDEX IFK_TrackAlbumId ON Track (AlbumId);

ALTER TABLE Track ADD CONSTRAINT FK_TrackGenreId
    FOREIGN KEY (GenreId) REFERENCES Genre (GenreId);

CREATE INDEX IFK_TrackGenreId ON Track (GenreId);

ALTER TABLE Track ADD CONSTRAINT FK_TrackMediaTypeId
    FOREIGN KEY (MediaTypeId) REFERENCES MediaType (MediaTypeId);

CREATE INDEX IFK_TrackMediaTypeId ON Track (MediaTypeId);
