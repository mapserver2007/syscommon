#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use CGI;
use JSON::Syck qw/Dump/;
use FindBin::libs qw{ export base=syscommon };
use MyLibs::Common::Util::Upload;
use MyLibs::Common::Util::Thumbnail;
use MyLibs::Common::DB::Config;
use MyLibs::Common::DB::Schema;

# diary4_filearchives2テーブルにInsertするテスト

my $fileinfo = {
	conv_filename => '1253431059.jpg',
	origin_filename => 'gununu_normal.jpg',
	date => '2009-09-20T16:17:39Z',
	file_ext => 'jpg',
	file_size => 1182
};

### ここからDB登録処理 ###
# 使用するDBMSを指定(mysql or pgsql)
my $dbms = "mysql";

# データベース名を指定
my $dbname = "diarysys";

# スキーマファイル名を指定
my $schema_name = "Diary4Filearchives2";

# DBの接続設定を取得
my ($conf_obj, $db_conf);
$conf_obj = MyLibs::Common::DB::Config->new();
$conf_obj->use_db($dbms);
$db_conf = $conf_obj->get_db_config();

## ORマッピング開始
my $connect_info = ["dbi:$db_conf->{dbms}:dbname=$dbname;host=$db_conf->{host}", $db_conf->{user}, $db_conf->{pass}];
my $schema = MyLibs::Common::DB::Schema->connect(@{$connect_info});
$schema->storage->dbh->do("SET names utf8");

my $result = $schema->resultset($schema_name)->create({
	filename => $fileinfo->{conv_filename},
	original_filename => $fileinfo->{origin_filename},
	date => $fileinfo->{date},
	filetype => $fileinfo->{file_ext},
	filesize => $fileinfo->{file_size},
	comment => ''
});

print "ok";