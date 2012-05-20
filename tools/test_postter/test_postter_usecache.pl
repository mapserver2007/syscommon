#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use LWP::UserAgent;
use FindBin::libs qw{ export base=syscommon };
use MyLibs::Common::Util::Cache;
use Time::HiRes;

my $st = Time::HiRes::time;
my $cgi = new CGI();
my $url = "http://friendfeed-api.com/v2/feed/mapserver2007";
my $callback = $cgi->escapeHTML($cgi->param('callback'));
my $cache_file = "C:/workspace/cache.db";
my $key = "friendfeed";
my $ttl = 6000;

print $cgi->header(-type=>"application/x-javascript", -charset=>"utf-8");

my $cache = MyLibs::Common::Util::Cache->new();
my $cache_data = $cache->load_cache($cache_file, $ttl, $key);
unless($cache_data){
	my $ua = LWP::UserAgent->new();
	my $res = $ua->get($url);
	$cache_data = $cache->create_cache($cache_file, $key, $res->content);
}

print $cache_data;

print "\n";

my $ed = Time::HiRes::time;


# 計測結果
print "### 開始時刻：" . $st . "\n";
print "### 終了時刻：" . $ed . "\n";
print "### 実行時間：";
printf("%5.3f(sec)\n", $ed - $st);