package MyLibs::TMAP::Blogeo::BlogRegister;

{
	use Class::Std::Utils;

	my %blog_list_ref;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;

		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;

		return $obj;
	}

	# 収集したBlogデータを登録
	# 呼び出し元で use TMAP::Blogeo::DB; が必須
	sub register {
		my ($self, $blog_list_ref) = @_;
		my ($blog_sql, @blog_bind, $addr_sql, @addr_bind, $rv);
		my ($tmp_sql, @tmp_bind);

		# DBに問い合わせて正しい住所か照合する
		my $db = MyLibs::TMAP::Blogeo::DB->new();

		# DB接続
		$db->DBConnect();

		for(@{$blog_list_ref}){
			# 重複のURLが存在しないかチェック
			$tmp_sql = "SELECT count(*) FROM tmap_blog WHERE url = ?";
			@tmp_bind = ($_->{url});
			$db->fetch($tmp_sql, @tmp_bind);
			my $duplication_count = $db->get_data()->[0]->{count};

			# 重複がある場合は次へ
			next if ($duplication_count > 0);

			# BLOG:SQL生成
			$blog_sql = "INSERT INTO tmap_blog (url, site, title, date) VALUES (?, ?, ?, ?)";
			@blog_bind = ($_->{url}, $_->{site_name}, $_->{article_title}, $_->{date});

			# BLOG:実行
			$rv = $db->register($blog_sql, @blog_bind);

			# Blogデータが登録できたときのみ住所データも登録する
			if($rv == 1){
				# 今登録したBlogデータのGROUP IDを取得する
				$tmp_sql = "SELECT grp_id FROM tmap_blog ORDER BY grp_id DESC LIMIT 1 OFFSET 0";
				@tmp_bind = ();
				$db->fetch($tmp_sql, @tmp_bind);
				my $grp_id = $db->get_data()->[0]->{grp_id};

				# ADDR:SQL生成
				$addr_sql = "INSERT INTO tmap_addr (grp_id, city, aza, address, geom) VALUES (?, ?, ?, ?, GeometryFromText('POINT($_->{lng} $_->{lat})', 4326))";
				@addr_bind = ($grp_id, $_->{city}, $_->{aza}, $_->{addr});
				$rv = $db->register($addr_sql, @addr_bind);
			}
		}
		# DB切断
		$db->DBClose();

		return;
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my ($self) = @_;

		delete $blog_list_ref{ident $self};

		return;
	}
}

1;