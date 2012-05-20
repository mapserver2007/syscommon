#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use FindBin::libs qw{ export base=syscommon };
use Common::DB;
use Common::ApiAuth;
use TrushCliper::DB;

# 認証処理
sub exec_auth {
	my ($apikey, $referer) = @_;
	
	# API認証開始
	my $auth = Common::ApiAuth->new({
		"apikey" => $apikey,
		"referer" => $referer
	});
	
	# API認証失敗時のエラーハンドリング
	if(!$auth->execAuthentication()){
		print "authorization failed";
		exit;
	};
	
	return;
}

# DB登録処理
sub exec_db {
	my ($title, $url, $comment) = @_;
	my ($sql, @bind);
	my $msg = "";
	my $db = TrushCliper::DB->new();
	
	# 日付を取得
	my ($sec, $min, $hour, $day, $month, $year) = (localtime(time))[0..5];
	$year += 1900;
	$month += 1;
	my $date = $year . "-" . $month . "-" . $day . " " . $hour . ":" . $min . ":" . $sec;
	
	# DB接続
	$db->DBConnect();
	
	# 登録処理
	$sql = "INSERT INTO tclipers (title, url, comment, date) ";
	$sql.= "VALUES (?, ?, ?, ?)";
	@bind = ($title, $url, $comment, $date);
	
	eval{ $db->register($sql, @bind); };
	if($@){
		# Duplicate entry error
		if($DBI::err == 1062){
			$msg = "already clip this site!";
		}
		else{
			$msg = "unknown error!";
		}
	}
	else{
		# Register success
		$msg = "clip complete!";
	}

	# DB切断
	$db->DBClose();
	
	return $msg;
}

# CGI開始
my $cgi = new CGI;
print $cgi->header(-type=>"text/html", -charset=>"utf-8");

# POSTデータを取得
my $title   = $cgi->param("title");
my $url     = $cgi->param("url");
my $comment = $cgi->param("comment");
my $apikey  = $cgi->param("apikey");
my $referer = $cgi->referer();

#　認証処理
exec_auth($apikey, $referer);

# DB処理
my $result = exec_db($title, $url, $comment);

print $result;