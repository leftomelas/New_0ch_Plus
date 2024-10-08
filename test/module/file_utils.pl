#============================================================================================================
#
#	ファイル操作ユーティリティモジュール
#
#============================================================================================================
package	FILE_UTILS;

use strict;
use utf8;
use open IO => ':encoding(cp932)';
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	ファイルコピー
#	-------------------------------------------------------------------------------------
#	@param	$src	コピー元ファイルパス
#	@param	$dst	コピー先ファイルパス
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Copy
{
	my ($src, $dst) = @_;
	
	if (open(my $fh_s, '<', $src) && open(my $fh_d, (-f $dst ? '+<' : '>'), $dst)) {
		flock($fh_s, 2);
		flock($fh_d, 2);
		seek($fh_d, 0, 0);
		binmode($fh_s);
		binmode($fh_d);
		print $fh_d (<$fh_s>);
		truncate($fh_d, tell($fh_d));
		close($fh_s);
		close($fh_d);
		
		# パーミッション設定
		chmod((stat $src)[2], $dst);
		return 1;
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	ファイル移動
#	-------------------------------------------------------------------------------------
#	@param	$src	移動元ファイルパス
#	@param	$dst	移動先ファイルパス
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Move
{
	my ($src, $dst) = @_;
	
	if (Copy($src, $dst)) {
		unlink $src;	# コピー元削除
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ディレクトリ再帰削除
#	-------------------------------------------------------------------------------------
#	@param	$path	削除するパス
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DeleteDirectory
{
	my ($path) = @_;
	
	# ファイル情報を取得
	my %fileList = ();
	GetFileInfoList($path, \%fileList);
	
	foreach my $file (keys %fileList) {
		if ($file ne '.' && $file ne '..') {
			my (undef, undef, $attr) = split(/<>/, $fileList{$file}, -1);
			if ($attr & 1) {						# ディレクトリなら
				DeleteDirectory("$path/$file");		# 再帰呼び出し
			}
			else {									# ファイルなら
				unlink "$path/$file";				# そのまま削除
			}
		}
	}
	rmdir $path;
}

#------------------------------------------------------------------------------------------------------------
#
#	ファイル情報一覧取得
#	-------------------------------------------------------------------------------------
#	@param	$Path	一覧取得するパス
#	@param	$pList	一覧を格納するハッシュの参照
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub GetFileInfoList
{
	my ($Path, $pList) = @_;
	
	my @arFiles = ();
	if (opendir(my $dh, $Path)) {
		@arFiles = readdir($dh);
		closedir($dh);
	}
	
	# ディレクトリ内の全ファイルを走査
	foreach my $file (@arFiles) {
		my $Full = "$Path/$file";
		my $Attr = 0;
		my $Size = -s $Full;									# サイズ取得
		my $Perm = substr(sprintf('%o', (stat $Full)[2]), -4);	# パーミッション取得
		$Attr |= 1 if (-d $Full);								# ディレクトリ？
		$Attr |= 2 if (-T $Full);								# テキストファイル？
		$pList->{$file} = "$Size<>$Perm<>$Attr";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	指定ファイル一覧取得
#	-------------------------------------------------------------------------------------
#	@param	$path	一覧取得するパス
#	@param	$pList	一覧を格納する配列の参照
#	@param	$opt	抽出オプション(正規表現)
#	@return	見つかったファイル数
#
#------------------------------------------------------------------------------------------------------------
sub GetFileList
{
	my ($path, $pList, $opt) = @_;
	
	my @files = ();
	if (opendir(my $dh, $path)) {
		@files = readdir($dh);
		closedir($dh);
	}
	
	my $num = 0;
	foreach my $file (@files) {
		# ディレクトリじゃなく抽出条件が一致したら配列にプッシュする
		if (! -d "$path/$file") {
			if ($file =~ /$opt/) { # $optは正規表現
				push @$pList, $file;
				$num++;
			}
		}
	}
	return $num;
}

#------------------------------------------------------------------------------------------------------------
#
#	ディレクトリ作成
#	-------------------------------------------------------------------------------------
#	@param	$path	作成するパス
#	@param	$perm	ディレクトリのパーミッション
#	@return	作成に成功したら1を返す
#
#------------------------------------------------------------------------------------------------------------
sub CreateDirectory
{
	my ($path, $perm) = @_;
	
	if (! -e $path) {
		return mkdir($path, $perm);
	}
	return 0;
}

#-------------------------------------------------------------------------------------------------------------
#
#	ディレクトリ作成
#	------------------------------------------------------------------
#	@param	$path	生成パス
#	@return	なし
#
#-------------------------------------------------------------------------------------------------------------
sub CreateFolderHierarchy
{
	my ($path, $perm) = @_;
	
	while (1) {
		if (-d $path) {
			return;
		}
		else {
			if (mkdir($path, $perm)) {
				return;
			}
			# ディレクトリ作成失敗時は再帰的に1つ下の階層を作成する
			else {
				my $upath = $path;
				$upath =~ s|[\\\/][^\\\/]*$||;
				CreateFolderHierarchy($upath, $perm);
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ディレクトリ検索
#	-------------------------------------------------------------------------------------
#	@param	$path	検索するパス
#	@param	$pHash	検索結果格納用ハッシュ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub GetFolderHierarchy
{
	my ($path, $pHash) = @_;
	
	my @elements = ();
	if (opendir(my $dh, $path)) {
		@elements = readdir($dh);
		closedir($dh);
	}
	
	foreach my $elem (sort @elements) {
		# ディレクトリが見つかったら再帰的に探索する
		if (-d "$path/$elem" && $elem ne '.' && $elem ne '..') {
			my %folders = ();
			GetFolderHierarchy("$path/$elem", \%folders);
			if (scalar(keys(%folders)) > 0) {
				$pHash->{$elem} = \%folders;
			}
			else {
				$pHash->{$elem} = undef; # don't delete
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ディレクトリリスト取得
#	GetFolderHierarchyで取得したハッシュからディレクトリ一覧の配列を取得する
#	-------------------------------------------------------------------------------------
#	@param	$pHash	GetFolderHierarchyで取得したハッシュ
#	@param	$pList	結果格納用配列
#	@param	$base	ベースパス
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub GetFolderList
{
	my ($pHash, $pList, $base) = @_;
	
	foreach my $key (keys %$pHash) {
		push @$pList, "$base/$key";
		if (defined $pHash->{$key}) {
			GetFolderList($pHash->{$key}, $pList, "$base/$key");
		}
	}
}
#ファイル全文検索
sub fsearch {
  my($dir, $word) = @_;
	my $result = '';

  opendir(DIR, $dir);
  my @dir = sort { $a cmp $b } readdir(DIR);
  closedir(DIR);

  foreach my $file (@dir) {
	if ($file eq '.' or $file eq '..') {
	  next;
	}

	my $target = "$dir$file";

	if (-d $target) {
	  &search("$target/", $word);
	} else {
	  my $flag = 0;

	  open(FH, $target);
	  while (my $line = <FH>) {
		if (index(lc($line), lc($word)) >= 0) {
		  $flag = 1;
		}
	  }
	  close(FH);

	  if ($flag) {
		$result = $target;
				last;
	  }
	}
  }

  return $result;
}

# 期限切れファイルのクリア
sub ClearExpiredFiles
{
	my ($dir, $reg_file, $expiry) = @_;

	opendir(my $targetDir, "$dir/") or die "Cannot open directory: $!";
	my @files = grep { /$reg_file/ && -f "$dir/$_" } readdir($targetDir);
	closedir($targetDir);

	my $count = 0;
	foreach my $file (@files){

		my $filename = "$dir/$file";
		unlink $filename if(time - (stat($filename))[9] > $expiry);
		$count++;

	}
	return $count;
}
#============================================================================================================
#	Module END
#============================================================================================================
1;
