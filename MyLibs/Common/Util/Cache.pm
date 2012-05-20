package MyLibs::Common::Util::Cache;

{
	use Class::Std::Utils;
	use Fcntl;
	use MLDBM qw/DB_File Storable/;

	use constant DEFAULT_TTL => 86400;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;
		my $obj = bless \do{my $anon_scalar}, $class;
		return $obj;
	}

	# キャッシュを生成する
	sub create_cache {
		my ($self, $path, $key, $data) = @_;
		my $ret = {};
		if($key){
			$ret->{data} = $data;
			tie my %db, 'MLDBM', $path, O_CREAT | O_RDWR, 0666 or die "$path: $!";
			$ret->{mtime} = time();
			$db{$key} = $ret;
		}
		return $data;
	}

	# キャッシュを読み出す
	sub load_cache {
		my ($self, $path, $ttl, $key) = @_;
		my $ret;
		# キャッシュファイルが存在するとき
		if(-f $path){
			tie my %db, 'MLDBM', $path, O_RDONLY, 0444 or die "$path: $!";
			$ret = $db{$key}->{data} if (time() < ($db{$key}->{mtime} + $ttl || DEFAULT_TTL));
		}
		return $ret;
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my $self = shift;
		return;
	}
}

1;