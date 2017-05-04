DROP DATABASE IF EXISTS `foo_db`;
CREATE DATABASE `foo_db`;
CREATE TABLE `foo_db`.`dogs` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE `foo_db`.`cats` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE `foo_db`.`schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
);

DROP DATABASE IF EXISTS `bar_db`;
CREATE DATABASE `bar_db`;
CREATE TABLE `bar_db`.`dogs` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE `bar_db`.`cats` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE `bar_db`.`schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
);

DROP DATABASE IF EXISTS `honk_db`;
CREATE DATABASE `honk_db`;
CREATE TABLE `honk_db`.`goudas` (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  PRIMARY KEY (`id`)
);
