#!/usr/bin/perl
use strict;
use warnings;
use FindBin::libs qw{ export base=syscommon };
use MyLibs::Common::DB::Config;
use DBIx::Class::Schema::Loader qw( make_schema_at );

# スキーマファイルの出力先
my $dump_directory = 'C:/workspace/syscommon';

# データベース名を指定
my $dbname = "tclipers";

my ($conf_obj, $db_conf);

$conf_obj = MyLibs::Common::DB::Config->new();
$conf_obj->use_db("mysql");
$db_conf = $conf_obj->get_db_config();

make_schema_at(
	'MyLibs::Common::DB::Schema',
	{relationships => 1, debug => 1, dump_directory => $dump_directory},
	["dbi:$db_conf->{dbms}:dbname=$dbname;host=$db_conf->{host}", $db_conf->{user}, $db_conf->{pass}]
);
