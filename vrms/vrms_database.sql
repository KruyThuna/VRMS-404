-- ============================================================================
-- Vehicle Rental Management System (VRMS)
-- Database Name: vrms
-- Target RDBMS: MySQL 8.0+ / MariaDB 10.5+
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `vrms`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE `vrms`;

-- Temporarily disable foreign key checks during schema rebuild
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- Drop existing tables (clean install)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `banneritem_specchips`;
DROP TABLE IF EXISTS `banners`;
DROP TABLE IF EXISTS `rentals`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `vehicles`;
DROP TABLE IF EXISTS `rental_inquiries`;
DROP TABLE IF EXISTS `agency_config`;
DROP TABLE IF EXISTS `vehicle`; -- legacy table cleanup if present

-- ----------------------------------------------------------------------------
-- Table 1: `vehicles`
-- Represents the fleet of vehicles available for rent.
-- ----------------------------------------------------------------------------
CREATE TABLE `vehicles` (
  `id` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `brand` VARCHAR(255) NOT NULL,
  `type` VARCHAR(255) NOT NULL,
  `dailyCents` INT NOT NULL,
  `purchasePrice` INT NOT NULL,
  `available` BIT(1) NOT NULL DEFAULT b'1',
  `fuel` VARCHAR(255) DEFAULT NULL,
  `seats` INT NOT NULL DEFAULT 5,
  `transmission` VARCHAR(255) DEFAULT NULL,
  `engine` VARCHAR(255) DEFAULT NULL,
  `horsepower` VARCHAR(255) DEFAULT NULL,
  `topSpeed` VARCHAR(255) DEFAULT NULL,
  `acceleration` VARCHAR(255) DEFAULT NULL,
  `imageUrl` VARCHAR(2048) DEFAULT NULL,
  `maintenance` BIT(1) NOT NULL DEFAULT b'0',
  `tagline` VARCHAR(255) DEFAULT NULL,
  `year` INT DEFAULT 2024,
  `plate` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_vehicles_available` (`available`),
  INDEX `idx_vehicles_type` (`type`),
  INDEX `idx_vehicles_brand` (`brand`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- Table 2: `customers`
-- Stores verified customer identities, contact info, and rental history stats.
-- ----------------------------------------------------------------------------
CREATE TABLE `customers` (
  `id` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(255) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `driverLicense` VARCHAR(255) DEFAULT NULL,
  `nationalId` VARCHAR(255) DEFAULT NULL,
  `totalSpentCents` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  INDEX `idx_customers_phone` (`phone`),
  INDEX `idx_customers_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- Table 3: `rentals`
-- Tracks rental bookings, overdue status, daily rate, and vehicle return state.
-- ----------------------------------------------------------------------------
CREATE TABLE `rentals` (
  `id` VARCHAR(255) NOT NULL,
  `vehicleId` VARCHAR(255) DEFAULT NULL,
  `customerId` VARCHAR(255) DEFAULT NULL,
  `startDate` DATE DEFAULT NULL,
  `endDate` DATE DEFAULT NULL,
  `dailyCents` INT NOT NULL,
  `paidCents` INT NOT NULL DEFAULT 0,
  `returned` BIT(1) NOT NULL DEFAULT b'0',
  `status` VARCHAR(255) DEFAULT 'Active',
  `notes` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_rentals_vehicleId` (`vehicleId`),
  INDEX `idx_rentals_customerId` (`customerId`),
  INDEX `idx_rentals_status` (`status`),
  INDEX `idx_rentals_returned` (`returned`),
  CONSTRAINT `fk_rentals_vehicle` FOREIGN KEY (`vehicleId`) REFERENCES `vehicles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rentals_customer` FOREIGN KEY (`customerId`) REFERENCES `customers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- Table 4: `banners`
-- Promotional hero banners showcased on the client app landing page.
-- ----------------------------------------------------------------------------
CREATE TABLE `banners` (
  `id` VARCHAR(255) NOT NULL,
  `tagline` VARCHAR(255) DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `subtitle` VARCHAR(255) DEFAULT NULL,
  `vehicleId` VARCHAR(255) DEFAULT NULL,
  `imageUrl` VARCHAR(2048) DEFAULT NULL,
  `priceText` VARCHAR(255) DEFAULT NULL,
  `badgeText` VARCHAR(255) DEFAULT NULL,
  `badgeColorValue` BIGINT NOT NULL DEFAULT 4279310657,
  `active` BIT(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`id`),
  INDEX `idx_banners_vehicleId` (`vehicleId`),
  CONSTRAINT `fk_banners_vehicle` FOREIGN KEY (`vehicleId`) REFERENCES `vehicles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- Table 5: `banneritem_specchips`
-- Key specification chips attached to promotional hero banners.
-- ----------------------------------------------------------------------------
CREATE TABLE `banneritem_specchips` (
  `BannerItem_id` VARCHAR(255) NOT NULL,
  `specChips` VARCHAR(255) DEFAULT NULL,
  INDEX `idx_specchips_banner` (`BannerItem_id`),
  CONSTRAINT `fk_specchips_banner` FOREIGN KEY (`BannerItem_id`) REFERENCES `banners` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- Table 6: `rental_inquiries`
-- Inquiries sent from users or visitors regarding vehicle reservations.
-- ----------------------------------------------------------------------------
CREATE TABLE `rental_inquiries` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) DEFAULT NULL,
  `phone` VARCHAR(255) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `vehicleName` VARCHAR(255) DEFAULT NULL,
  `message` TEXT DEFAULT NULL,
  `createdAt` DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- Table 7: `agency_config`
-- Brand profile, emergency contact, headquarters address, and store settings.
-- ----------------------------------------------------------------------------
CREATE TABLE `agency_config` (
  `id` VARCHAR(255) NOT NULL,
  `companyName` VARCHAR(255) DEFAULT 'DriveLine',
  `companySlogan` VARCHAR(255) DEFAULT 'CAR RENTAL',
  `phone` VARCHAR(255) DEFAULT '+855 23 999 888',
  `email` VARCHAR(255) DEFAULT 'booking@driveline-rental.com',
  `address` VARCHAR(255) DEFAULT 'Phnom Penh & Siem Reap, Cambodia',
  `logoUrl` VARCHAR(2048) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Re-enable foreign key constraints
SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================================
-- SEED DATA INSERTION
-- Populates default vehicles, customers, banners, specs, and agency config.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Insert Vehicles
-- ----------------------------------------------------------------------------
INSERT INTO `vehicles` (
  `id`, `name`, `brand`, `type`, `dailyCents`, `purchasePrice`,
  `available`, `fuel`, `seats`, `transmission`, `engine`, `horsepower`,
  `topSpeed`, `acceleration`, `imageUrl`, `maintenance`, `tagline`, `year`, `plate`
) VALUES
(
  'v_tiggo9', 'Chery Tiggo 9', 'Chery', 'SUV', 5500, 34500,
  b'1', 'Petrol Turbo', 7, '8-Speed AT', '2.0L TGDI Turbo', '261 HP',
  '205 KM/H', '7.5s', 'assets/images/tiggo9_banner.png', b'0', 'ONE STEP AHEAD', 2025, '2BK-9988'
),
(
  'v0', 'Bugatti La Voiture Noire', 'Bugatti', 'Hypercar', 95000, 11000000,
  b'1', 'Quad-Turbo W16', 2, '7-Speed Dual-Clutch', '8.0L W16 Quad-Turbo', '1500 HP',
  '420 KM/H', '2.4s', 'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=1200&q=80', b'0', 'THE EXCLUSIVE MASTERPIECE', 2024, '1AA-0001'
),
(
  'v1', 'Toyota Fortuner', 'Toyota', 'SUV', 6500, 42000,
  b'1', 'Diesel', 7, 'Automatic', '2.8L Diesel', '201 HP',
  '180 KM/H', '9.8s', 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=1200&q=80', b'0', 'TOUGH & RELIABLE', 2023, '2AZ-4512'
),
(
  'v2', 'Toyota Land Cruiser', 'Toyota', 'SUV', 9500, 68000,
  b'0', 'Diesel Twin-Turbo', 7, 'Automatic', '3.3L V6 Twin-Turbo', '304 HP',
  '210 KM/H', '7.9s', 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=1200&q=80', b'0', 'KING OF THE ROAD', 2024, '2BA-8899'
),
(
  'v3', 'Porsche 911 GT3 RS', 'Porsche', 'Sports', 22000, 225000,
  b'1', 'Premium Gasoline', 2, '7-Speed PDK', '4.0L Naturally Aspirated Flat-6', '518 HP',
  '296 KM/H', '3.0s', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=80', b'0', 'TRACK WEAPON', 2024, '2BB-9111'
),
(
  'v5', 'Tesla Model 3 AWD', 'Tesla', 'Electric', 7500, 38900,
  b'1', 'Electric Dual Motor', 5, 'Single-Speed', 'Dual Electric Motors', '450 HP',
  '233 KM/H', '3.1s', 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=1200&q=80', b'0', 'THE ELECTRIC REVOLUTION', 2024, '2BC-3300'
),
(
  'v6', 'BMW 4 Series Gran Coupe', 'BMW', 'Luxury', 8500, 48000,
  b'1', 'Petrol TwinPower', 5, '8-Speed Steptronic', '2.0L TwinPower Turbo', '258 HP',
  '250 KM/H', '5.8s', 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=1200&q=80', b'0', 'THE ULTIMATE DRIVING MACHINE', 2023, '2BD-4422'
),
(
  'v7', 'Audi RS e-tron GT', 'Audi', 'Concept', 18000, 145000,
  b'0', 'All-Electric Quattro', 4, '2-Speed Automatic', 'Dual Permanent Magnet Motors', '637 HP',
  '250 KM/H', '3.1s', 'https://images.unsplash.com/photo-1614200187524-dc4b892acf16?w=1200&q=80', b'1', 'FUTURE IN MOTION', 2024, '2BE-7700'
);

-- ----------------------------------------------------------------------------
-- 2. Insert Customers
-- ----------------------------------------------------------------------------
INSERT INTO `customers` (
  `id`, `name`, `phone`, `email`, `driverLicense`, `nationalId`, `totalSpentCents`
) VALUES
('c1', 'Sokha Seng', '+855 12 345 678', 'sokha.seng@gmail.com', 'KH-9843210', '010293847', 4500),
('c2', 'Johnathan Miller', '+1 415 555 2671', 'j.miller@expats.com', 'US-CA-B849201', 'P982019482', 12500),
('c3', 'Chan Vannak', '+855 98 765 432', 'vannak.chan@outlook.com', 'KH-4521890', '010774829', 19500);

-- ----------------------------------------------------------------------------
-- 3. Insert Promotional Banners
-- ----------------------------------------------------------------------------
INSERT INTO `banners` (
  `id`, `tagline`, `title`, `subtitle`, `vehicleId`,
  `imageUrl`, `priceText`, `badgeText`, `badgeColorValue`, `active`
) VALUES
(
  'b_tiggo9', 'ONE STEP AHEAD', 'TIGGO 9', 'Chery Flagship Luxury 7-Seat Intelligent AWD SUV',
  'v_tiggo9', 'assets/images/tiggo9_banner.png', '$55 / DAY • FULL INSURANCE', 'CHERY FLAGSHIP', 4279310657, b'1'
),
(
  'b_bugatti', 'THE EXCLUSIVE MASTERPIECE', 'LA VOITURE NOIRE', '1-of-1 Bespoke Carbon Hypercar • 1500 HP W16 Quad-Turbo',
  'v0', 'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=1200&q=80', '$950 / DAY • VIP CHAUFFEUR & INSURANCE', 'HYPERCAR ICON', 4293200148, b'1'
),
(
  'b_tesla', 'THE ELECTRIC REVOLUTION', 'MODEL 3 AWD', 'Instant Torque Dual Motor • Autopilot Enabled Cockpit',
  'v5', 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=1200&q=80', '$75 / DAY • FREE CHARGING & GPS', 'ZERO EMISSIONS', 4280738516, b'1'
),
(
  'b_bmw', 'THE ULTIMATE DRIVING MACHINE', 'BMW 4 SERIES', 'TwinPower Turbo Performance • M Sport Aerodynamics',
  'v6', 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=1200&q=80', '$85 / DAY • AIRPORT PICKUP & INSURANCE', 'M SPORT LUXURY', 4280640491, b'1'
);

-- ----------------------------------------------------------------------------
-- 4. Insert Banner Spec Chips
-- ----------------------------------------------------------------------------
INSERT INTO `banneritem_specchips` (`BannerItem_id`, `specChips`) VALUES
('b_tiggo9', '2.0L TGDI TURBO · 261 HP'),
('b_tiggo9', '8-SPEED AT · INTELLIGENT AWD'),
('b_tiggo9', 'CDC SUSPENSION'),
('b_tiggo9', '7-SEAT LUXURY'),
('b_bugatti', '8.0L W16 QUAD-TURBO · 1500 CV'),
('b_bugatti', '0-100 IN 2.5 SEC · 420 KM/H'),
('b_bugatti', 'FULL CARBON MONOCOQUE'),
('b_bugatti', '1 OF 1 WORLDWIDE'),
('b_tesla', 'DUAL MOTOR AWD · 450 CV'),
('b_tesla', '0-100 IN 3.1 SEC'),
('b_tesla', 'AUTOPILOT COCKPIT'),
('b_tesla', 'SUPERCHARGING'),
('b_bmw', '2.0L TWINPOWER · 258 CV'),
('b_bmw', '0-100 IN 5.8 SEC · 250 KM/H'),
('b_bmw', 'M SPORT AERODYNAMICS'),
('b_bmw', 'HARMAN KARDON AUDIO');

-- ----------------------------------------------------------------------------
-- 5. Insert Rentals (Demonstrates Active, Overdue Unpaid, and Completed Returns)
-- ----------------------------------------------------------------------------
INSERT INTO `rentals` (
  `id`, `vehicleId`, `customerId`, `startDate`, `endDate`,
  `dailyCents`, `paidCents`, `returned`, `status`, `notes`
) VALUES
(
  'R-DEMO', 'v1', 'c1', '2026-10-15', '2026-10-20',
  6500, 6500, b'0', 'Active', 'VIP Concierge rental and airport handover.'
),
(
  'R-1001', 'v2', 'c2', '2026-10-08', '2026-10-14',
  9500, 4000, b'0', 'Overdue', 'Customer notified. Pending overdue return check-in with unpaid balance.'
),
(
  'R-1002', 'v6', 'c3', '2026-10-01', '2026-10-05',
  8500, 34000, b'1', 'Completed', 'Vehicle safely inspected and returned on time.'
);

-- ----------------------------------------------------------------------------
-- 6. Insert Agency Configuration
-- ----------------------------------------------------------------------------
INSERT INTO `agency_config` (
  `id`, `companyName`, `companySlogan`, `phone`, `email`, `address`, `logoUrl`
) VALUES
(
  'default',
  'DriveLine',
  'CAR RENTAL',
  '+855 23 999 888',
  'booking@driveline-rental.com',
  'Phnom Penh & Siem Reap, Cambodia',
  NULL
);

-- ----------------------------------------------------------------------------
-- 7. Insert Sample Rental Inquiry
-- ----------------------------------------------------------------------------
INSERT INTO `rental_inquiries` (
  `name`, `phone`, `email`, `vehicleName`, `message`, `createdAt`
) VALUES
(
  'Dara Som',
  '+855 10 888 777',
  'dara.som@gmail.com',
  'Chery Tiggo 9',
  'Interested in renting the 7-seat Tiggo 9 for a family road trip to Siem Reap next weekend.',
  NOW()
);
