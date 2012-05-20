#!/usr/bin/perl

#
# 一括でサムネイル生成するスクリプト(Linux用)
#

use strict;
use warnings;
use Data::Dumper;
use FindBin::libs qw{ export base=syscommon };
use MyLibs::Common::Util::Thumbnail;

# 画像一覧が保存されているディレクトリパス(ディレクトリ名は最後にスラッシュをつける。)
my $image_path = "/var/share/tmpdir/upload/";
# 保存するディレクトリパス(ディレクトリ名は最後にスラッシュをつける。)
my $thumbnail_path = "/var/share/tmpdir/upload/thumbnail/";

unless (-d $image_path) {
	print "Wrong path: $image_path";
	exit;
}

unless (-d $thumbnail_path) {
	print "Wrong path: $thumbnail_path";
	exit;
}

opendir(DIR, $image_path) or die "$!";

# ファイル一覧取得
for (readdir(DIR)) {
	# ファイルだけ処理
	my $filepath = $image_path . $_;
	if (-f $filepath) {
		my $thumbnail = MyLibs::Common::Util::Thumbnail->new({
			image_path => $filepath, # 必須、間違い不可
			dir_path => $thumbnail_path, # 必須、間違い不可
			#size_x => 15,
			#size_y => 25, # size_x、size_yどちらかが指定してあればOK。片方省略時は比率を維持
			size_auto => 75, # 縦横のサイズを自動検出して長いほうの辺のサイズに適用する。
			#percentage => 0.5, # 最大1、最小0.0..01、縦横比維持、size_x or size_yとの併用不可、size_x,size_y優先
		});
		unless ($thumbnail->save()) {
			print "Thumbnail image save failed!";
			exit;
		}
		else {
			print "[OK]\t$filepath\n";
		}
	}
}
