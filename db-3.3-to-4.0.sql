--
-- Move entries from fac_CabinetAudit to fac_GenericLog
--

INSERT INTO fac_GenericLog (UserID, Class, ObjectID, Action, Time) SELECT fac_CabinetAudit.UserID as UserID, "CabinetAudit" as Class, fac_CabinetAudit.CabinetID as ObjectID, "CertifyAudit" as Action, fac_CabinetAudit.AuditStamp as Time FROM fac_CabinetAudit;

--
-- Not sure if you want to do this yet
-- The answer is NO.  Wait until next point release after 4.0
--

-- DROP TABLE IF EXISTS fac_CabinetAudit;

--
-- Time to merge Contacts and Users - create a new fac_People table and delete the two old ones in the next release
--

DROP TABLE IF EXISTS fac_People;
CREATE TABLE fac_People (
  PersonID int(11) NOT NULL AUTO_INCREMENT,
  UserID varchar(255) NOT NULL,
  LastName varchar(40) NOT NULL,
  FirstName varchar(40) NOT NULL,
  Phone1 varchar(20) NOT NULL,
  Phone2 varchar(20) NOT NULL,
  Phone3 varchar(20) NOT NULL,
  Email varchar(80) NOT NULL,
  AdminOwnDevices tinyint(1) NOT NULL,
  ReadAccess tinyint(1) NOT NULL,
  WriteAccess tinyint(1) NOT NULL,
  DeleteAccess tinyint(1) NOT NULL,
  ContactAdmin tinyint(1) NOT NULL,
  RackRequest tinyint(1) NOT NULL,
  RackAdmin tinyint(1) NOT NULL,
  SiteAdmin tinyint(1) NOT NULL,
  APIToken varchar(80) NOT NULL,
  Disabled tinyint(1) NOT NULL,
  PRIMARY KEY(PersonID),
  KEY(UserID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for fac_DeviceCustomAttribute
--

DROP TABLE IF EXISTS fac_DeviceCustomAttribute;
CREATE TABLE fac_DeviceCustomAttribute(
  AttributeID int(11) NOT NULL AUTO_INCREMENT,
  Label varchar(80) NOT NULL,
  AttributeType enum('string', 'number', 'integer', 'date', 'phone', 'email', 'ipv4', 'url', 'checkbox') NOT NULL DEFAULT 'string',
  Required tinyint(1) NOT NULL DEFAULT 0,
  AllDevices tinyint(1) NOT NULL DEFAULT 0,
  DefaultValue varchar(65000),
  PRIMARY KEY (AttributeID)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for fac_DeviceTemplateCustomValue
--

DROP TABLE IF EXISTS fac_DeviceTemplateCustomValue;
CREATE TABLE fac_DeviceTemplateCustomValue (
  TemplateID int(11) NOT NULL,
  AttributeID int(11) NOT NULL,
  Required tinyint(1) NOT NULL DEFAULT 0,
  Value varchar(65000),
  PRIMARY KEY (TemplateID, AttributeID)
) ENGINE=InnoDB CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for fac_DeviceCustomValue
--

DROP TABLE IF EXISTS fac_DeviceCustomValue;
CREATE TABLE fac_DeviceCustomValue (
  DeviceID int(11) NOT NULL,
  AttributeID int(11) NOT NULL,
  Value varchar(65000),
  PRIMARY KEY (DeviceID, AttributeID)
) ENGINE=InnoDB CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Add new device type for CDUs and Sensors
--
ALTER TABLE fac_Device CHANGE DeviceType DeviceType ENUM( 'Server', 'Appliance', 'Storage Array', 'Switch', 'Patch Panel', 'Physical Infrastructure', 'Chassis', 'CDU', 'Sensor' ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE fac_DeviceTemplate CHANGE DeviceType DeviceType ENUM( 'Server', 'Appliance', 'Storage Array', 'Switch', 'Patch Panel', 'Physical Infrastructure', 'Chassis', 'CDU', 'Sensor' ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;

--
-- Create new table for power ports
--

DROP TABLE IF EXISTS fac_PowerPorts;
CREATE TABLE fac_PowerPorts (
	DeviceID int(11) NOT NULL,
	PortNumber int(11) NOT NULL,
	Label varchar(40) NOT NULL,
	ConnectedDeviceID int(11) DEFAULT NULL,
	ConnectedPort int(11) DEFAULT NULL,
	Notes varchar(80) NOT NULL,
	PRIMARY KEY (DeviceID,PortNumber),
	UNIQUE KEY LabeledPort (DeviceID,PortNumber,Label),
	UNIQUE KEY ConnectedDevice (ConnectedDeviceID,ConnectedPort)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- TemplatePowerPorts table content the power connections of a device template 
--

DROP TABLE IF EXISTS fac_TemplatePowerPorts;
CREATE TABLE fac_TemplatePowerPorts (
  TemplateID int(11) NOT NULL,
  PortNumber int(11) NOT NULL,
  Label varchar(40) NOT NULL,
  PortNotes varchar(80) NOT NULL,
  PRIMARY KEY (TemplateID,PortNumber),
  UNIQUE KEY LabeledPort (TemplateID,PortNumber,Label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Add Config item for appending the datacenter / cabinet to device lists 
--
INSERT INTO fac_Config set Parameter='AppendCabDC', Value='disabled', UnitOfMeasure='Enabled/Disabled', ValType='string', DefaultVal='disabled';

--
-- Extend fac_PowerSource table for more load options to match CDUs
-- 
ALTER TABLE fac_PowerSource ADD OID2 VARCHAR( 80 ) NOT NULL AFTER LoadOID, ADD OID3 VARCHAR( 80 ) NOT NULL AFTER OID2;

--
-- Extend fac_Cabinet table for better sorting
--
ALTER TABLE fac_Cabinet ADD LocationSortable VARCHAR( 20 ) NOT NULL AFTER Location;
UPDATE fac_Cabinet SET LocationSortable = REPLACE(Location, ' ', '');

--
-- Add a failure counter to all devices to keep track of whether or not they've gone silent
--
ALTER TABLE fac_Device ADD SNMPFailureCount TINYINT(1) NOT NULL AFTER SNMPCommunity;

--
-- Extend fac_CabRow table to allow for rows directly in a datacenter not just a zone
--
ALTER TABLE fac_CabRow ADD DataCenterID INT( 11 ) NOT NULL AFTER Name;
UPDATE fac_CabRow SET DataCenterID=(SELECT DataCenterID FROM fac_Zone WHERE fac_CabRow.ZoneID=fac_Zone.ZoneID);

--
-- Add some fields needed to keep the local database in sync (if enabled) with the global repository
--

ALTER TABLE fac_CDUTemplate ADD GlobalID int(11) NOT NULL;
ALTER TABLE fac_CDUTemplate ADD ShareToRepo tinyint(1) NOT NULL DEFAULT 0;
ALTER TABLE fac_CDUTemplate ADD KeepLocal tinyint(1) NOT NULL DEFAULT 0;

ALTER TABLE fac_DeviceTemplate ADD GlobalID int(11) NOT NULL;
ALTER TABLE fac_DeviceTemplate ADD ShareToRepo tinyint(1) NOT NULL DEFAULT 0;
ALTER TABLE fac_DeviceTemplate ADD KeepLocal tinyint(1) NOT NULL DEFAULT 0;

ALTER TABLE fac_Manufacturer ADD GlobalID int(11) NOT NULL;
ALTER TABLE fac_Manufacturer ADD ShareToRepo tinyint(1) NOT NULL DEFAULT 0;
ALTER TABLE fac_Manufacturer ADD KeepLocal tinyint(1) NOT NULL DEFAULT 0;

ALTER TABLE fac_SensorTemplate ADD GlobalID int(11) NOT NULL;
ALTER TABLE fac_SensorTemplate ADD ShareToRepo tinyint(1) NOT NULL DEFAULT 0;
ALTER TABLE fac_SensorTemplate ADD KeepLocal tinyint(1) NOT NULL DEFAULT 0;

INSERT INTO fac_Config set Parameter="ShareToRepo", Value="disabled", UnitOfMeasure="Enabled/Disabled", ValType="string", DefaultVal="disabled";
INSERT INTO fac_Config set Parameter="KeepLocal", Value="enabled", UnitOfMeasure="Enabled/Disabled", ValType="string", DefaultVal="enabled";
