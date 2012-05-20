package TrushCliper::DB;

{
	use Class::Std::Utils;
	use DBI;
	my %db;      # DBハンドラを格納
	my %result;  # 取得結果を格納
	
	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;
		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;
		# メンバデータを初期化する
		$db{ident $obj} = $init_ref;

		return $obj;
	}
	
	# DBに接続する
	sub DBConnect {
		my $self = shift;
		my $dsn = "DBI:mysql:tclipers:192.168.0.103:3306;mysql_read_default_file=/etc/mysql/my.cnf";
		my $user = "mysql";
		my $pass = "mysql";
		
		# DBIオブジェクトを格納、DB接続する
		$db{ident $self} = DBI->connect($dsn, $user, $pass);
		
		return;
	}
	
	# DBを切断する
	sub DBClose {
		my $self = shift;
		
		# DB切断する
		$db{ident $self}->disconnect;
	
		return;
	}
	
	# 内容を登録する
	sub register {
		my ($self, $sql, @bind) = @_;
		my $data = [];
		# SQLを実行する
		my $sth = $db{ident $self}->prepare($sql) or die $DBI::errstr;
		$sth->execute(@bind) or die $DBI::errstr;
   		$sth->finish();
	}
	
	# 結果を取り出す
	sub fetch {
		my ($self, $sql, @bind) = @_;
		my $data = [];
		# SQLを実行する
		my $sth = $db{ident $self}->prepare($sql) or die $DBI::errstr;
		$sth->execute(@bind) or die $DBI::errstr;
    	while(my $res = $sth->fetchrow_hashref){
    		push @{$data}, $res;
    		$rv = 1;
   		}
   		$result{ident $self} = $data;
   		$sth->finish();
	}
	
	# DBから取り出した値を返す
	sub get_data {
		$self = shift;
		return $result{ident $self};
	}
	
	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my ($self) = @_;
		
		delete $db{ident $self};
		delete $result{ident $self};
		
		return;
	}
}

1;
