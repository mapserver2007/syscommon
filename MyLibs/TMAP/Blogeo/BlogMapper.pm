package MyLibs::TMAP::Blogeo::BlogMapper;

{
	use Class::Std::Utils;
	use JSON;
	use Encode;

	use constant MAX_NUM  => 100; # データの最大表示件数
	use constant DEF_NUM  => 10;  # データのデフォルト表示件数
	use constant MAX_DIST => 100000; # 表示範囲の最大距離(メートル)
	use constant DEF_DIST => 10000;  # 表示範囲のデフォルト距離(メートル)

	my %result;
	my %query;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;

		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;

		# メンバデータを初期化する
		$query{ident $obj} = {};

		return $obj;
	}

	# バリデート
	sub validate {
		my ($self, $query) = @_;
		my $ret = 0;

		# 経度
		if(defined $query->{lng}){
			if($query->{lng} > 120 && $query->{lng} < 150){
				$query{ident $self}->{lng} = $query->{lng};
				$ret++;
			}
		}

		# 緯度
		if(defined $query->{lat}){
			if($query->{lat} > 23 && $query->{lat} < 47){
				$query{ident $self}->{lat} = $query->{lat};
				$ret++;
			}
		}

		# 距離
		if(defined $query->{dist}){
			if($query->{dist} > 0 && $query->{dist} < MAX_DIST){
				$query{ident $self}->{dist} = $query->{dist};
			}
			else {
				$query{ident $self}->{dist} = DEF_NUM;
			}
			$ret++;
		}

		# 表示件数
		if(defined $query->{num}){
			if($query->{num} > 0 && $query->{num} < MAX_NUM){
				$query{ident $self}->{num} = $query->{num};
			}
			else {
				$query{ident $self}->{num} = DEF_NUM;
			}
			$ret++;
		}

		#　コールバック(バリデートは特にしない)
		if(defined $query->{callback}){
			$query{ident $self}->{callback} = $query->{callback};
		}

		return $ret;
	}

	# マッピングデータを返す
	# 呼び出し元で use TMAP::Blogeo::DB; が必須
	sub mapper {
		my ($self, $query) = @_;
		my ($sql, @bind);

		# バリデーション
		if($self->validate($query) != 4){ return; }

		# DBに問い合わせ開始
		my $db = MyLibs::TMAP::Blogeo::DB->new();

		# DB接続
		$db->DBConnect();

		# SQL
		$sql = "SELECT address, x(geom) AS lng, y(geom) AS lat, distance_sphere(geom, GeometryFromText(?, 4326)) AS distance, site, title, url ";
		$sql.= "FROM tmap_addr, tmap_blog WHERE distance_sphere(geom, GeometryFromText(?, 4326)) < ? AND tmap_addr.grp_id = tmap_blog.grp_id ";
		$sql.= "ORDER BY distance LIMIT ? OFFSET 0";
		my $geom_arg = 'POINT(' . $query{ident $self}->{lng} . ' ' . $query{ident $self}->{lat} . ')';
		@bind = ($geom_arg, $geom_arg, $query{ident $self}->{dist}, $query{ident $self}->{num});
		my $rv = $db->fetch($sql, @bind);

		$result{ident $self} = $db->get_data();

		# DB切断
		$db->DBClose();

		return;
	}

	# JSONで返す(コールバックがある場合はJSONP)
	sub get_json {
		my ($self, $callabck) = @_;
		my $json = to_json($result{ident $self});
		#my $json = encode('euc-jp', decode('euc-jp', to_json($result{ident $self})));
		return $query{ident $self}->{callback} ? qq/$query{ident $self}->{callback}($json)/ : $json;
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my ($self) = @_;

		delete $result{ident $self};
		delete $query{ident $self};

		return;
	}
}

1;