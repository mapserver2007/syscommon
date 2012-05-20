<?php
/**
 * 全コンテンツ共通処理
 * @author   Ryuichi TANAKA
 * @version  2008/12/18
 * 対象システム
 * ・DIARYSYS4
 * ・TMAP3
 * ・TMAP　API2
 * ・(SEARCHSYS4fx：今後対応予定)
 * ・chocolab
 * ・SVNリポジトリ
 * ・tcliper
 * ・tmarker
 */

//共通グローバル変数
define('__CONFIG__', '/usr/local/apache2/htdocs/syscommon/common.ini');

//コンテンツヘッダ出力
function common_header(){

	$link = "<div class=\"syscommon_h\">";

	if(!file_exists(__CONFIG__)){
		echo __CONFIG__ . " not found.";
		return false;
	}
	$config_ini = parse_ini_file(__CONFIG__, true);
	foreach($config_ini as $key => $val){
		if($key == "common"){
			$host1    = $val['host1'];
			$host2    = $val['host2'];
			$doc_root = $val['doc_root'];
			if(!$host1 || !$host2){
				die("HOST URL not found.");
			}
			if(!$doc_root){
				die("DOCUMENT ROOT not found.");
			}
			continue;
		}
		$url = "http://";
		if($val['uri_location']){
			$url .= $host1 . $val['uri_location'];
		}
		if($val['uri_subdomain']){
			$url .= $val['uri_subdomain'] . "." . $host2;
		}

		$link .= "<a href=\"" . $url . "\">";
		$link .= $val['uri_text'];
		$link .= "</a> | ";
		/*
		if(!file_exists($doc_root . $val['uri_location'])){
			echo "NOT FOUND";
		}else{
			$link .= "<a href=\"" . $host . $val['uri_location'] . "\">";
			$link .= $val['uri_text'];
			$link .= "</a> | ";
		}
		*/
	}
	$link = substr($link, 0, -2);
	$link .= "</div>";

	echo $link;
}

//コンテンツフッタ出力
function common_footer(){
	$link = "<div class=\"syscommon_f\">Copyright &copy; 2004-2010 summer-lights All Rights Reserved</div>";
	echo $link;
}

?>