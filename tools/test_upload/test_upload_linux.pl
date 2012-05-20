#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use CGI;
use JSON::Syck qw/Dump/;
use FindBin::libs qw{ export base=syscommon };
use MyLibs::Common::Util::Upload;
use MyLibs::Common::Util::Thumbnail;

my $save_path = '/usr/local/apache2/htdocs/syscommon/tools/test_upload/upload/';
my $save_path_thumbnail = '/usr/local/apache2/htdocs/syscommon/tools/test_upload/thumbnail/';
my $cgi = new CGI;
my $callback = $cgi->escapeHTML($cgi->param('callback')) || "test_callback";
print $cgi->header(-type=>"text/html", -charset => 'utf-8');

# ここからUpload処理
my $upload = MyLibs::Common::Util::Upload->new({
	save_path => $save_path
});

unless ($upload->save()) {
	print $callback . '(' . JSON::Syck::Dump($upload->get_error()) . ');';
	exit;
}

my $fileinfo = $upload->get_fileinfo();

#print Dumper $fileinfo;

# ここからサムネイル生成処理
my $thumbnail = MyLibs::Common::Util::Thumbnail->new({
	image_path => $fileinfo->{save_filepath}, # 必須、間違い不可
	save_path => $save_path_thumbnail, # 必須、間違い不可
	#size_x => 15,
	#size_y => 15, # size_x、size_yどちらかが指定してあればOK。片方省略時は比率を維持
	percentage => 0.5, # 最大1、最小0.0..01、縦横比維持、size_x or size_yとの併用不可、size_x,size_y優先
});

unless ($thumbnail->save()) {
	print $callback . '(' . JSON::Syck::Dump($thumbnail->get_error()) . ');';
	exit;
}

print "ok";


# ここにDB登録処理