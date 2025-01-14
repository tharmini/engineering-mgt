
-- MySQL dump 10.13  Distrib 8.0.16, for macos10.14 (x86_64)
--
-- Host: localhost    Database: WSO2_ORGANIZATION_DETAILS
-- ------------------------------------------------------
-- Server version	8.0.16


--
-- Table structure for table `ENGAPP_GITHUB_ISSUES`
--

DROP TABLE IF EXISTS `ENGAPP_GITHUB_ISSUES`;
CREATE TABLE `ENGAPP_GITHUB_ISSUES` (
  `ISSUE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GITHUB_ID` varchar(45) NOT NULL,
  `REPOSITORY_ID` int(11) NOT NULL,
  `CREATED_DATE` datetime DEFAULT NULL,
  `UPDATED_DATE` datetime DEFAULT NULL,
  `CLOSED_DATE` datetime DEFAULT NULL,
  `CREATED_BY` varchar(100) NOT NULL,
  `ISSUE_TYPE` varchar(100) NOT NULL,
  `HTML_URL` varchar(500) DEFAULT NULL,
  `LABELS` varchar(500) DEFAULT NULL,
  `ASSIGNEES` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`ISSUE_ID`)
  );

--
-- Dumping data for table `ENGAPP_GITHUB_ISSUES`
--

-- Table structure for table `ENGAPP_GITHUB_ORGANIZATIONS`
--

DROP TABLE IF EXISTS `ENGAPP_GITHUB_ORGANIZATIONS`;
CREATE TABLE `ENGAPP_GITHUB_ORGANIZATIONS` (
  `ORG_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GITHUB_ID` varchar(50) NOT NULL,
  `ORG_NAME` varchar(100) NOT NULL,
  PRIMARY KEY (`ORG_ID`)
  );

--
-- Dumping data for table `ENGAPP_GITHUB_ORGANIZATIONS`
--


--
-- Table structure for table `ENGAPP_GITHUB_REPOSITORIES`
--

DROP TABLE IF EXISTS `ENGAPP_GITHUB_REPOSITORIES`;
CREATE TABLE `ENGAPP_GITHUB_REPOSITORIES` (
  `REPOSITORY_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GITHUB_ID` varchar(50) NOT NULL,
  `REPOSITORY_NAME` varchar(150) NOT NULL,
  `ORG_ID` int(11) NOT NULL,
  `URL` varchar(150) NOT NULL,
  `TEAM_ID` int(11) NOT NULL,
  PRIMARY KEY (`REPOSITORY_ID`)
  );

--
-- Dumping data for table `ENGAPP_GITHUB_REPOSITORIES`
--


--
-- Table structure for table `ENGAPP_GITHUB_TEAMS`
--

DROP TABLE IF EXISTS `ENGAPP_TEAMS`;
CREATE TABLE `ENGAPP_TEAMS` (
  `TEAM_ID` int(11) NOT NULL,
  `TEAM_NAME` varchar(100) NOT NULL,
  `TEAM_ABBR` varchar(45) NOT NULL,
  PRIMARY KEY (`TEAM_ID`)
);
--
-- Dumping data for table `ENGAPP_TEAMS`
--


--
-- Table structure for table `ENGAPP_ISSUE_COUNT`
--

DROP TABLE IF EXISTS `ENGAPP_ISSUE_COUNT`;
CREATE TABLE `ENGAPP_ISSUE_COUNT` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `DATE` date NOT NULL,
  `OPEN_ISSUES` int(11) NOT NULL DEFAULT '0',
  `CLOSED_ISSUES` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`)
);
--
-- Dumping data for table `ENGAPP_ISSUE_COUNT`
--


-- Dump completed on 2019-10-25 15:35:37
