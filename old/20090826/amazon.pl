#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use LWP::UserAgent;
use XML::Simple;
use Encode;
use JSON;
use Data::Dumper;

# 定数定義
use constant KEY => "";
use constant URL => "http://ecs.amazonaws.jp/onca/xml?";

# CGI開始
my $cgi = new CGI();
print $cgi->header(-type=>"text/html", -charset=>"utf-8");

# GETデータ取得
my $qstr  = encode("utf8", $cgi->param("query")) || exit;
my $qkind = $cgi->param("qkind") || exit;
my $query = {
	"title" => $qkind eq "aws_title" ? $qstr : "",
	"author" => $qkind eq "aws_author" ? $qstr : ""
};
my $callback = $cgi->param("callback") || "call";

# AMAZONのNoImage画像の定義
my $noimage = sub {
	my $kind = shift;
	my $image = {
		"small" => {
			"url" => "http://ec1.images-amazon.com/images/G/09/x-locale/detail/thumb-no-image.gif",
			"width" => 52,
			"height" => 75
		},
		"medium" => {
			"url" => "http://ec1.images-amazon.com/images/G/09/nav2/dp/no-image-no-ciu._SL100_.gif",
			"width" => 100,
			"height" => 100			
		},
		"large" => {
			"url" => "http://ec1.images-amazon.com/images/G/09/nav2/dp/no-image-no-ciu._AA250_.gif",
			"width" => 250,
			"height" => 250			
		}
	};
	return $image->{$kind};
};

# AMAZONのURLクエリ生成
my $aws_url = sub {
	my $q = shift;
	my $param = {
		"Service" => "AWSECommerceService",         # 必須
		"AWSAccessKeyId" => KEY,                    # 必須
		"Operation" => "ItemSearch",                # 検索を指定
		"SearchIndex" => "Books",                   # 本を指定(今後拡張も予定？)
		"Title" => $q->{"title"},                   # タイトル
		"Author" => $q->{"author"},                 # 著者
		"ResponseGroup" => "Images,ItemAttributes"  # 属性と画像を検索;
	};
	my $url = URL;
	foreach my $key (keys %{$param}){
		($url .= $key . "=" . $param->{$key} . "&") if ($param->{$key});
	}
	chop($url);
	return $url;
};

# AMAZONのXMLを取得
my $aws_xml = sub {
	my $url = shift;
	my $ua = LWP::UserAgent->new();
	my $res = $ua->get($url);
	$res->is_success or die "Can't connect to Amazon Web Service.";
	my $xml = $res->content;
	return $xml;
};

# XMLをハッシュに変換
my $xml2hash = sub {
	my $xml = shift;
	my $source = shift;
	# キー名の定義
	my @items_key = ("SmallImage", "MediumImage", "LargeImage");
	# XML->Hash
	my $hash = XMLin($xml);
	# 必要な個所を抜く
	my $require_data = $hash->{"Items"}->{"Item"};
	# 必要な情報を再構築
	my $key = $require_data ? scalar @{$require_data} : 0;
	# この配列に入れる
	my $books = [];
	
	for(my $i = 0; $i < $key; $i++){
		# 書籍の詳細データを取り出すことが可能な時
		my $parse = sub{
			my ($idx, $img_idx) = @_;
			my $kind = $items_key[$img_idx];
			my $image = "";

			if(scalar(keys(%{$require_data->[$idx]->{$kind}})) == 0){
				$image = {
					$noimage->("small")
				};				
			}else{			
				$image = {
					"url" => $require_data->[$idx]->{$kind}->{"URL"},
					"width" => $require_data->[$idx]->{$kind}->{"Width"}->{"content"},
					"height" => $require_data->[$idx]->{$kind}->{"Height"}->{"content"}
				};
			}
			return $image;
		};
		
		# データが複数ある場合は、連結して返す
		my $spliter = sub(){
			my $authors = shift;
			my $res = "";
			if(ref($authors) eq "ARRAY"){
				foreach my $value (@{$authors}){
					$res .= $value . "/";
				}
				chop($res);
			}else{
				$res = $authors;
			}
			return $res;
		};
		
		# 書籍データ完成
		my $book = {
			"Author" => $spliter->($require_data->[$i]->{"ItemAttributes"}->{"Author"}),
			"Title" => $require_data->[$i]->{"ItemAttributes"}->{"Title"},
			"Publisher" => $require_data->[$i]->{"ItemAttributes"}->{"Publisher"},
			"PublicationDate" => $require_data->[$i]->{"ItemAttributes"}->{"PublicationDate"},
			"Price" => {
				"Amount" => $require_data->[$i]->{"ItemAttributes"}->{"ListPrice"}->{"Amount"},
				"FormattedPrice" => $require_data->[$i]->{"ItemAttributes"}->{"ListPrice"}->{"FormattedPrice"}
			},
			"Image" => {
				"small" => $parse->($i, 0),
				"medium" => $parse->($i, 1),
				"large" => $parse->($i, 2)
 			},
 			"Detail" => $require_data->[$i]->{"DetailPageURL"},
 			"Source" => $source
		};
		push @$books, $book;
	}
	return $books;
};

# ハッシュをJSONに変換
my $hash2json = sub {
	my $hash = shift;
	return to_json($hash);
};

# URL取得
my $url = $aws_url->($query);
# XML取得
my $xml = $aws_xml->($url);
# 書籍データハッシュ取得
my $hash = $xml2hash->($xml, $url);
# 書籍データJSON取得
my $json = $hash2json->($hash);

print $callback . "(" . $json . ")";


