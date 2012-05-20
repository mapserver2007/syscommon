package MyLibs::TMAP::Blogeo::BlogRequest;

{
	use Class::Std::Utils;
	use Encode;

	use constant BLOG_SEARCH_URL => 'http://blog-search.yahoo.co.jp/search?ei=UTF-8&';
	use constant MAXIMUM_NUM => 30; # 最大検索件数
	use constant SORT => {fit => "gd", day => "dd"};

	my %request_list;  # リクエストURL、住所・住所コードのリスト
	my %request_url;   # リクエストURL
	my %request_addr;  # 住所、住所コード

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;

		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;

		# メンバデータを初期化する
		$request_list{ident $obj} = [];

		return $obj;
	}

	# リクエストURL生成のためのパラメータをセット
	sub setURLQuery {
		my ($self, $query_ref) = @_;
		my ($domain_num, $addr_num);
		my ($num, $page, $sort) = ($query_ref->{num}, 1, $query_ref->{sort});

		# 指定したブログドメインの個数を取得
		$domain_num = scalar(@{$query_ref->{domain}});

		# 指定した住所の個数を取得
		$addr_num = scalar(@{$query_ref->{addr}});

		# 指定したブログドメインと住所の個数毎にそれぞれURLを生成
		for(0..($domain_num - 1)){
			my $domain = $query_ref->{domain}->[$_];
			for(0..($addr_num -1)){
				my $addr = $query_ref->{addr}->[$_];

				# クエリURL生成
				my $url = $self->createURL({
					domain => $domain,
					addr   => $addr,
					num    => $num,
					page   => $page,
					sort   => $sort
				});

				# URLを取得
				$request_url{ident $self} = $url;

				# 結果をセットする
				push @{$request_list{ident $self}}, {url => $request_url{ident $self}, addr => $request_addr{ident $self}};
			}
		}
	}

	# スクレイプ対象のURLのリストを返す
	sub getURLQuery {
		my $self = shift;
		return $request_list{ident $self};
	}

	# リクエストURL生成
	sub createURL {
		my ($self, $param) = @_;
		my (%query, $url);

		# サイトフィルタ(p)クエリ生成
		if($self->validation({url => $param->{domain}})) {
			$query{p} = "site:" . $self->url_encode($param->{domain});
		}
		else {
			die("Invalid URL!");
		}

		# 住所(p)クエリ生成
		if($self->validation({addr => $param->{addr}})) {
			$query{p} = $query{p} ? $query{p} . "+" . $self->url_encode($param->{addr}) : $self->url_encode($param->{addr});
		}
		else {
			die("Invalid address!");
		}

		# 検索件数(n)クエリ生成
		if($self->validation({num => $param->{num}})) {
			$query{n} = $param->{num};
		}
		else {
			die("Invalid num!");
		}

		# ページ番号(b)クエリ生成(とりあえず1で固定)
		if($self->validation({page => $param->{page}})) {
			$query{b} = $param->{page};
		}
		else {
			die("Invalid page!");
		}

		# ソート方法(so)クエリ生成
		if($self->validation({sort => $param->{sort}})) {
			$query{so} = SORT->{$param->{sort}};
		}
		else {
			die("Invalid sort!");
		}

		# URL構築
		for my $key (keys %query){
			$url .= $key . "=" . $query{$key} . "&";
		}
		$url = BLOG_SEARCH_URL . $url;
		chop($url);

		return $url;
	}

	# バリデーション
	sub validation {
		my ($self, $ref) = @_;
		my $ret;

		# URLバリデーション
		if(defined $ref->{url}){
			$ret = 1 if ($ref->{url} =~ /s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+/g);
		}

		# 住所バリデーション
		if(defined $ref->{addr}){
			my $addr_list = $self->validation_addr($ref->{addr});
			# バリデーション結果が都道府県、都道府県コード、市区町村、市区町村コードの4つが含まれているかどうか
			$ret = 1 if (keys(%{$addr_list}) == 4);
		}

		# 検索件数バリデーション
		if(defined $ref->{num}){
			$ret = 1 if ($ref->{num} =~ /\d/ && $ref->{num} <= MAXIMUM_NUM);
		}

		# ページ番号バリデーション
		if(defined $ref->{page}){
			$ret = 1 if ($ref->{page} =~ /\d/);
		}

		# ソート方法バリデーション
		if(defined $ref->{sort}){
			$ret = 1 if ($ref->{sort} =~ /fit|day/);
		}

		return $ret;
	}

	# 住所のバリデーション
	# 呼び出し元で use TMAP::Blogeo::DB; が必須
	sub validation_addr {
		my ($self, $addr) = @_;
		my ($city, $aza) = ($addr, $addr);
		my ($city_sql, @city_bind, $aza_sql, @aza_bind);
		my ($city_code, $aza_code);
		my $result;

		# 都道府県検出用正規表現
		my $re =<<RE;
		(?-xism:(?:(?:(?:[富岡]|和歌)山|(?:[広徳]|鹿児)島|(?:[石香]|神奈)
		川|山[口形梨]|福[井岡島]|[佐滋]賀 |宮[城崎]|愛[媛知]|長[崎野]|三重|
		兵庫|千葉|埼玉|奈良|岐阜|岩手|島根|新潟|栃木|沖縄|熊本|秋田|群馬|茨城|
		青森|静岡|高知|鳥取)県|大(?:分県|阪府)|京都府|北海道|東京都))
RE
		$re =~ s/(\n|\t)//g;

		# 都道府県らしき文字列と市区町村らしき文字列に分ける
		$aza =~ s/$re//;
		$city =~ s/$aza//;

		# DBに問い合わせて正しい住所か照合する
		my $db = MyLibs::TMAP::Blogeo::DB->new();

		# DB接続
		$db->DBConnect();

		# City
		$city_sql = "SELECT code FROM tmap_code_city WHERE name = ?";
		@city_bind = ($city);
		$db->fetch($city_sql, @city_bind);
		$city_code = $db->get_data()->[0]->{code};

		# Aza
		$aza_sql = "SELECT code FROM tmap_code_aza WHERE name = ? AND code LIKE ?";
		@aza_bind = ($aza, $city_code . "%");
		$db->fetch($aza_sql, @aza_bind);
		$aza_code = $db->get_data()->[0]->{code};

		# DB切断
		$db->DBClose();

		# 4つのコードが正しく取得できたら値をセットする
		if($city && $aza && $city_code && $aza_code){
			$result = {
				city      => $city,
				aza       => $aza,
				city_code => $city_code,
				aza_code  => $aza_code
			};
			$request_addr{ident $self} = $result;
		}
		return $result;
	}

	# URLエンコード
	sub url_encode {
		my ($self, $str) = @_;
		$str =~ s/([^\w\.])/'%'.unpack("H2", $1)/eg;
		$str =~ tr/ /+/;
		return $str;
	}

	# URLデコード
	sub url_decode {
		my ($self, $str) = @_;
		$str =~ tr/+/ /;
		$str =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack('H2', $1)/eg;
		return $str;
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my ($self) = @_;

		delete $request_list{ident $self};
		delete $request_url{ident $self};
		delete $request_addr{ident $self};

		return;
	}
}

1;