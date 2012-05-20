#!/usr/bin/perl
use strict;
use warnings;
use FindBin::libs qw{ export base=syscommon };
use MyLibs::Diarysys::Service::Amazon;
use Time::HiRes;

my $st = Time::HiRes::time;

my $amazon = MyLibs::Diarysys::Service::Amazon->new({
	key => "",
	secret => "",
	keyword => "Ruby",
	callback => "",
	cache_file => "C:/workspace/cache.db",
	ttl => 10000
});

print $amazon->get_data();
print "\n";

my $ed = Time::HiRes::time;


# 計測結果
print "### 開始時刻：" . $st . "\n";
print "### 終了時刻：" . $ed . "\n";
print "### 実行時間：";
printf("%5.3f(sec)\n", $ed - $st);