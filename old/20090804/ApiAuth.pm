package MyLibs::Common::Auth::ApiAuth;

{
	use Class::Std::Utils;
	use FindBin::libs qw{ export base=syscommon };
	use MyLibs::Common::DB::Config;
	use MyLibs::Common::DB::Schema;

	use constant SCHEMA_NAME => "Apikey";
	use constant DBMS_NAME => "mysql";
	use constant DB_NAME => "apikey";

	my %request_query; # 処理のステータスを記録
	#my %db_conf;       # DB接続の設定

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;

		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;

		# メンバデータを初期化する
		$request_query{ident $obj} = $init_ref;

		return $obj;
	}

	sub db_conf {
		my $self = shift;

		# DBの接続設定を取得
		my ($conf_obj, $db_conf);
		$conf_obj = MyLibs::Common::DB::Config->new();
		$conf_obj->use_db(DBMS_NAME);
		$db_conf = $conf_obj->get_db_config();

		return $db_conf;
	}

	# APIの認証を行う
	sub execAuthentication {
		my $self = shift;
		my ($sql, @bind);
		my $dbname = DB_NAME;

		# DB接続設定をロード
		my $db_conf = $self->db_conf();

		# ORマッピング開始
		my $connect_info = ["dbi:$db_conf->{dbms}:dbname=$dbname;host=$db_conf->{host}", $db_conf->{user}, $db_conf->{pass}];
		my $schema = MyLibs::Common::DB::Schema->connect(@{$connect_info});
		$schema->storage->dbh->do("SET names utf8");

		# リファラからドメイン名を取得
		my $domain = ($request_query{ident $self}->{referer} =~ /^https?:\/\/([^\/]+)/) ? $1 : $request_query{ident $self}->{referer};

		# デバッグ用にリファラなしの場合はsummer-lights.dyndns.wsに置き換える(特別ルール)
		$domain = "summer-lights.dyndns.ws" if ($domain eq "");

		my $auth_result = 0;

		if($domain){
			my $rs = $schema->resultset(SCHEMA_NAME)->search({domain => $domain});

			while(my $row = $rs->next){
				if($row->apikey eq $request_query{ident $self}->{apikey}){
					$auth_result = 1;
					break;
				}
			}
		}

		return $auth_result;
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my $self = shift;

		delete $request_query{ident $self};

		return;
	}
}

1;