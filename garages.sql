-- phpMyAdmin SQL Dump
-- version 4.5.1
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: 02 Iun 2017 la 19:20
-- Versiune server: 10.1.19-MariaDB
-- PHP Version: 7.0.13

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `database`
--

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `garages`
--

CREATE TABLE `garages` (
  `ID` int(11) NOT NULL DEFAULT '1',
  `Owner` varchar(24) DEFAULT NULL,
  `Owned` tinyint(4) NOT NULL DEFAULT '0',
  `eX` float NOT NULL DEFAULT '0',
  `eY` float NOT NULL DEFAULT '0',
  `eZ` float NOT NULL DEFAULT '0',
  `Price` int(11) NOT NULL DEFAULT '0',
  `Size` tinyint(4) NOT NULL
  `VirtualWorld` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
