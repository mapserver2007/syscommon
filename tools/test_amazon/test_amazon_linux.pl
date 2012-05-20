#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use FindBin::libs qw{ export base=syscommon };
use MyLibs::Diarysys::Service::Amazon;

my $cgi = new CGI();
print $cgi->header(-type=>"application/x-javascript", -charset=>"utf-8");

my $amazon = MyLibs::Diarysys::Service::Amazon->new({
	key => "",
	secret => "",
	keyword => $cgi->escapeHTML($cgi->param('keyword')),
	callback => $cgi->escapeHTML($cgi->param('callback')),
	cache_file => "/usr/local/apache2/htdocs/syscommon/tools/cache/cache.db",
	ttl => 10000
});

print $amazon->get_data();
