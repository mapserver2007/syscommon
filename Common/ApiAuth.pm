package Common::ApiAuth;

{
	use Class::Std::Utils;

	my %request_query; # 処理のステータスを記録
	
	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;
		
		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;
		
		# メンバデータを初期化する
		$request_query{ident $obj} = $init_ref;

		return $obj;
	}
	
	# APIの認証を行う
	# 呼び出し元で use Common::DB; が必須
	sub execAuthentication {
		my $self = shift;
		my ($sql, @bind);

		# DBに問い合わせ開始
		my $db = Common::DB->new();
		
		# DB接続
		$db->DBConnect();

		# リファラからドメイン名を取得
		my $domain = ($request_query{ident $self}->{referer} =~ /^https?:\/\/([^\/]+)/) ? $1 : $request_query{ident $self}->{referer};

		# デバッグ用にリファラなしの場合はsummer-lights.dyndns.wsに置き換える(特別ルール)
		$domain = "summer-lights.dyndns.ws" if ($domain eq "");
		
		my $auth_result = 0;

		if($domain){
			# SQL実行
			$sql = "SELECT apikey FROM apikey WHERE domain = ?";
			@bind = ($domain);
			$db->fetch($sql, @bind);
			my $row = $db->get_data();
			for(my $i = 0; $i < scalar(@{$row}); $i++){
				# APIキーが正しいかチェック
				if($row->[$i]->{apikey} eq $request_query{ident $self}->{apikey}){
					$auth_result = 1;
					break;
				}
			}
		}
		
		# DB切断
		$db->DBClose();
		
		return $auth_result;
	}
	
	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my ($self) = @_;
		
		delete $request_query{ident $self};
		
		return;
	}	
}

1;