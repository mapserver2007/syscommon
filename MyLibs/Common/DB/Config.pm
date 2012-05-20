package MyLibs::Common::DB::Config;

{
	use Class::Std::Utils;
	my %db_conf;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;
		my $obj = bless \do{my $anon_scalar}, $class;

		return $obj;
	}

	sub use_db {
		my ($self, $dbms, $dbname) = @_;

		# 使用するDBの設定を読み込む
		if($dbms eq "mysql"){
			$self->def_db_mysqlconfig();
		}
		elsif($dbms eq "pgsql"){
			$self->def_db_pgconfig();
		}

		return;
	}

	# MySQL設定
	sub def_db_mysqlconfig {
		my $self = shift;

		$db_conf{ident $self} = {
			dbms => "mysql",
			host => "192.168.0.103",
			port => 3306,
			user => "mysql",
			pass => "mysql"
		};

		return;
	}

	# PostgreSQL設定
	sub def_db_pgconfig {
		my $self = shift;

		$db_conf{ident $self} = {
			dbms => "Pg",
			host => "192.168.0.103",
			port => 5432,
			user => "postgres",
			pass => "psql"
		};

		return;
	}

	# DB設定を返す
	sub get_db_config {
		my $self = shift;

		return $db_conf{ident $self};
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my $self = shift;

		delete $db_conf{ident $self};

		return;
	}
}

1;