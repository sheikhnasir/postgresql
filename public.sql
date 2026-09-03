/*
 Navicat Premium Dump SQL

 Source Server         : localhost
 Source Server Type    : PostgreSQL
 Source Server Version : 180004 (180004)
 Source Host           : localhost:5432
 Source Catalog        : developer_lab
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 180004 (180004)
 File Encoding         : 65001

 Date: 22/07/2026 21:23:40
*/


-- ----------------------------
-- Sequence structure for employee_empid_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."employee_empid_seq";
CREATE SEQUENCE "public"."employee_empid_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for users_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."users_id_seq";
CREATE SEQUENCE "public"."users_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 2147483647
START 1
CACHE 1;

-- ----------------------------
-- Table structure for Address
-- ----------------------------
DROP TABLE IF EXISTS "public"."Address";
CREATE TABLE "public"."Address" (
  "addid" int4 NOT NULL,
  "address1" varchar(255) COLLATE "pg_catalog"."default",
  "address2" varchar(255) COLLATE "pg_catalog"."default",
  "poscode" varchar(8) COLLATE "pg_catalog"."default",
  "state" varchar(40) COLLATE "pg_catalog"."default",
  "country" varchar(60) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of Address
-- ----------------------------
INSERT INTO "public"."Address" VALUES (1, 'XXXX', 'XXXX', '60000', 'SELANGOR', 'MALAYSIA');
INSERT INTO "public"."Address" VALUES (2, 'YYYY', 'YYYY', '80000', 'SARAWAK', 'MALAYSIA');
INSERT INTO "public"."Address" VALUES (3, 'ZZZZ', 'ZZZZ', '12000', 'PERLIS', 'MALAYSIA');

-- ----------------------------
-- Table structure for employee
-- ----------------------------
DROP TABLE IF EXISTS "public"."employee";
CREATE TABLE "public"."employee" (
  "empid" int8 NOT NULL DEFAULT nextval('employee_empid_seq'::regclass),
  "name" text COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of employee
-- ----------------------------
INSERT INTO "public"."employee" VALUES (1, 'ali');
INSERT INTO "public"."employee" VALUES (2, 'danny');

-- ----------------------------
-- Table structure for hasaddress
-- ----------------------------
DROP TABLE IF EXISTS "public"."hasaddress";
CREATE TABLE "public"."hasaddress" (
  "empid" int8 NOT NULL DEFAULT nextval('employee_empid_seq'::regclass),
  "addid" int4 NOT NULL,
  "status" bool,
  "startdate" date NOT NULL,
  "enddate" date
)
;

-- ----------------------------
-- Records of hasaddress
-- ----------------------------
INSERT INTO "public"."hasaddress" VALUES (1, 1, 't', '2026-07-22', NULL);
INSERT INTO "public"."hasaddress" VALUES (1, 3, 't', '2026-07-22', NULL);

-- ----------------------------
-- Table structure for test
-- ----------------------------
DROP TABLE IF EXISTS "public"."test";
CREATE TABLE "public"."test" (
  "id" int8 NOT NULL,
  "name" text COLLATE "pg_catalog"."default",
  "email" text[] COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of test
-- ----------------------------
INSERT INTO "public"."test" VALUES (1, 'danny', '{danny@yahoo.com,test@gmail.com}');

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS "public"."users";
CREATE TABLE "public"."users" (
  "id" int4 NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  "name" text COLLATE "pg_catalog"."default",
  "emails" text[] COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO "public"."users" VALUES (1, 'aaa', NULL);
INSERT INTO "public"."users" VALUES (4, 'Danny', '{danny@gmail.com,danny@company.com}');
INSERT INTO "public"."users" VALUES (3, 'ddd', '{test}');
INSERT INTO "public"."users" VALUES (2, 'eee', '{test}');

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."employee_empid_seq"
OWNED BY "public"."employee"."empid";
SELECT setval('"public"."employee_empid_seq"', 1, false);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."users_id_seq"
OWNED BY "public"."users"."id";
SELECT setval('"public"."users_id_seq"', 4, true);

-- ----------------------------
-- Primary Key structure for table Address
-- ----------------------------
ALTER TABLE "public"."Address" ADD CONSTRAINT "Addres_pkey" PRIMARY KEY ("addid");

-- ----------------------------
-- Primary Key structure for table employee
-- ----------------------------
ALTER TABLE "public"."employee" ADD CONSTRAINT "employee_pkey" PRIMARY KEY ("empid");

-- ----------------------------
-- Primary Key structure for table hasaddress
-- ----------------------------
ALTER TABLE "public"."hasaddress" ADD CONSTRAINT "hasaddress_pkey" PRIMARY KEY ("empid", "addid", "startdate");

-- ----------------------------
-- Primary Key structure for table test
-- ----------------------------
ALTER TABLE "public"."test" ADD CONSTRAINT "test_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table users
-- ----------------------------
ALTER TABLE "public"."users" ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Foreign Keys structure for table hasaddress
-- ----------------------------
ALTER TABLE "public"."hasaddress" ADD CONSTRAINT "hasaddress_addid_fkey" FOREIGN KEY ("addid") REFERENCES "public"."Address" ("addid") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "public"."hasaddress" ADD CONSTRAINT "hasaddress_empid_fkey" FOREIGN KEY ("empid") REFERENCES "public"."employee" ("empid") ON DELETE CASCADE ON UPDATE CASCADE;
