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

print $cgi->header(-type=>"application/x-javascript", -charset=>"utf-8");

my $ua = LWP::UserAgent->new();
my $res = $ua->get($url);
print $res->content;

print "\n";
my $ed = Time::HiRes::time;

# 計測結果
print "### 開始時刻：" . $st . "\n";
print "### 終了時刻：" . $ed . "\n";
print "### 実行時間：";
printf("%5.3f(sec)\n", $ed - $st);