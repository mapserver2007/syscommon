package MyLibs::TMAP::Blogeo::BlogScraper;

{
	use Class::Std::Utils;
	use Web::Scraper;
	use URI;
	use Encode;
	use LWP::UserAgent;
	use JSON;

	my %result_list;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;

		# スカラーをブレスする
		my $obj = bless \do{my $anon_scalar}, $class;

		# メンバデータを初期化する
		$request_list{ident $obj} = [];

		return $obj;
	}

	# スクレイプ実行
	sub scrape {
		my ($self, $request_ref, $tmapi_conf) = @_;
		my ($date, $url, $site_name, $article_title);
		my $result_str = "[OK]";

		for my $query (@{$request_ref}){
			# スクレイプ開始
			my $res = scraper {
				process '//div[@class="r-details yjSt"]/div/em', 'url[]' => 'TEXT';
				process '//div[@class="r-details yjSt"]/a[1]', 'site_name[]' => 'TEXT';
				process '//a[@class="r-title yjM"]', 'article_title[]' => 'TEXT';
				process '//em[@class="r-date yjS"]', 'date[]' => 'TEXT';
				result 'url', 'site_name', 'article_title', 'date';
			}->scrape(URI->new($query->{url}));

			#　スクレイプ結果を整形してリスト化
			my $key = scalar(@{$res->{url}});
			for(0..($key - 1)){
				# APIの叩きすぎを防止するためにスリープ
				sleep(5);

				# 日付を整形する
				my @d = split(/[^\d]+/, $res->{date}->[$_]);
				$date = sprintf("%4d-%02d-%02d %02d:%02d", $d[0], $d[1], $d[2], $d[3], $d[4]);

				# URLを整形
				$url = "http://" . $res->{url}->[$_];

				# サイト名
				$site_name = encode("utf8", $res->{site_name}->[$_]);

				# 記事名
				$article_title = encode("utf8", $res->{article_title}->[$_]);

				my $base_addr = $res->{addr}->{city} . $res->{addr}->{aza};

				# 当該ブログの住所と経緯度を取得
				my $extract_url = qq/$tmapi_conf->{base_uri}?uri=$url&ext=$tmapi_conf->{ext}&apikey=$tmapi_conf->{apikey}/;
				$extract_url =~ s/summer-lights.dyndns.ws/localhost/;

				my $ua = LWP::UserAgent->new;
				my $addr_json = $ua->request(HTTP::Request->new(GET => $extract_url))->content;
				my $addr_obj = from_json($addr_json);

				# 抽出した住所・経緯度の組の数を取得
				my $i = scalar(@{$addr_obj});

				# 抽出できなかったら次へ
				next if ($i == 0);
				# 都道府県、市区町村を結合しておく
				my $base_addr = $query->{addr}->{city} . $query->{addr}->{aza};
				# 丁・番地レベルまである住所だけを取得する
				for(0..($i - 1)){
					if($addr_obj->[$_]->{addr} =~ /^$base_addr+[^\d]+[\d]/){
						my ($addr, $lng, $lat) = (encode('utf8', decode('utf8', $addr_obj->[$_]->{addr})), $addr_obj->[$_]->{lng}, $addr_obj->[$_]->{lat});
						my ($city, $aza) = ($query->{addr}->{city_code}, $query->{addr}->{aza_code});
						my $obj = {
							url           => $url,
							site_name     => $site_name,
							article_title => $article_title,
							date          => $date,
							addr          => $addr,
							lng           => $lng,
							lat           => $lat,
							city          => $city,
							aza           => $aza
						};
						push @{$request_list{ident $self}}, $obj;

						# 結果をコンソール表示
						print $result_str . "\t" . $url  . "\n" if ($url);
						print $result_str . "\t" . $addr . "\n" if ($addr);
					}
				}
			}
		}
		return;
	}

	# 取得したスクレイプ結果を返す
	sub get_blog_list {
		my $self = shift;
		return $request_list{ident $self};
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my ($self) = @_;

		delete $request_list{ident $self};

		return;
	}
}

1;