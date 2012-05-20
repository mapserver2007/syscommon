package MyLibs::Common::Util::Thumbnail;

{
	use strict;
	use warnings;
	use Class::Std::Utils;
	use Imager;
	use File::Basename;
	use Data::Dumper;

	my %params;
	my %error;

	# コンストラクタ
	sub new {
		my ($class, $init_ref) = @_;
		my $obj = bless \do{my $anon_scalar}, $class;
		$params{ident $obj} = $init_ref;
		$error{ident $obj} = [];
		return $obj;
	}

	sub validate {
		my $self = shift;
		my $is_success = 0;
		my $image_path = $self->canonicalize($params{ident $self}->{image_path} || '/path/to/unknown');
		my $save_path = $self->canonicalize($params{ident $self}->{dir_path} || '/path/to/unknown');
		my $size_x = $params{ident $self}->{size_x};
		my $size_y = $params{ident $self}->{size_y};
		my $size_auto = $params{ident $self}->{size_auto};
		my $percentage = $params{ident $self}->{percentage};

		# 変換前画像パスのチェック
		unless (-f $image_path) {
			$self->set_error("Not found image: $image_path.");
			return $is_success;
		}

		# サムネイル画像保存パスのチェック
		unless (-d $save_path) {
			$self->set_error("Invalid save directory path: $save_path.");
			return $is_success;
		}

		# サイズパラメータが全て指定なし(undef)の場合
		if(!(defined $size_x) && !(defined $size_y) && !(defined $size_auto) && !(defined $percentage)) {
			$self->set_error("Please set correctly size parameter.");
			return $is_success;
		}
		# 画像の縮小割合をチェック
		elsif (defined $size_x && defined $size_y && $size_x <= 0 && $size_y <= 0 && $size_x =~ /\d/ && $size_y =~ /\d/) {
			$self->set_error("Invalid size: $size_x or $size_y.");
			return $is_success;
		}
		# 画像の自動縮小割合をチェック
		elsif (defined $size_auto && $size_auto <= 0 && $size_auto =~ /\d/) {
			$self->set_error("Invalid size(auto): $size_auto.");
			return $is_success;
		}
		# 画像の縮小割合(倍率)
		elsif (defined $percentage && ($percentage <= 0 || $percentage > 1) && $percentage =~ /\d/) {
			$self->set_error("Invalid percentage: $percentage.");
			return $is_success;
		}

		$is_success = 1;
		return $is_success;
	}

	# サムネイル生成
	sub save {
		my $self = shift;
		my $is_success = 0;
		unless ($self->validate()) { return; }
		my ($width, $height) = ($params{ident $self}->{size_x}, $params{ident $self}->{size_y});
		my $size_auto = $params{ident $self}->{size_auto};
		my $percentage = $params{ident $self}->{percentage};

		my $tn = Imager->new();
		my $filename = basename($params{ident $self}->{image_path});
		$tn->read(file => $self->canonicalize($params{ident $self}->{image_path})) or die $tn->errstr;

		# selected size_x or size_y
		if($width || $height) {
			$width  = int($height / $tn->getheight() * $tn->getwidth() + 0.5) unless ($width);
			$height = int($width / $tn->getwidth() * $tn->getheight() + 0.5) unless ($height);
			$tn = $tn->scale(xpixels => $width, ypixels => $height);
		}
		# selected size(auto)
		elsif($size_auto) {
			my $base_ratio = ($tn->getwidth() <=> $tn->getheight()) == -1 ?
				$size_auto / $tn->getheight() : $size_auto / $tn->getwidth();
			$width = $tn->getwidth() * $base_ratio;
			$height = $tn->getheight() * $base_ratio;
			$tn = $tn->scale(xpixels => $width, ypixels => $height);
		}
		# selected percentage
		elsif($percentage) {
			$tn = $tn->scale(scalefactor => $percentage);
		}

		$tn->write(file => ($params{ident $self}->{dir_path} . '/' . $filename)) or die $tn->errstr;
		$is_success = 1;

		return $is_success;
	}

	sub remove {
		my ($self, $filename) = @_;
		my $is_success = 0;

		# ディレクトリパスが存在するか
		my $remove_path = $self->canonicalize($params{ident $self}->{dir_path} || '/path/to/unknown');
		unless (-d $remove_path) {
			$self->set_error("Invalid remove thumbnail image directory path: $remove_path.");
			return $is_success;
		}

		# ファイルが存在するか
		my $file_path = qq|$remove_path/$filename|;
		unless (-f $file_path) {
			$self->set_error("Invalid remove thumbnail image path: $file_path.");
			return $is_success;
		}

		# ファイルを削除する
		unless (unlink $file_path) {
			$self->set_error("Could not remove thumbnail image: $file_path.");
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

	# オブジェクト破棄時に属性をクリーンアップする
	sub DESTROY {
		my $self = shift;
		delete $params{ident $self};
		delete $error{ident $self};
		return;
	}
}

1;