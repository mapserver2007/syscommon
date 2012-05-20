package MyLibs::Common::Util::Upload;

{
	use strict;
	use warnings;
	use Class::Std::Utils;
	use CGI;
	use Imager;
	use DateTime;
	use File::Copy;
	use File::Basename;

	use constant MIMETYPE => {
		'image/jpeg'  => 'jpg',
		'image/pjpeg' => 'jpg',
		'image/png'   => 'png',
		'image/gif'   => 'gif'
	};

	my %params;
	my %fileinfo;
	my %error;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;
		my $obj = bless \do{my $anon_scalar}, $class;
		$params{ident $obj} = $init_ref;
		$error{ident $obj} = [];
		return $obj;
	}

	sub save {
		my $self = shift;
		my $cgi = CGI->new();
		my $is_success = 0;

		# ディレクトリパスが存在するか
		my $save_path = $self->canonicalize($params{ident $self}->{dir_path} || '/path/to/unknown');
		unless (-d $save_path) {
			$self->set_error("Invalid save directory path: $save_path.");
			return $is_success;
		}

		# ファイルハンドラとファイル名取得
		my $fh = $cgi->upload('filename');
		$fileinfo{ident $self}->{origin_filename} = basename($fh);

		# アップロードされたファイルのフルパス
		my $tmp_path = $cgi->tmpFileName($fh);

		# MIMEタイプ
		my $mimetype = $cgi->uploadInfo($fh)->{'Content-Type'};

		# 拡張子
		if (MIMETYPE->{$mimetype}) {
			$fileinfo{ident $self}->{file_ext} = MIMETYPE->{$mimetype};
		}
		else {
			$self->set_error("Can't permit this file.");
			return $is_success;
		}

		# 自動生成ファイル名取得
		my $conv_filename = time;
		$fileinfo{ident $self}->{conv_filename} = qq/$conv_filename.$fileinfo{ident $self}->{file_ext}/;

		# ファイル保存
		my $upload_path = qq|$save_path/$fileinfo{ident $self}->{conv_filename}|;
		move($tmp_path, $upload_path) || $self->set_error("Can't save image : $upload_path.");
		$fileinfo{ident $self}->{save_filepath} = $upload_path;
		close($fh);

		# 画像アップロード時間を取得
		my $dt = DateTime->now(time_zone => 'Asia/Tokyo');
		$fileinfo{ident $self}->{date} = $dt->strftime('%Y-%m-%dT%H:%M:%SZ');

		# ファイルサイズ取得
		$fileinfo{ident $self}->{file_size} = (-s $upload_path);

		# アップロード処理が成功
		$is_success = 1 unless @{$self->get_error()};

		return $is_success;
	}

	sub remove {
		my ($self, $filename) = @_;
		my $is_success = 0;

		# ディレクトリパスが存在するか
		my $remove_path = $self->canonicalize($params{ident $self}->{dir_path} || '/path/to/unknown');
		unless (-d $remove_path) {
			$self->set_error("Invalid remove image directory path: $remove_path.");
			return $is_success;
		}

		# ファイルが存在するか
		my $file_path = qq|$remove_path/$filename|;
		unless (-f $file_path) {
			$self->set_error("Invalid remove image path: $file_path.");
			return $is_success;
		}

		# ファイルを削除する
		unless (unlink $file_path) {
			$self->set_error("Could not remove image: $file_path.");
			return $is_success;
		}

		# ファイル削除処理が成功
		$is_success = 1 unless @{$self->get_error()};

		return $is_success;
	}

	# 正しいディレクトリパスかチェック
	sub canonicalize {
		my ($self, $dir) = @_;

		if ($dir !~ m|^/|) {
			my $cwd = `/bin/pwd`; #UNIXコマンド実行
			chop($cwd);
			$dir = "$cwd/$dir";
		}

		# パスの正規化
		my @components = ();
		foreach my $component (split('/', $dir)) {
			next if($component eq "");          # // は無視
			next if($component eq ".");         # /./ は無視
			if($component eq "..") {            # /../ なら
				pop(@components);               # 1 つ前の構成要素も無視
				next;
			}
			push(@components, $component);      # 構成要素を追加
		}
		$dir = '/'.join('/', @components);      # パス名文字列を生成

		return $dir;
	}

	sub set_error {
		my ($self, $msg) = @_;
		push @{$error{ident $self}}, $msg;
		return;
	}

	sub get_error {
		my $self = shift;
		return $error{ident $self};
	}

	sub get_fileinfo {
		my $self = shift;
		return $fileinfo{ident $self};
	}

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my $self = shift;
		delete $params{ident $self};
		delete $fileinfo{ident $self};
		delete $error{ident $self};
		return;
	}
}

1;