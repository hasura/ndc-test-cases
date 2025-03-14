
/*******************************************************************************
   Chinook Database - Version 1.4
   Script: Chinook_Oracle.sql
   Description: Creates and populates the Chinook database.
   DB Server: Oracle
   Author: Luis Rocha
   License: http://www.codeplex.com/ChinookDatabase/license
********************************************************************************/


/*******************************************************************************
   Create Tables
********************************************************************************/
CREATE TABLE "Album"
(
    "AlbumId" NUMBER NOT NULL,
    "Title" VARCHAR2(160) NOT NULL,
    "ArtistId" NUMBER NOT NULL,
    CONSTRAINT "PK_Album" PRIMARY KEY ("AlbumId")
);

COMMENT ON TABLE "Album" IS 'The record of all albums';
COMMENT ON COLUMN "Album"."AlbumId" IS 'The identifier of an album';
COMMENT ON COLUMN "Album"."Title" IS 'The title of an album';
COMMENT ON COLUMN "Album"."ArtistId" IS 'The id of the artist that authored the album';

CREATE TABLE "Artist"
(
    "ArtistId" NUMBER NOT NULL,
    "Name" VARCHAR2(120),
    CONSTRAINT "PK_Artist" PRIMARY KEY ("ArtistId")
);

COMMENT ON TABLE "Artist" IS 'The record of all artists';
COMMENT ON COLUMN "Artist"."ArtistId" IS 'The identifier of an artist';
COMMENT ON COLUMN "Artist"."Name" IS 'The name of an artist';

CREATE TABLE "Customer"
(
    "CustomerId" NUMBER NOT NULL,
    "FirstName" VARCHAR2(40) NOT NULL,
    "LastName" VARCHAR2(20) NOT NULL,
    "Company" VARCHAR2(80),
    "Address" VARCHAR2(70),
    "City" VARCHAR2(40),
    "State" VARCHAR2(40),
    "Country" VARCHAR2(40),
    "PostalCode" VARCHAR2(10),
    "Phone" VARCHAR2(24),
    "Fax" VARCHAR2(24),
    "Email" VARCHAR2(60) NOT NULL,
    "SupportRepId" NUMBER,
    CONSTRAINT "PK_Customer" PRIMARY KEY ("CustomerId")
);

COMMENT ON TABLE "Customer" IS 'The record of all customers';
COMMENT ON COLUMN "Customer"."CustomerId" IS 'The identifier of a customer';
COMMENT ON COLUMN "Customer"."FirstName" IS 'The first name of a customer';
COMMENT ON COLUMN "Customer"."LastName" IS 'The last name of a customer';

CREATE TABLE "Employee"
(
    "EmployeeId" NUMBER NOT NULL,
    "LastName" VARCHAR2(20) NOT NULL,
    "FirstName" VARCHAR2(20) NOT NULL,
    "Title" VARCHAR2(30),
    "ReportsTo" NUMBER,
    "BirthDate" TIMESTAMP,
    "HireDate" TIMESTAMP,
    "Address" VARCHAR2(70),
    "City" VARCHAR2(40),
    "State" VARCHAR2(40),
    "Country" VARCHAR2(40),
    "PostalCode" VARCHAR2(10),
    "Phone" VARCHAR2(24),
    "Fax" VARCHAR2(24),
    "Email" VARCHAR2(60),
    CONSTRAINT "PK_Employee" PRIMARY KEY ("EmployeeId")
);

CREATE TABLE "Genre"
(
    "GenreId" NUMBER NOT NULL,
    "Name" VARCHAR2(120),
    CONSTRAINT "PK_Genre" PRIMARY KEY ("GenreId")
);

CREATE TABLE "Invoice"
(
    "InvoiceId" NUMBER NOT NULL,
    "CustomerId" NUMBER NOT NULL,
    "InvoiceDate" TIMESTAMP NOT NULL,
    "BillingAddress" VARCHAR2(70),
    "BillingCity" VARCHAR2(40),
    "BillingState" VARCHAR2(40),
    "BillingCountry" VARCHAR2(40),
    "BillingPostalCode" VARCHAR2(10),
    "Total" NUMBER(10,2) NOT NULL,
    CONSTRAINT "PK_Invoice" PRIMARY KEY ("InvoiceId")
);

CREATE TABLE "InvoiceLine"
(
    "InvoiceLineId" NUMBER NOT NULL,
    "InvoiceId" NUMBER NOT NULL,
    "TrackId" NUMBER NOT NULL,
    "UnitPrice" NUMBER(10,2) NOT NULL,
    "Quantity" NUMBER NOT NULL,
    CONSTRAINT "PK_InvoiceLine" PRIMARY KEY ("InvoiceLineId")
);

CREATE TABLE "MediaType"
(
    "MediaTypeId" NUMBER NOT NULL,
    "Name" VARCHAR2(120),
    CONSTRAINT "PK_MediaType" PRIMARY KEY ("MediaTypeId")
);

CREATE TABLE "Playlist"
(
    "PlaylistId" NUMBER NOT NULL,
    "Name" VARCHAR2(120),
    CONSTRAINT "PK_Playlist" PRIMARY KEY ("PlaylistId")
);

CREATE TABLE "PlaylistTrack"
(
    "PlaylistId" NUMBER NOT NULL,
    "TrackId" NUMBER NOT NULL,
    CONSTRAINT "PK_PlaylistTrack" PRIMARY KEY ("PlaylistId", "TrackId")
);

CREATE TABLE "Track"
(
    "TrackId" NUMBER NOT NULL,
    "Name" VARCHAR2(200) NOT NULL,
    "AlbumId" NUMBER,
    "MediaTypeId" NUMBER NOT NULL,
    "GenreId" NUMBER,
    "Composer" VARCHAR2(220),
    "Milliseconds" NUMBER NOT NULL,
    "Bytes" NUMBER,
    "UnitPrice" NUMBER(10,2) NOT NULL,
    CONSTRAINT "PK_Track" PRIMARY KEY ("TrackId")
);



/*******************************************************************************
   Create Primary Key Unique Indexes
********************************************************************************/

/*******************************************************************************
   Create Foreign Keys
********************************************************************************/
ALTER TABLE "Album" ADD CONSTRAINT "FK_AlbumArtistId"
    FOREIGN KEY ("ArtistId") REFERENCES "Artist" ("ArtistId");

CREATE INDEX "IFK_AlbumArtistId" ON "Album" ("ArtistId");

ALTER TABLE "Customer" ADD CONSTRAINT "FK_CustomerSupportRepId"
    FOREIGN KEY ("SupportRepId") REFERENCES "Employee" ("EmployeeId");

CREATE INDEX "IFK_CustomerSupportRepId" ON "Customer" ("SupportRepId");

ALTER TABLE "Employee" ADD CONSTRAINT "FK_EmployeeReportsTo"
    FOREIGN KEY ("ReportsTo") REFERENCES "Employee" ("EmployeeId");

CREATE INDEX "IFK_EmployeeReportsTo" ON "Employee" ("ReportsTo");

ALTER TABLE "Invoice" ADD CONSTRAINT "FK_InvoiceCustomerId"
    FOREIGN KEY ("CustomerId") REFERENCES "Customer" ("CustomerId");

CREATE INDEX "IFK_InvoiceCustomerId" ON "Invoice" ("CustomerId");

ALTER TABLE "InvoiceLine" ADD CONSTRAINT "FK_InvoiceLineInvoiceId"
    FOREIGN KEY ("InvoiceId") REFERENCES "Invoice" ("InvoiceId");

CREATE INDEX "IFK_InvoiceLineInvoiceId" ON "InvoiceLine" ("InvoiceId");

ALTER TABLE "InvoiceLine" ADD CONSTRAINT "FK_InvoiceLineTrackId"
    FOREIGN KEY ("TrackId") REFERENCES "Track" ("TrackId");

CREATE INDEX "IFK_InvoiceLineTrackId" ON "InvoiceLine" ("TrackId");

ALTER TABLE "PlaylistTrack" ADD CONSTRAINT "FK_PlaylistTrackPlaylistId"
    FOREIGN KEY ("PlaylistId") REFERENCES "Playlist" ("PlaylistId");

ALTER TABLE "PlaylistTrack" ADD CONSTRAINT "FK_PlaylistTrackTrackId"
    FOREIGN KEY ("TrackId") REFERENCES "Track" ("TrackId");

CREATE INDEX "IFK_PlaylistTrackTrackId" ON "PlaylistTrack" ("TrackId");

ALTER TABLE "Track" ADD CONSTRAINT "FK_TrackAlbumId"
    FOREIGN KEY ("AlbumId") REFERENCES "Album" ("AlbumId");

CREATE INDEX "IFK_TrackAlbumId" ON "Track" ("AlbumId");

ALTER TABLE "Track" ADD CONSTRAINT "FK_TrackGenreId"
    FOREIGN KEY ("GenreId") REFERENCES "Genre" ("GenreId");

CREATE INDEX "IFK_TrackGenreId" ON "Track" ("GenreId");

ALTER TABLE "Track" ADD CONSTRAINT "FK_TrackMediaTypeId"
    FOREIGN KEY ("MediaTypeId") REFERENCES "MediaType" ("MediaTypeId");

CREATE INDEX "IFK_TrackMediaTypeId" ON "Track" ("MediaTypeId");


