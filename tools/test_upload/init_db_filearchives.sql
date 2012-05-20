drop table if exists diary4_filearchives;
create table diary4_filearchives (
	id int not null auto_increment primary key,
	filename varchar(15) not null,
	original_filename text not null,
	date datetime not null,
	filetype varchar(4) not null,
	filesize int not null,
	comment text
);