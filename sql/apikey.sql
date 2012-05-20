-- API認証用テーブルを作成するSQL
--
-- 2009.03.15 Tanaka Ryuichi
-- 2009.07.12 Tanaka Ryuichi 更新

-- MySQL版

-- あらかじめ以下のコマンドを実行しておく
-- create database apikey

DROP TABLE apikey;
DROP TABLE apimaster;

CREATE TABLE apikey (
	id int auto_increment PRIMARY KEY,
	domain text NOT NULL,
	date timestamp NOT NULL,
	apikey varchar(64) UNIQUE NOT NULL,
	api_id int NOT NULL
);

CREATE TABLE apimaster (
	id int auto_increment PRIMARY KEY,
	name varchar(15) NOT NULL
);

-- 順次追加
INSERT INTO apimaster (name) VALUES ('TMAP');
INSERT INTO apimaster (name) VALUES ('tcliper');

-- PostgreSQL版

-- あらかじめ以下のコマンドを実行しておく
-- createdb apikey

-- DROP TABLE apikey;
-- DROP TABLE apimaster;

-- CREATE TABLE apikey (
-- 	id serial PRIMARY KEY,
-- 	domain text NOT NULL,
-- 	date timestamp NOT NULL,
-- 	apikey text UNIQUE NOT NULL,
-- 	api_id int NOT NULL
-- );

-- GRANT ALL ON apikey TO postgres;

-- CREATE TABLE apimaster (
-- 	id serial PRIMARY KEY,
-- 	name varchar(15) NOT NULL
-- );

-- 順次追加
-- INSERT INTO apimaster (name) VALUES ('TMAP');
-- INSERT INTO apimaster (name) VALUES ('Trush cliper');

-- GRANT ALL ON apimaster TO postgres;
