package MyLibs::TMAP::API::AddressExtract;

{
	use Class::Std::Utils;
	use Encode;
	use Encode::Guess qw(euc-jp utf8 shiftjis);
	use JSON;
	use LWP::UserAgent;
	use HTML::TokeParser::Simple;
	use Geography::AddressExtract::Japan;
	use WebService::OkiLab::ExtractPlace;
	use encoding 'utf8';

	use constant EXTRACTER_OKI => "oki"; # WebService::OkiLab::ExtractPlaceで抽出
	use constant EXTRACTER_GAJ => "gaj"; # Geography::AddressExtract::Japanで抽出
	use constant LOCAL_DOMAIN => "summer-lights.dyndns.ws"; # ローカルドメイン

	my %request_query;  # リクエストクエリ(URLまたは文字列)

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;

		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;
		# メンバデータを初期化する
		$request_query{ident $obj} = $init_ref;

		return $obj;
	}

	# 抽出対象の文字列を整形or取得
	sub set_query {
		my ($self, $req) = @_;

		# URLか文字列かを判定
		$request_query{ident $self} = $req =~ /s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+/g
			? $self->get_remote_str($req) : decode(guess_encoding($req)->name, $req);

		return;
	}

	# リモートサイトから文字列を取得
	sub get_remote_str {
		my ($self, $url) = @_;
		my $strip_str = "";

		# 指定されたサイトはlocalhostに置換
		$url =~ s/LOCAL_DOMAIN/localhost/;

		# リモートサイトからHTMLを取得
		my $ua = LWP::UserAgent->new;
		my $res = $ua->request(HTTP::Request->new(GET => $url));
		my $str = decode(guess_encoding($res->content)->name, $res->content);

		# HTMLタグを除去
		my $p = HTML::TokeParser::Simple->new(\$str);
		while(my $token = $p->get_token){
			next unless $token->is_text;
			$strip_str .= $token->as_is;
		}

		return $strip_str;
	}

	# 経緯度を取得
	sub get_lnglat {
		my ($self, $mode, $callback) = @_;

		# 住所を抽出しJSONで返す
		my $addr = $mode eq EXTRACTER_OKI ? $self->extract_oki() : $self->extract_gaj();

		# コールバックがある場合はJSONPとして返す
		return $callback ? $callback . "(" . $addr . ")" : $addr;
	}

	# WebService::OkiLab::ExtractPlaceによる抽出
	sub extract_oki {
		my $self = shift;
		my $text = encode("utf8", $request_query{ident $self});  #UTF-8 Encode
		my $explace = WebService::OkiLab::ExtractPlace->new;
		my $result = $explace->extract($text);
		my @data = $result->{'result_select'}->[0];
		my $obj = [];
		my $i = 0;
		while(exists($data[0][$i])){
			if($data[0][$i]->{'type'} eq "address"){
				my $addr = $data[0][$i]->{'text'};
				$addr = decode('utf8', $addr);    # UTF-8 Decode
				my $addr_data = {
					id   => $i + 1,
					addr => $addr,
					lng  => $data[0][$i]->{'lng'},
					lat  => $data[0][$i]->{'lat'}
				};
				push @$obj, $addr_data;
			}
			$i++;
		}

		return to_json($obj);
	}

	# Geography::AddressExtract::Japanによる抽出
	sub extract_gaj {
		my $self = shift;

		my $result = Geography::AddressExtract::Japan->extract($request_query{ident $self});
		my $obj = [];
		my @data = map { $_->{"city"} . $_->{"aza"} . $_->{"number"}; }@{$result};
		foreach(@data){ push(@$obj, $_); }

		return to_json($obj);
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my ($self) = @_;

		delete $request_query{ident $self};

		return;
	}
}

1;