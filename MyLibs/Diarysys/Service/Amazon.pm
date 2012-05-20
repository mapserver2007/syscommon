package MyLibs::Diarysys::Service::Amazon;

{
	use strict;
	use warnings;
	use Class::Std::Utils;
	use FindBin::libs qw{ export base=syscommon };
	use base qw/MyLibs::Common::Util::Cache/;
	use URI;
	use URI::Escape;
	use LWP::UserAgent;
	use Encode qw/encode decode_utf8/;
	use Digest::SHA qw/hmac_sha256_base64/;
	use DateTime;
	use XML::Simple;
	use Data::Dumper;
	use JSON::Syck qw/Dump/;

	use constant API_URL => "http://webservices.amazon.co.jp/onca/xml";

	my %params;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;
		my $obj = bless \do{my $anon_scalar}, $class;
		$params{ident $obj} = $init_ref;
		return $obj;
	}

	# リクエストURL作成
	sub create_request_url {
		my $self = shift;
		my $uri = URI->new(API_URL);

		# 現在の時間を取得
		my $dt = DateTime->now(time_zone => 'Asia/Tokyo');
		my $timestamp = $dt->strftime('%Y-%m-%dT%H:%M:%SZ');

		# パラメータ定義
		my $q = {
			Service        => "AWSECommerceService",                        # 固定値
			AWSAccessKeyId => $params{ident $self}->{key},                  # アクセスキー
			Operation      => "ItemSearch",                                 # 商品検索
			SearchIndex    => "All",                                        # 全ての商品から
			Keywords       => decode_utf8($params{ident $self}->{keyword}), # キーワード
			ResponseGroup  => "Images,ItemAttributes",                      # 固定値
			Timestamp      => $timestamp,                                   # タイムスタンプ
			Version        => "2009-03-31"                                  # バージョン
		};

		# パラメータを昇順にソートして連結
		my $sq = join '&', map { $_ . '=' . URI::Escape::uri_escape_utf8( $q->{$_} ) if ($q->{$_}) } sort keys %{$q};

		# シグネチャを作成
		my $sig = join "\n", 'GET', $uri->host, $uri->path, $sq;
		$sig = Digest::SHA::hmac_sha256_base64($sig, $params{ident $self}->{secret});
		$sig .= '=' while length($sig) % 4;
		$sig = URI::Escape::uri_escape_utf8($sig);

		# AmazonのリクエストURL作成
		API_URL . qq/?$sq&Signature=$sig/;
	}

	# 画像データを返す
	sub get_book_image {
		my ($self, $elem, $size) = @_;

		# 画像のデータ構造を定義
		my $image_obj = {
			found => {
				url    => $elem->{$size}->{URL},
				width  => $elem->{$size}->{Width}->{content},
				height => $elem->{$size}->{Height}->{content}
			},
			not_found => {
				SmallImage => {
					url    => "http://ec1.images-amazon.com/images/G/09/x-locale/detail/thumb-no-image.gif",
					width  => 52,
					height => 75
				},
				MediumImage => {
					url    => "http://ec1.images-amazon.com/images/G/09/nav2/dp/no-image-no-ciu._SL100_.gif",
					width  => 100,
					height => 100
				},
				LargeImage => {
					url    => "http://ec1.images-amazon.com/images/G/09/nav2/dp/no-image-no-ciu._AA250_.gif",
					width  => 250,
					height => 250
				}
			}
		};

		return scalar(keys(%{$elem->{$size}})) == 0 ? $image_obj->{not_found}->{$size} : $image_obj->{found};
	}

	# 書籍データの要素を抽出する
	sub get_book_data {
		my ($self, $elem) = @_;

		my $e = $elem->{ItemAttributes};

		# UTF8にエンコード
		my $to_utf8 = sub { encode("utf8", shift); };

		# データが複数ある場合
		my $s = sub{
			my $elem = shift;
			ref($elem) eq "ARRAY" ? $to_utf8->(join "/", @$elem) : $to_utf8->($elem);
		};

		# 書籍データ取得
		my $book = {
			Author          => $s->($e->{Author}),
			Title           => $s->($e->{Title}),
			Publisher       => $s->($e->{Publisher}),
			PublicationDate => $e->{PublicationDate},
			Price => {
				Amount => $e->{ListPrice}->{Amount},
				FormattedPrice => $s->($e->{ListPrice}->{FormattedPrice})
			},
			Image => {
				small  => $self->get_book_image($elem, "SmallImage"),
				medium => $self->get_book_image($elem, "MediumImage"),
				large  => $self->get_book_image($elem, "LargeImage")
			},
			Detail => $elem->{DetailPageURL}
		};

		return $book;
	}

	# AmazonのJSONデータを取得する
	sub response_json {
		my ($self, $url) = @_;
		my $cache;

		# Amazonに問い合わせる
		my $get_json = sub {
			my $books = [];

			# AmazonデータのXMLを取得する
			my $ua = LWP::UserAgent->new();
			my $res = $ua->get($url);
			my $xml = $res->content if ($res->is_success);

			# Amazonデータをハッシュにする
			my $require_data = XMLin($xml)->{"Items"}->{"Item"};
			$require_data = [$require_data] if (ref($require_data) eq "HASH");

			for (@{$require_data}) { push @{$books}, $self->get_book_data($_); }

			# JSON化する
			JSON::Syck::Dump($books);
		};

		# キャッシュを有効にしているとき
		if ($params{ident $self}->{cache_file}){
			# キーを生成する
			my $sha = Digest::SHA->new(256);
			my $key = $sha->add($params{ident $self}->{keyword})->hexdigest;

			# キャッシュを取得する
			$cache = $self->load_cache(
				$params{ident $self}->{cache_file},
				$params{ident $self}->{ttl},
				$key
			);

			# キャッシュがない場合は作成する
			unless($cache){
				$cache = $self->create_cache(
					$params{ident $self}->{cache_file},
					$key,
					$get_json->()
				);
			}
		}
		# キャッシュを有効にしていない場合
		else {
			$cache = $get_json->();
		}

		return $cache;
	}

	# 書籍データのJSONを取得
	sub get_data {
		my $self = shift;

		# AmazonのリクエストURL取得
		my $url = $self->create_request_url();

		# AmazonのJSONを取得する
		return ($params{ident $self}->{callback} || "callback") . "(" . ($self->response_json($url)) . ");";
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my $self = shift;
		delete $params{ident $self};
		return;
	}
}

1;