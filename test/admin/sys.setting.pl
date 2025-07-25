#============================================================================================================
#
#	システム管理 - 設定 モジュール
#	sys.setting.pl
#	---------------------------------------------------------------------------
#	2004.02.14 start
#
#	EXぜろちゃんねる
#	2010.08.12 設定項目追加による改変
#
#============================================================================================================
package	MODULE;

use strict;
use utf8;
use open IO => ':encoding(cp932)';
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj, @LOG);
	
	$obj = {
		'LOG' => \@LOG
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	SYSTEM
#	@param	$Form	FORM
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $BASE, $Page);
	
	require './admin/admin_cgi_base.pl';
	$BASE = ADMIN_CGI_BASE->new;
	
	# 管理情報を登録
	$Sys->Set('ADMIN', $pSys);
	
	# 管理マスタオブジェクトの生成
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($BASE, $pSys);
	
	if ($subMode eq 'INFO') {														# システム情報画面
		PrintSystemInfo($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'BASIC') {													# 基本設定画面
		PrintBasicSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'PERMISSION') {												# パーミッション設定画面
		PrintPermissionSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'LIMITTER') {												# リミッタ設定画面
		PrintLimitterSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'OTHER') {													# その他設定画面
		PrintOtherSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'VIEW') {													# 表示設定
		PrintPlusViewSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SEC') {														# 規制設定
		PrintPlusSecSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'PLUGIN') {													# 拡張機能設定画面
		PrintPluginSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'PLUGINCONF') {												# 拡張機能個別設定設定画面
		PrintPluginOptionSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# システム設定完了画面
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('システム設定処理', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# システム設定失敗画面
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	$BASE->Print($Sys->Get('_TITLE'), 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	機能メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	SYSTEM
#	@param	$Form	FORM
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $err);
	
	# 管理情報を登録
	$Sys->Set('ADMIN', $pSys);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'BASIC') {														# 基本設定
		$err = FunctionBasicSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'PERMISSION') {												# パーミッション設定
		$err = FunctionPermissionSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'LIMITTER') {												# 制限設定
		$err = FunctionLimitterSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'OTHER') {													# その他設定
		$err = FunctionOtherSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'VIEW') {													# 表示設定
		$err = FunctionPlusViewSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SEC') {														# 規制設定
		$err = FunctionPlusSecSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SET_PLUGIN') {												# 拡張機能情報設定
		$err = FunctionPluginSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATE_PLUGIN') {											# 拡張機能情報更新
		$err = FunctionPluginUpdate($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SET_PLUGINCONF') {											# 拡張機能個別設定設定
		$err = FunctionPluginOptionSetting($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	ADMIN_CGI_BASE
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys) = @_;
	
	$Base->SetMenu('情報', "'sys.setting','DISP','INFO'");
	
	# システム管理権限のみ
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('基本設定', "'sys.setting','DISP','BASIC'");
		$Base->SetMenu('パーミッション設定', "'sys.setting','DISP','PERMISSION'");
		$Base->SetMenu('リミッタ設定', "'sys.setting','DISP','LIMITTER'");
		$Base->SetMenu('その他設定', "'sys.setting','DISP','OTHER'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('表示設定', "'sys.setting','DISP','VIEW'");
		$Base->SetMenu('規制設定', "'sys.setting','DISP','SEC'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('拡張機能設定', "'sys.setting','DISP','PLUGIN'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	システム情報画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintSystemInfo
{
	my ($Page, $SYS, $Form) = @_;
	
	$SYS->Set('_TITLE', 'ex0ch Administrator Information');
	
	my $zerover = $SYS->Get('VERSION');
	my $perlver = $];
	my $perlpath = $^X;
	my $filename = $ENV{'SCRIPT_FILENAME'} || $0;
	my $serverhost = $ENV{'HTTP_HOST'};
	my $servername = $ENV{'SERVER_NAME'};
	my $serversoft = $ENV{'SERVER_SOFTWARE'};
	my @checklist = (qw(
		LWP::UserAgent
		LWP::Protocol::https
		Net::SSLeay
		Net::DNS
		Net::DNS::Lite
		Socket
	), qw(
		CGI
		CGI::Cookie
		CGI::Carp
		CGI::Session
		FCGI
	), qw(
		JSON
		XML::Simple
		HTML::Entities
		Encode
		MIME::Base64
		Storable
	), qw(
		Digest::MD5
		Digest::SHA::PurePerl
	), qw(
		File::Spec
		File::Basename
		File::Path
		File::Copy
		File::Glob
	), qw(
		Time::HiRes
		Time::Local
		POSIX
	), qw(
		Carp
		Safe
	));
	
	my $core = {};
	eval {
		require Module::CoreList;
		$core = $Module::CoreList::version{$perlver};
	};
	
	$Page->Print("<br><b>ex0ch BBS - Administrator Script</b>");
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>■ex0ch Information</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Version</td><td>$zerover</td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>■Perl Information</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Version</td><td>$perlver</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Perl Path</td><td>$perlpath</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Server Software</td><td>$serversoft</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Server Name</td><td>$servername</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Server Host</td><td>$serverhost</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Script Path</td><td>$filename</td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>■Perl Packages (include perllib)</td></tr>\n");
	foreach my $pkg (@checklist) {
		my $var = eval("require $pkg;return \${${pkg}::VERSION};");
		$var = 'undefined' if ($@ || !defined $var);
		$var = "<b>$var</b>" if (!defined $core->{$pkg} || $core->{$pkg} ne $var);
		$Page->Print("<tr><td class=\"DetailTitle\">$pkg</td><td>$var</td></tr>\n");
	}
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	システム基本設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBasicSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($server, $cgi, $bbs, $info, $data, $common,$sitename);
	
	$SYS->Set('_TITLE', 'System Base Setting');
	
	$server	= $SYS->Get('SERVER');
	$cgi	= $SYS->Get('CGIPATH');
	$bbs	= $SYS->Get('BBSPATH');
	$info	= $SYS->Get('INFO');
	$data	= $SYS->Get('DATA');
	$sitename	= $SYS->Get('SITENAME');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','BASIC');\"";
	if ($server eq '') {
		my $sname = $ENV{'SERVER_NAME'};
		$server = "https://$sname";
	}
	if ($cgi eq '') {
		my $path = $ENV{'SCRIPT_NAME'};
		$path =~ s|/[^/]+/[^/]+$||;
		$cgi = "$path$cgi";
	}
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。<br>\n");
	$Page->Print("いくつかの例を挙げます。<br>\n");
	$Page->Print("　例1: http://example.jp/test/admin.cgi<br>\n");
	$Page->Print("　例2: http://example.net/~user/test/admin.cgi<br>\n");
	$Page->Print("　例3: http://example.com/cgi-bin/test/admin.cgi</td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">稼動サーバ(末尾の / は要りません)<br><span class=\"NormalStyle\">");
	$Page->Print("　例1: http://example.jp<br>");
	$Page->Print("　例2: http://example.net</span></td>");
	$Page->Print("<td><input type=text size=60 name=SERVER value=\"$server\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">CGI設置ディレクトリ(絶対パス)<br><span class=\"NormalStyle\">");
	$Page->Print("　例1: /test<br>");
	$Page->Print("　例2: /~user/test<br>");
	$Page->Print("　例3: /cgi-bin/test</span></td>");
	$Page->Print("<td><input type=text size=60 name=CGIPATH value=\"$cgi\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">掲示板配置ディレクトリ(相対パス)<br><span class=\"NormalStyle\">");
	$Page->Print("　例1: .jp/bbs1/ → <span class=\"UnderLine\">..</span><br>");
	$Page->Print("　例2: .net/~user/bbs2/ → <span class=\"UnderLine\">..</span><br>");
	$Page->Print("　例3: .com/bbs3/ → <span class=\"UnderLine\">../..</span></span></td>");
	$Page->Print("<td><input type=text size=60 name=BBSPATH value=\"$bbs\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">システム情報ディレクトリ(/ から始める)<br><span class=\"NormalStyle\">");
	$Page->Print("　例1: .jp/test/info → <span class=\"UnderLine\">/info</span><br>");
	$Page->Print("<td><input type=text size=60 name=INFO value=\"$info\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">システムデータディレクトリ(/ から始める)<br><span class=\"NormalStyle\">");
	$Page->Print("　例1: .jp/test/info → <span class=\"UnderLine\">/datas</span><br>");
	$Page->Print("<td><input type=text size=60 name=DATA value=\"$data\" ></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">サイトの名称(任意)<br><span class=\"WebSiteName\">");
	$Page->Print("　例1: 6ちゃんねる<br>");
	$Page->Print("　例2: 樺太庁のホームページ</span></td>");
	$Page->Print("<td><input type=text size=60 name=SITENAME value=\"$sitename\" ></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	パーミッション設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintPermissionSetting
{
	my ($Page, $Sys, $Form) = @_;
	
	$Sys->Set('_TITLE', 'System Permission Setting');
	
	my $datP	= sprintf("%o", $Sys->Get('PM-DAT'));
	my $txtP	= sprintf("%o", $Sys->Get('PM-TXT'));
	my $logP	= sprintf("%o", $Sys->Get('PM-LOG'));
	my $admP	= sprintf("%o", $Sys->Get('PM-ADM'));
	my $stopP	= sprintf("%o", $Sys->Get('PM-STOP'));
	my $admDP	= sprintf("%o", $Sys->Get('PM-ADIR'));
	my $bbsDP	= sprintf("%o", $Sys->Get('PM-BDIR'));
	my $logDP	= sprintf("%o", $Sys->Get('PM-LDIR'));
	my $kakoDP	= sprintf("%o", $Sys->Get('PM-KDIR'));
	
	my $common = "onclick=\"DoSubmit('sys.setting','FUNC','PERMISSION');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。<br>");
	$Page->Print("<b>（8進値で設定すること）</b></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">datファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_DAT value=\"$datP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">テキストファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_TXT value=\"$txtP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">ログファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_LOG value=\"$logP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">管理ファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_ADMIN value=\"$admP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">停止スレッドファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_STOP value=\"$stopP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">管理ディレクトリパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_ADMIN_DIR value=\"$admDP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">掲示板ディレクトリパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_BBS_DIR value=\"$bbsDP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">ログ保存ディレクトリパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_LOG_DIR value=\"$logDP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">過去ログ倉庫ディレクトリパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_KAKO_DIR value=\"$kakoDP\" ></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	制限設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#	2010.08.12 windyakin ★
#	 -> システム変更に伴う設定項目の追加
#
#------------------------------------------------------------------------------------------------------------
sub PrintLimitterSetting
{
	my ($Page, $SYS, $Form) = @_;
	my (@vSYS, $common);
	
	$SYS->Set('_TITLE', 'System Limitter Setting');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','LIMITTER');\"";
	$vSYS[0] = $SYS->Get('RESMAX');
	$vSYS[1] = $SYS->Get('SUBMAX');
	$vSYS[2] = $SYS->Get('ANKERS');
	$vSYS[3] = $SYS->Get('ERRMAX');
	$vSYS[4] = $SYS->Get('HSTMAX');
	$vSYS[5] = $SYS->Get('ADMMAX');
	$vSYS[6] = $SYS->Get('FLRMAX');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">1掲示板のsubject最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=SUBMAX value=\"$vSYS[1]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">1スレッドのレス最大数</td>");
	$Page->Print("<td><input type=text size=10 name=RESMAX value=\"$vSYS[0]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">1レスのアンカー最大数(0で無制限)</td>");
	$Page->Print("<td><input type=text size=10 name=ANKERS value=\"$vSYS[2]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">エラーログ最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=ERRMAX value=\"$vSYS[3]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">ホストログ最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=HSTMAX value=\"$vSYS[4]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">管理操作ログ最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=ADMMAX value=\"$vSYS[5]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">ユーザー書き込み失敗ログ最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=FLRMAX value=\"$vSYS[6]\" ></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintOtherSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($urlLink, $linkSt, $linkEd, $pathKind, $headText, $headUrl, $FastMode, $upCheck, $imageTag);
	my ($linkChk, $pathInfo, $pathQuery, $fastMode, $bbsget, $imgtag, $CSP, $CSPSet, $ninLvmax, $cookieExp, $authExp, $admCap, $srcCap, $logout, $is_selected);
	my ($imgurID, $imgurSecret, $imgurAuth, $uploadMode, $is_local, $is_imgur, $is_none);
	my ($common,$nin_exp,$pass_exp);
	
	$SYS->Set('_TITLE', 'System Other Setting');
	
	$urlLink	= $SYS->Get('URLLINK');
	$imageTag	= $SYS->Get('IMGTAG');
	$linkSt		= $SYS->Get('LINKST');
	$linkEd		= $SYS->Get('LINKED');
	$pathKind	= $SYS->Get('PATHKIND');
	$headText	= $SYS->Get('HEADTEXT');
	$headUrl	= $SYS->Get('HEADURL');
	$FastMode	= $SYS->Get('FASTMODE');
	$upCheck	= $SYS->Get('UPCHECK');
	$CSP		= $SYS->Get('CSP');
	$ninLvmax	= $SYS->Get('NINLVMAX');
	$cookieExp	= $SYS->Get('COOKIE_EXPIRY');
	$authExp	= $SYS->Get('AUTH_EXPIRY');
	$nin_exp	= $SYS->Get('NIN_EXPIRY');
	$pass_exp	= $SYS->Get('PASS_EXPIRY');
	$logout		= $SYS->Get('LOGOUT');
	$is_selected= $SYS->Get('CM_THEME');
	$imgurID	= $SYS->Get('IMGUR_ID');
	$imgurSecret= $SYS->Get('IMGUR_SECRET');
	$imgurAuth	= $SYS->Get('IMGUR_AUTH');
	$uploadMode = $SYS->Get('UPLOAD');
	
	$linkChk	= ($urlLink eq 'TRUE' ? 'checked' : '');
	$fastMode	= ($FastMode == 1 ? 'checked' : '');
	$imgtag		= ($imageTag == 1 ? 'checked' : '');
	$pathInfo	= ($pathKind == 0 ? 'checked' : '');
	$pathQuery	= ($pathKind == 1 ? 'checked' : '');
	$CSPSet		= ($CSP == 1 ? 'checked' : '');
	$is_none	= ($uploadMode eq '' ? 'selected' : '');
	$is_imgur	= ($uploadMode eq 'imgur' ? 'selected' : '');
	$is_local	= ($uploadMode eq 'local' ? 'selected' : '');

	if($imgurSecret && $imgurID){
		require './module/imgur.pl';
		my $Img = IMGUR->new;
		$Img->Load($SYS);
		if($imgurAuth eq 'authed'){
			$imgurAuth = "Imgur 連携済み";
		}elsif($uploadMode eq 'imgur'){
			require Digest::MD5;
			my $ctx = Digest::MD5->new;
			$ctx->add('ex0ch ID Generation');
			$ctx->add(':', $SYS->Get('SERVER'));
			$ctx->add(':', $SYS->Get('SECURITY_KEY'));
			$ctx->add(':', rand);

			my $redirect = $Form->modCGI->url(-full=>1);
			my $state = $ctx->hexdigest;
			my $auth_url = $Img->GetAuthorizationUrl($redirect, $state);

			$SYS->Set('IMGUR_AUTH',$state);
			$SYS->Save();
			$imgurAuth = qq{<a href="$auth_url" target="_blank">Imgur 連携ページへ</a>};
		}elsif($uploadMode ne 'imgur'){
			$imgurAuth = '<small>Imgurを使う場合、設定とClient IDとClient Secretを保存したら<b>ここ</b>から連携ページに移動して連携を完了させてください。</small>';
			$SYS->Set('IMGUR_AUTH','');
			$SYS->Save();
		}
	}else{
		$imgurAuth = '<small>Imgurを使う場合、Client IDとClient Secretを保存したら<b>ここ</b>から連携ページに移動して連携を完了させてください。</small>';
	}
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','OTHER');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">ヘッダ関連</td></tr>\n");
	$Page->Print("<tr><td>ヘッダ下部に表示するテキスト</td>");
	$Page->Print("<td><input type=text size=60 name=HEADTEXT value=\"$headText\" ></td></tr>\n");
	$Page->Print("<tr><td>上記テキストに貼るリンクのURL</td>");
	$Page->Print("<td><input type=text size=60 name=HEADURL value=\"$headUrl\" ></td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">画像アップロード</td></tr>\n");
	$Page->Print("<tr><td>ユーザーによる画像のアップロード方法を指定します。</td>");
	$Page->Print("<td><select name=\"UPLOAD\" disabled>\n");
	$Page->Print("<option value=\"\" $is_none>なし</option>\n");
	$Page->Print("<option value=\"imgur\" $is_imgur>Imgur</option>\n");
	$Page->Print("<option value=\"local\" $is_local disabled>ローカル</option>\n");
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td>Imgur Client ID</td>");
	$Page->Print("<td><input type=text size=60 name=IMGUR_ID value=\"$imgurID\" disabled></td></tr>\n");
	$Page->Print("<tr><td>Imgur Client Secret</td>");
	$Page->Print("<td><input type=text size=60 name=IMGUR_SECRET value=\"$imgurSecret\" disabled></td></tr>\n");
	$Page->Print("<tr><td>Imgur 連携</td>");
	$Page->Print("<td>$imgurAuth</td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">本文中のURL</td></tr>\n");
	$Page->Print("<tr><td colspan=2><label><input type=checkbox name=IMGTAG $imgtag value=on>");
	$Page->Print("imgur/twimg画像のみIMGタグ変換を許可</label></td>");
	$Page->Print("<tr><td colspan=2><label><input type=checkbox name=CSP $CSPSet value=on>");
	$Page->Print("Youtube/niconico埋め込み用　metaタグでCSPを設定（非推奨・HTTPヘッダで設定できない場合）</label></td>");
	$Page->Print("<tr><td colspan=2><label><input type=checkbox name=URLLINK $linkChk value=on>");
	$Page->Print("本文中URLへの自動リンク</label></td>");
	$Page->Print("<tr><td colspan=2><b>以下自動リンクOFF時のみ有効</b></td></tr>\n");
	$Page->Print("<tr><td>　　リンク禁止時間帯</td>");
	$Page->Print("<td><input type=text size=2 name=LINKST value=\"$linkSt\" >時 ～ ");
	$Page->Print("<input type=text size=2 name=LINKED value=\"$linkEd\" >時</td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">動作モード(read.cgi)</td></tr>\n");
	$Page->Print("<tr><td>PATH種別</td>");
	$Page->Print("<td><label><input type=radio name=PATHKIND value=\"0\" $pathInfo>PATHINFO</label>　");
	$Page->Print("<label><input type=radio name=PATHKIND value=\"1\" $pathQuery>QUERYSTRING</label></td></tr>\n");
	
	#$Page->Print("<tr><td colspan=2><label><input type=checkbox name=FASTMODE $fastMode value=on>");
	#$Page->Print("書き込み時にindex.htmlを更新しない(高速書き込みモード)</label></td>");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">更新チェック</td></tr>\n");
	$Page->Print("<tr><td>更新チェックの間隔</td>");
	$Page->Print("<td><input type=text size=2 name=UPCHECK value=\"$upCheck\">日(0でチェック無効)</td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">Cookie</td></tr>\n");
	$Page->Print("<tr><td>Cookie有効期限</td>");
	$Page->Print("<td><input type=text size=2 name=COOKIE_EXPIRY value=\"$cookieExp\">日</td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">ユーザー認証</td></tr>\n");
	$Page->Print("<tr><td>認証有効期限</td>");
	$Page->Print("<td><input type=text size=2 name=AUTH_EXPIRY value=\"$authExp\">日</td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">忍法帖関連</td></tr>\n");
	$Page->Print("<tr><td>忍法帖データ保持日数</td>");
	$Page->Print("<td>最終書き込みから<input type=text size=2 name=NIN_EXPIRY value=\"$nin_exp\">日</td></tr>\n");
	$Page->Print("<tr><td>パスワード設定時の保持日数</td>");
	$Page->Print("<td>最終書き込みから<input type=text size=2 name=PASS_EXPIRY value=\"$pass_exp\">日</td></tr>\n");
	$Page->Print("<tr><td>忍法帖Lv上限</td>");
	$Page->Print("<td><input type=text size=2 name=NINLVMAX value=\"$ninLvmax\"></td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">ログアウト</td></tr>\n");
	$Page->Print("<tr><td>管理画面からの自動ログアウト時間</td>");
	$Page->Print("<td><input type=text size=2 name=LOGOUT value=\"$logout\">分間操作なしでログアウト(無記入または0で三十分)</td></tr>\n");

	# テーマ名のリスト
	my @themes = (
		'default', '3024-day', '3024-night', 'abbott', 'abcdef', 'ambiance',
		'ayu-dark', 'ayu-mirage', 'base16-dark', 'base16-light', 'bespin',
		'blackboard', 'cobalt', 'colorforth', 'darcula', 'dracula',
		'duotone-dark', 'duotone-light', 'eclipse', 'elegant', 'erlang-dark',
		'gruvbox-dark', 'hopscotch', 'icecoder', 'idea', 'isotope',
		'juejin', 'lesser-dark', 'liquibyte', 'lucario', 'material',
		'material-darker', 'material-palenight', 'material-ocean', 'mbo',
		'mdn-like', 'midnight', 'monokai', 'moxer', 'neat', 'neo', 'night',
		'nord', 'oceanic-next', 'panda-syntax', 'paraiso-dark',
		'paraiso-light', 'pastel-on-dark', 'railscasts', 'rubyblue', 'seti',
		'shadowfox', 'solarized dark', 'solarized light', 'the-matrix',
		'tomorrow-night-bright', 'tomorrow-night-eighties', 'ttcn', 'twilight',
		'vibrant-ink', 'xq-dark', 'xq-light', 'yeti', 'yonce', 'zenburn',
	);

	# セレクトボックス生成
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">エディタのテーマ</td></tr>\n");
	$Page->Print("<tr><td>HTML/BGDSL編集画面のエディタのテーマを設定します。</td>");
	$Page->Print("<td><select name=\"CM_THEME\">\n");
	my $sel = $is_selected eq '' ? ' selected="selected"' : '';
	$Page->Print("<option value=\"\" $sel>なし</option>\n");
	for my $theme (@themes) {
		my $sel = ($theme eq $is_selected) ? ' selected="selected"' : '';
		$Page->Print("<option value=\"$theme\" $sel>$theme</option>\n");
	}
	$Page->Print("</select></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	表示設定画面の表示(EXぜろちゃんねるオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub PrintPlusViewSetting
{
	my ($Page, $SYS, $Form) = @_;
	
	$SYS->Set('_TITLE', 'System View Setting');
	
	my $Banner		= $SYS->Get('BANNER');
	my $Counter		= $SYS->Get('COUNTER');
	my $Prtext		= $SYS->Get('PRTEXT');
	my $Prlink		= $SYS->Get('PRLINK');
	my $Msec		= $SYS->Get('MSEC');
	my $hide_hits	= $SYS->Get('HIDE_HITS');
	my $refresh_mode= $SYS->Get('REFRESH_MODE');
	
	my $bannerindex	= ($Banner & 3 ? 'checked' : '');
	my $banner		= ($Banner & 5 ? 'checked' : '');
	my $msec		= ($Msec == 1 ? 'checked' : '');
	my $hide		= ($hide_hits == 0 ? 'checked' : '');
	my $def			= ($refresh_mode eq 'default' ? 'checked' : '');
	my $ind			= ($refresh_mode eq 'index' ? 'checked' : '');
	my $red			= ($refresh_mode eq 'readcgi' ? 'checked' : '');
	
	my $common = "onclick=\"DoSubmit('sys.setting','FUNC','VIEW');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">Read.cgi関連</td></tr>\n");
	$Page->Print("<tr><td>PR欄の表示文字列 <small>(未入力でPR欄非表示)</small></td>");
	$Page->Print("<td><input type=text size=60 name=PRTEXT value=\"$Prtext\"></td></tr>\n");
	$Page->Print("<tr><td>PR欄のリンクURL</td>");
	$Page->Print("<td><input type=text size=60 name=PRLINK value=\"$Prlink\"></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">告知欄表示</td></tr>\n");
	$Page->Print("<tr><td>index.htmlの告知欄を表示する</td>");
	$Page->Print("<td><input type=checkbox name=BANNERINDEX $bannerindex value=on></td></tr>\n");
	$Page->Print("<tr><td>index.html以外の告知欄を表示する</td>");
	$Page->Print("<td><input type=checkbox name=BANNER $banner value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">msec表示</td></tr>\n");
	$Page->Print("<tr><td>ミリ秒まで表示する</td>");
	$Page->Print("<td><input type=checkbox name=MSEC $msec value=on></td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">規制情報公開</td></tr>\n");
	$Page->Print("<tr><td>規制ユーザーの情報を公開する <br><small>(madakana.cgi、ユーザー規制のエラー画面)</small></td>");
	$Page->Print("<td><input type=checkbox name=HIDE_HITS $hide value=on></td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">書き込み後の遷移先</td></tr>\n");
	$Page->Print("<tr><td>掲示板に書き込まれた後どこに自動遷移するか指定します。</td>");
	$Page->Print("<td><label><input type=radio name=REFRESH_MODE value=\"default\" $def>DEFAULT</label>\n");
	$Page->Print("<label><input type=radio name=REFRESH_MODE value=\"index\" $ind>INDEX</label>\n");
	$Page->Print("<label><input type=radio name=REFRESH_MODE value=\"readcgi\" $red>READ.CGI</label></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	規制設定画面の表示(EXぜろちゃんねるオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub PrintPlusSecSetting
{
	
	my ($Page, $SYS, $Form) = @_;
	my ($Kakiko, $Samba, $DefSamba, $DefHoushi, $Trip12, $TOREXIT,$Captcha,$Captcha_IP,$spamhaus);
	my ($kakiko, $trip12, $torexit, $s5h, $dronebl, $bgdsl, $DSL);
	my ($common);
	
	$SYS->Set('_TITLE', 'System Regulation Setting');
	
	$Kakiko		= $SYS->Get('KAKIKO');
	$Samba		= $SYS->Get('SAMBATM');
	$DefSamba	= $SYS->Get('DEFSAMBA');
	$DefHoushi	= $SYS->Get('DEFHOUSHI');
	$Trip12		= $SYS->Get('TRIP12');
	$TOREXIT	= $SYS->Get('DNSBL_TOREXIT');
	$Captcha	= $SYS->Get('CAPTCHA');
	$Captcha_IP	= $SYS->Get('CAPTCHA_LENIENCY');
	$DSL		= $SYS->Get('BGDSL');
	
	my $noCapSet 	= $Captcha ? '':'selected';
	my $hCapSet 	= $Captcha eq 'h-captcha' ? 'selected' : '';
	my $reCapSet 	= $Captcha eq 'g-recaptcha' ? 'selected' : '';
	my $TurnSet 	= $Captcha eq 'cf-turnstile' ? 'selected' : '';
	my $noCapIP 	= $Captcha_IP ? '':'selected';
	my $CapIPRelax 	= $Captcha_IP eq 'relaxed' ? 'selected' : '';
	my $CapIPStrict = $Captcha_IP eq 'strict' ? 'selected' : '';
	my $Captcha_sitekey 	= $SYS->Get('CAPTCHA_SITEKEY');
	my $Captcha_secretkey  	= $SYS->Get('CAPTCHA_SECRETKEY');
	my $Proxy_apikey  	= $SYS->Get('PROXYCHECK_APIKEY');
	my $Proxy_api		= $SYS->Get('PROXYCHECK_API');
	my $noApiSet 	= $Proxy_api ? '':'selected';
	my $pApiSet 	= $Proxy_api eq 'proxycheck.io' ? 'selected' : '';
	my $IP2ApiSet 	= $Proxy_api eq 'ip2location' ? 'selected' : '';
	my $IPApiSet 	= $Proxy_api eq 'ipqualityscore' ? 'selected' : '';
	my $AApiSet 	= $Proxy_api eq 'abstract' ? 'selected' : '';
	my $IPDApiSet 	= $Proxy_api eq 'ipdata' ? 'selected' : '';
	my $admCap		= $SYS->Get('ADMINCAP');
	my $srcCap		= $SYS->Get('SEARCHCAP');

	$kakiko		= ($Kakiko == 1 ? 'checked' : '');
	$trip12		= ($Trip12 == 1 ? 'checked' : '');
	$torexit	= ($TOREXIT == 1 ? 'checked' : '');
	$spamhaus	= ($SYS->Get('DNSBL_SPAMHAUS') == 1 ? 'checked' : '');
	$s5h		= ($SYS->Get('DNSBL_S5H') == 1 ? 'checked' : '');
	$dronebl	= ($SYS->Get('DNSBL_DRONEBL') == 1 ? 'checked' : '');
	$admCap		= ($admCap == 1 ? 'checked' : '');
	$srcCap		= ($srcCap == 1 ? 'checked' : '');
	$bgdsl		= ($DSL == 1 ? 'checked' : '');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','SEC');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">２重かきこですか？？</td></tr>\n");
	$Page->Print("<tr><td>同じIPからの書き込みの文字数が変化しない場合規制する</td>");
	$Page->Print("<td><input type=checkbox name=KAKIKO $kakiko value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">短時間投稿規制</td></tr>\n");
	$Page->Print("<tr><td>短時間投稿規制秒数を入力(0で規制無効)</td>");
	$Page->Print("<td><input type=text size=60 name=SAMBATM value=\"$Samba\"></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">Samba規制</td></tr>\n");
	$Page->Print("<tr><td>Samba待機秒数デフォルト値を入力(0で規制無効)<br>");
	$Page->Print("<small>Sambaの設定は掲示板ごとに設定できます</small></td>");
	$Page->Print("<td><input type=text size=60  name=DEFSAMBA value=\"$DefSamba\"></td></tr>\n");
	$Page->Print("<tr><td>Samba奉仕時間(分)デフォルト値を入力</td>");
	$Page->Print("<td><input type=text size=60 name=DEFHOUSHI value=\"$DefHoushi\"></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">新仕様トリップ</td></tr>\n");
	$Page->Print("<tr><td>新仕様トリップ(12桁=SHA-1)を有効にする</td>");
	$Page->Print("<td><input type=checkbox name=TRIP12 $trip12 value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">DNSBL設定</td></tr>\n");
	$Page->Print("<tr><td colspan=2>適用するDNSBLにチェックをいれてください(規制を行う場合は各掲示板の設定で有効にしてください)<br>\n");
	$Page->Print("<input type=checkbox name=DNSBL_TOREXIT $torexit value=on>");
	$Page->Print("<a href=\"https://www.dan.me.uk/dnsbl\" target=\"_blank\">Dan.me.uk</a>(Tor出口ノード判定)\n");
	$Page->Print("<input type=checkbox name=DNSBL_SPAMHAUS $spamhaus value=on>");
	$Page->Print("<a href=\"https://www.spamhaus.org/\" target=\"_blank\">Spamhaus</a>\n");
	$Page->Print("<input type=checkbox name=DNSBL_S5H $s5h value=on>");
	$Page->Print("<a href=\"http://www.usenix.org.uk/content/rbl.html\" target=\"_blank\">S5H</a>\n");
	$Page->Print("<input type=checkbox name=DNSBL_DRONEBL $dronebl value=on>");
	$Page->Print("<a href=\"https://dronebl.org/\" target=\"_blank\">DroneBL</a>\n");
	$Page->Print("</td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">外部APIキー</td></tr>\n");
	$Page->Print("<tr><td>プロキシチェックAPI種別<br><td>");
	$Page->Print("<select name=PROXYCHECK_API required>");
	$Page->Print("<option value=\"\" $noApiSet>なし</option>");
	$Page->Print("<option value=\"proxycheck.io\" $pApiSet>ProxyCheck.io</option>");
	$Page->Print("<option value=\"ipqualityscore\" $IPApiSet>IPQS</option>");
	$Page->Print("<option value=\"ip2location\" $IP2ApiSet>IP2LOCATION.IO</option>");
	$Page->Print("<option value=\"abstract\" $AApiSet>Abstract</option>");
	$Page->Print("<option value=\"ipdata\" $IPDApiSet>ipdata</option>");
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td>APIキー</td>");
	$Page->Print("<td><input type=text size=60 name=PROXYCHECK_APIKEY value=\"$Proxy_apikey\"></td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">Captcha設定</td></tr>\n");
	$Page->Print("<tr><td>Captcha種別<br><td>");
	$Page->Print("<select name=CAPTCHA required>");
	$Page->Print("<option value=\"\" $noCapSet>なし</option>");
	$Page->Print("<option value=\"h-captcha\" $hCapSet>hCaptcha</option>");
	$Page->Print("<option value=\"g-recaptcha\" $reCapSet>reCAPTCHA v2</option>");
	$Page->Print("<option value=\"cf-turnstile\" $TurnSet>Turnstile</option>");
	$Page->Print("</select></td></tr>\n");
	#$Page->Print("<tr><td>(Turnstileのみ)IPの検証<br><td>");
	#$Page->Print("<select name=CAPTCHA_LENIENCY required disabled>");
	#$Page->Print("<option value=\"\" $noCapIP>なし</option>");
	#$Page->Print("<option value=\"relaxed\" $CapIPRelax>普通</option>");
	#$Page->Print("<option value=\"strict\" $CapIPStrict>厳格</option>");
	#$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td>Captchaサイトキー<br>");
	$Page->Print("<td><input type=text size=60  name=CAPTCHA_SITEKEY value=\"$Captcha_sitekey\"></td></tr>\n");
	$Page->Print("<tr><td>Captchaシークレットキー</td>");
	$Page->Print("<td><input type=text size=60 name=CAPTCHA_SECRETKEY value=\"$Captcha_secretkey\"></td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">Captchaを課すCGI</td></tr>\n");
	$Page->Print("<tr><td>admin.cgi</td>");
	$Page->Print("<td><input type=checkbox name=ADMINCAP $admCap value=on></td></tr>\n");
	$Page->Print("<tr><td>search.cgi</td>");
	$Page->Print("<td><input type=checkbox name=SEARCHCAP $srcCap value=on></td></tr>\n");
	$Page->Print("<tr><td>bbs.cgi</td>");
	$Page->Print("<td>各掲示板の設定で有効化してください</td></tr>\n");

	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">BoardGuard DSL（高度）</td></tr>\n");
	$Page->Print("<tr><td>条件付きユーザー規制を有効化する<br><small>注意：<a href=\"https://prefkarafuto.github.io/docs/bgdsl/\">");
	$Page->Print("このDSLの文法・機能</a>を十分に把握した上で使用してください。datやデータファイルが破損する恐れがあります。</small></td>\n");
	$Page->Print("<td><input type=checkbox name=BGDSL $bgdsl value=on></td></tr>\n");

	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintPluginSetting
{
	my ($Page, $SYS, $Form) = @_;
	my (@pluginSet, $num, $common, $Plugin);
	
	$SYS->Set('_TITLE', 'System Plugin Setting');
	$common = "onclick=\"DoSubmit('sys.setting','FUNC'";
	
	require './module/plugin.pl';
	$Plugin = PLUGIN->new;
	$Plugin->Load($SYS);
	$num = $Plugin->GetKeySet('ALL', '', \@pluginSet);
	
	# 拡張機能が存在する場合は有効・無効設定画面を表示
	if ($num > 0) {
		my ($id, $file, $class, $name, $expl, $v, $valid);
		
		$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
		$Page->Print("<tr><td colspan=5>有効にする機能にチェックを入れてください。<br>");
		$Page->Print("<br>※0.7.5以前のプラグイン及び旧ぜろちゃんねる用プラグインは使用できません。詳細はリリースノートを参照してください。</td></tr>\n");
		$Page->Print("<tr><td colspan=5><hr></td></tr>\n");
		$Page->Print("<tr>");
		$Page->Print("<td class=\"DetailTitle\">Order</td>");
		$Page->Print("<td class=\"DetailTitle\">Function Name</td>");
		$Page->Print("<td class=\"DetailTitle\">Explanation</td>");
		$Page->Print("<td class=\"DetailTitle\">File</td>");
		$Page->Print("<td class=\"DetailTitle\">Options</td></tr>\n");
		
		for my $i (0 .. $#pluginSet) {
			$id = $pluginSet[$i];
			$file = $Plugin->Get('FILE', $id);
			$class = $Plugin->Get('CLASS', $id);
			$name = $Plugin->Get('NAME', $id);
			$expl = $Plugin->Get('EXPL', $id);
			$v     = $Plugin->Get('VALID', $id);
			$valid = ($v == -1 && 'disabled') || ($v == 1  && 'checked') || '';
			$Page->Print("<tr><td><input type=text name=PLUGIN_${id}_ORDER value=@{[$i+1]} size=3></td>");
			$Page->Print("<td><label><input type=checkbox name=PLUGIN_VALID value=$id $valid> $name</label></td>");
			$Page->Print("<td>$expl</td><td>$file</td>");
			if ($class->can('getConfig') && scalar(keys %{$class->getConfig()}) > 0) {
				$Page->Print("<td><a href=\"javascript:SetOption('PLGID','$id');");
				$Page->Print("DoSubmit('sys.setting','DISP','PLUGINCONF');\">個別設定</a></td>");
			}
			else {
				$Page->Print("<td></td>");
			}
			$Page->Print("</tr>\n");
		}
		$Page->Print("<tr><td colspan=5><hr></td></tr>\n");
		$Page->Print("<tr><td colspan=5 align=left>");
		$Page->Print("<input type=button value=\"　設定　\" $common,'SET_PLUGIN');\"> ");
	}
	else {
		$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
		$Page->Print("<tr><td><hr></td></tr>\n");
		$Page->Print("<tr><td><b>プラグインは存在しません。</b></td></tr>\n");
		$Page->Print("<tr><td><hr></td></tr>\n");
		$Page->Print("<tr><td align=left>");
	}
		$Page->Print("<input type=hidden name=PLGID value=\"\">");
		$Page->Print("<input type=button value=\"　更新　\" $common,'UPDATE_PLUGIN');\">");
	$Page->Print("</td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#   拡張機能個別設定設定画面の表示
#   @param   $Page   ページコンテキスト
#   @param   $SYS    システム変数
#   @param   $Form   フォーム変数
#   @return  なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintPluginOptionSetting {
    my ($Page, $SYS, $Form) = @_;
    my ($common, $Plugin, $Config, %conftype);
    my ($id, $file, $className, $conf, $err);

    $id = $Form->Get('PLGID');

    require './module/plugin.pl';
    $Plugin = PLUGIN->new;
    $Plugin->Load($SYS);
    $Config = PLUGINCONF->new($Plugin, $id);

    $SYS->Set('_TITLE', 'System Plugin Option Setting - ' . $Plugin->Get('NAME', $id));
    $common = "onclick=\"DoSubmit('sys.setting','FUNC'";

	# 設定画面本体のレンダリング
    $Page->Print("<center><table border=0 cellspacing=2 width=100%>");
    $Page->Print("<tr><td colspan=4>個別設定</td></tr>\n");
    $Page->Print("<tr><td colspan=4><hr></td></tr>\n");
    $Page->Print("<tr>");
    $Page->Print("<td class=\"DetailTitle\">Name</td>");
    $Page->Print("<td class=\"DetailTitle\">Value</td>");
    $Page->Print("<td class=\"DetailTitle\" width=50%>Explanation</td>");
    $Page->Print("<td class=\"DetailTitle\">Type</td></tr>\n");

    %conftype = (
        0 => '変更不可',
        1 => '数値',
        2 => '文字列',
        3 => '真偽値',
    );

    # プラグイン .pl ファイル名
    $file = $Plugin->Get('FILE', $id);
	$err = '';
    my $load_ok = eval {
        require "./plugin/$file";
        1;
    };
    if (not $load_ok) {
        chomp($err = $@ || '不明なエラー');
    }

    # クラス名生成
    if ($file =~ /^0ch_(.*)_utf8\.pl$/) {
        $className = "ZPL_$1";
    }

    # getConfig 呼び出しも eval でガード
    if ($className->can('getConfig')) {
        my $conf_ok = eval {
            my $plugin = $className->new;
            $conf = $plugin->getConfig();
            1;
        };
        if (not $conf_ok) {
            chomp($err = $@ || '不明なエラー');
        }
    }

	if(!$err){
		if (defined $conf) {
			foreach my $key (sort keys %$conf) {
				my ($val, $type, $desc);
				$val  = $Config->GetConfig($key);
				$type = $conf->{$key}{valuetype};
				$desc = $conf->{$key}{description};

				# 特殊文字エスケープ
				$val =~ s/([\"<>\x5c])/\x5c$1/g if $type eq 2;

				$Page->Print("<tr><td>$key</td>");
				if ($type eq 3) {
					$Page->Print(
						"<td><input type=checkbox name=PLUGIN_OPT_"
						. unpack('H*', $key)
						. ($val ? ' checked' : '')
						. "></td>"
					);
				}
				elsif ($type eq 0) {
					$Page->Print("<td>$val</td>");
				}
				else {
					$Page->Print(
						"<td><input type=text name=PLUGIN_OPT_"
						. unpack('H*', $key)
						. " value=\"$val\" size=30></td>"
					);
				}
				$Page->Print("<td>$desc</td><td>$conftype{$type}</td></tr>\n");
			}
		}
	}else{
		$Page->Print("<tr><td>エラー</td><td>プラグインファイルにエラーがあります。</td><td>$err</td><td>システムメッセージ</td></tr>\n");
		$err = 'disabled';
	}

    $Page->Print("<tr><td colspan=4><hr></td></tr>\n");
    $Page->Print("<tr><td colspan=4 align=left>");
    $Page->Print("<input type=hidden name=PLGID value=\"$id\">");
    $Page->Print("<input type=button value=\"　設定　\" $common,'SET_PLUGINCONF');\" $err>");
    $Page->Print("</td></tr>");
    $Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能個別設定設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginOptionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($common, $Plugin, $Config, %conftype);
	my ($id, $file, $className, $plugin, $conf);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	
	$id = $Form->Get('PLGID');
	
	require './module/plugin.pl';
	$Plugin = PLUGIN->new;
	$Plugin->Load($Sys);
	$Config = PLUGINCONF->new($Plugin, $id);
	
	$file = $Plugin->Get('FILE', $id);
	require "./plugin/$file";
	$file =~ /^0ch_(.*)_utf8\.pl$/;
	$className = "ZPL_$1";
	$plugin = new $className;
	if ($className->can('getConfig')) {
		$conf = $plugin->getConfig();
	}
	
	if (defined $conf) {
		push @$pLog, "$className";
		foreach my $key (sort keys %$conf) {
			my ($val);
			$val = $Form->Get('PLUGIN_OPT_' . unpack('H*', $key));
			$Config->SetConfig($key, $val);
			push @$pLog, "$key を設定しました。";
		}
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	基本設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBasicSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = ('SERVER', 'CGIPATH', 'BBSPATH', 'INFO', 'DATA');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
	}
	require './module/system.pl';
	$SYSTEM = SYSTEM->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('SERVER', $Form->Get('SERVER'));
	$SYSTEM->Set('CGIPATH', $Form->Get('CGIPATH'));
	$SYSTEM->Set('BBSPATH', $Form->Get('BBSPATH'));
	$SYSTEM->Set('INFO', $Form->Get('INFO'));
	$SYSTEM->Set('DATA', $Form->Get('DATA'));
	$SYSTEM->Set('SITENAME', $Form->Get('SITENAME'));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ 基本設定';
		push @$pLog, '　　　 サーバ：' . $Form->Get('SERVER');
		push @$pLog, '　　　 CGIパス：' . $Form->Get('CGIPATH');
		push @$pLog, '　　　 掲示板パス：' . $Form->Get('BBSPATH');
		push @$pLog, '　　　 管理データフォルダ：' . $Form->Get('INFO');
		push @$pLog, '　　　 基本データフォルダ：' . $Form->Get('DATA');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	パーミッション設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPermissionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/system.pl';
	$SYSTEM = SYSTEM->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('PM-DAT', oct($Form->Get('PERM_DAT')));
	$SYSTEM->Set('PM-TXT', oct($Form->Get('PERM_TXT')));
	$SYSTEM->Set('PM-LOG', oct($Form->Get('PERM_LOG')));
	$SYSTEM->Set('PM-ADM', oct($Form->Get('PERM_ADMIN')));
	$SYSTEM->Set('PM-STOP', oct($Form->Get('PERM_STOP')));
	$SYSTEM->Set('PM-ADIR', oct($Form->Get('PERM_ADMIN_DIR')));
	$SYSTEM->Set('PM-BDIR', oct($Form->Get('PERM_BBS_DIR')));
	$SYSTEM->Set('PM-LDIR', oct($Form->Get('PERM_LOG_DIR')));
	$SYSTEM->Set('PM-KDIR', oct($Form->Get('PERM_KAKO_DIR')));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ 基本設定';
		push @$pLog, '　　　 datパーミッション：' . $Form->Get('PERM_DAT');
		push @$pLog, '　　　 txtパーミッション：' . $Form->Get('PERM_TXT');
		push @$pLog, '　　　 logパーミッション：' . $Form->Get('PERM_LOG');
		push @$pLog, '　　　 管理ファイルパーミッション：' . $Form->Get('PERM_ADMIN');
		push @$pLog, '　　　 停止スレッドパーミッション：' . $Form->Get('PERM_STOP');
		push @$pLog, '　　　 管理DIRパーミッション：' . $Form->Get('PERM_ADMIN_DIR');
		push @$pLog, '　　　 掲示板DIRパーミッション：' . $Form->Get('PERM_BBS_DIR');
		push @$pLog, '　　　 ログDIRパーミッション：' . $Form->Get('PERM_LOG_DIR');
		push @$pLog, '　　　 倉庫DIRパーミッション：' . $Form->Get('PERM_KAKO_DIR');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	制限値設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLimitterSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/system.pl';
	$SYSTEM = SYSTEM->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('RESMAX', $Form->Get('RESMAX'));
	$SYSTEM->Set('SUBMAX', $Form->Get('SUBMAX'));
	$SYSTEM->Set('ANKERS', $Form->Get('ANKERS'));
	$SYSTEM->Set('ERRMAX', $Form->Get('ERRMAX'));
	$SYSTEM->Set('HSTMAX', $Form->Get('HSTMAX'));
	$SYSTEM->Set('ADMMAX', $Form->Get('ADMMAX'));
	$SYSTEM->Set('FLRMAX', $Form->Get('FLRMAX'));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ 基本設定';
		push @$pLog, '　　　 subject最大数：' . $Form->Get('SUBMAX');
		push @$pLog, '　　　 レス最大数：' . $Form->Get('RESMAX');
		push @$pLog, '　　　 アンカー最大数：' . $Form->Get('ANKERS');
		push @$pLog, '　　　 エラーログ最大数：' . $Form->Get('ERRMAX');
		push @$pLog, '　　　 ホストログ最大数：' . $Form->Get('HSTMAX');
		push @$pLog, '　　　 管理操作ログ最大数：' . $Form->Get('ADMMAX');
		push @$pLog, '　　　 ユーザ書き込み失敗ログ最大数：' . $Form->Get('FLRMAX');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionOtherSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/system.pl';
	$SYSTEM = SYSTEM->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('HEADTEXT', $Form->Get('HEADTEXT'));
	$SYSTEM->Set('HEADURL', $Form->Get('HEADURL'));
	$SYSTEM->Set('URLLINK', ($Form->Equal('URLLINK', 'on') ? 'TRUE' : 'FALSE'));
	$SYSTEM->Set('LINKST', $Form->Get('LINKST'));
	$SYSTEM->Set('LINKED', $Form->Get('LINKED'));
	$SYSTEM->Set('PATHKIND', $Form->Get('PATHKIND'));
	$SYSTEM->Set('IMGTAG', ($Form->Equal('IMGTAG', 'on') ? 1 : 0));
	$SYSTEM->Set('FASTMODE', ($Form->Equal('FASTMODE', 'on') ? 1 : 0));
	$SYSTEM->Set('UPCHECK', $Form->Get('UPCHECK'));
	$SYSTEM->Set('NINLVMAX', $Form->Get('NINLVMAX'));
	$SYSTEM->Set('NIN_EXPIRY', $Form->Get('NIN_EXPIRY'));
	$SYSTEM->Set('PASS_EXPIRY', $Form->Get('PASS_EXPIRY'));
	$SYSTEM->Set('COOKIE_EXPIRY', $Form->Get('COOKIE_EXPIRY'));
	$SYSTEM->Set('AUTH_EXPIRY', $Form->Get('AUTH_EXPIRY'));
	$SYSTEM->Set('LOGOUT', $Form->Get('LOGOUT'));
	$SYSTEM->Set('CM_THEME', $Form->Get('CM_THEME'));
	$SYSTEM->Set('CSP', ($Form->Equal('CSP', 'on') ? 1 : 0));
	$SYSTEM->Set('IMGUR_ID', $Form->Get('IMGUR_ID'));
	$SYSTEM->Set('IMGUR_SECRET', $Form->Get('IMGUR_SECRET'));
	$SYSTEM->Set('UPLOAD', $Form->Get('UPLOAD'));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ その他設定';
		push @$pLog, '　　　 ヘッダテキスト：' . $SYSTEM->Get('HEADTEXT');
		push @$pLog, '　　　 ヘッダURL：' . $SYSTEM->Get('HEADURL');
		push @$pLog, '　　　 Imgurのみ変換許可：' . $SYSTEM->Get('IMGTAG');
		push @$pLog, '　　　 画像アップロード：' . $SYSTEM->Get('UPLOAD');
		push @$pLog, '　　　 URL自動リンク：' . $SYSTEM->Get('URLLINK');
		push @$pLog, '　　　 　開始時間：' . $SYSTEM->Get('LINKST');
		push @$pLog, '　　　 　終了時間：' . $SYSTEM->Get('LINKED');
		push @$pLog, '　　　 PATH種別：' . $SYSTEM->Get('PATHKIND');
		push @$pLog, '　　　 index.htmlを更新しない：' . $SYSTEM->Get('FASTMODE');
		push @$pLog, '　　　 Cookie有効期限：' . $SYSTEM->Get('COOKIE_EXPIRY');
		push @$pLog, '　　　 認証有効期限：' . $SYSTEM->Get('AUTH_EXPIRY');
		push @$pLog, '　　　 忍法帖最大レベル：' . $SYSTEM->Get('NINLVMAX');
		push @$pLog, '　　　 忍法帖データ保持期間：' . $SYSTEM->Get('NIN_EXPIRY');
		push @$pLog, '　　　 パスワード設定時保持期間：' . $SYSTEM->Get('PASS_EXPIRY');
		push @$pLog, '　　　 更新チェック間隔：' . $SYSTEM->Get('UPCHECK');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示設定(EXぜろちゃんねるオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusViewSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/system.pl';
	$SYSTEM = SYSTEM->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('COUNTER', $Form->Get('COUNTER'));
	$SYSTEM->Set('PRTEXT', $Form->Get('PRTEXT'));
	$SYSTEM->Set('PRLINK', $Form->Get('PRLINK'));
	my $banner = ($Form->Equal('BANNERINDEX', 'on')?2:0) | ($Form->Equal('BANNER', 'on')?4:0);
	$SYSTEM->Set('BANNER', $banner);
	$SYSTEM->Set('MSEC', ($Form->Equal('MSEC', 'on') ? 1 : 0));
	$SYSTEM->Set('HIDE_HITS', ($Form->Equal('HIDE_HITS', 'on') ? 0 : 1));
	$SYSTEM->Set('REFRESH_MODE', $Form->Get('REFRESH_MODE'));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '　　　 カウンターアカウント：' . $SYSTEM->Get('COUNTER');
		push @$pLog, '　　　 PR欄表示文字列：' . $SYSTEM->Get('PRTEXT');
		push @$pLog, '　　　 PR欄リンクURL：' . $SYSTEM->Get('PRLINK');
		push @$pLog, '　　　 バナー表示：' . $SYSTEM->Get('BANNER');
		push @$pLog, '　　　 ミリ秒表示：' . $SYSTEM->Get('MSEC');
		push @$pLog, '　　　 規制情報公開：' . $SYSTEM->Get('HIDE_HITS');
		push @$pLog, '　　　 書き込み後遷移先：' . $SYSTEM->Get('REFRESH_MODE');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	規制設定(EXぜろちゃんねるオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusSecSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/system.pl';
	$SYSTEM = SYSTEM->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('KAKIKO', ($Form->Equal('KAKIKO', 'on') ? 1 : 0));
	$SYSTEM->Set('SAMBATM', $Form->Get('SAMBATM'));
	$SYSTEM->Set('DEFSAMBA', $Form->Get('DEFSAMBA'));
	$SYSTEM->Set('DEFHOUSHI', $Form->Get('DEFHOUSHI'));
	$SYSTEM->Set('TRIP12', ($Form->Equal('TRIP12', 'on') ? 1 : 0));
	$SYSTEM->Set('DNSBL_TOREXIT', ($Form->Equal('DNSBL_TOREXIT', 'on') ? 1 : 0));
	$SYSTEM->Set('DNSBL_SPAMHAUS', ($Form->Equal('DNSBL_SPAMHAUS', 'on') ? 1 : 0));
	$SYSTEM->Set('DNSBL_S5H', ($Form->Equal('DNSBL_S5H', 'on') ? 1 : 0));
	$SYSTEM->Set('DNSBL_DRONEBL', ($Form->Equal('DNSBL_DRONEBL', 'on') ? 1 : 0));
	$SYSTEM->Set('CAPTCHA', $Form->Get('CAPTCHA'));
	$SYSTEM->Set('CAPTCHA_LENIENCY', $Form->Get('CAPTCHA_LENIENCY'));
	$SYSTEM->Set('CAPTCHA_SITEKEY', $Form->Get('CAPTCHA_SITEKEY'));
	$SYSTEM->Set('CAPTCHA_SECRETKEY', $Form->Get('CAPTCHA_SECRETKEY'));
	$SYSTEM->Set('PROXYCHECK_API', $Form->Get('PROXYCHECK_API'));
	$SYSTEM->Set('PROXYCHECK_APIKEY', $Form->Get('PROXYCHECK_APIKEY'));
	$SYSTEM->Set('ADMINCAP', ($Form->Equal('ADMINCAP', 'on') ? 1 : 0));
	$SYSTEM->Set('SEARCHCAP', ($Form->Equal('SEARCHCAP', 'on') ? 1 : 0));
	$SYSTEM->Set('BGDSL', ($Form->Equal('BGDSL', 'on') ? 1 : 0));
	$SYSTEM->Save();
	
	{
		push @$pLog, '　　　 2重カキコ規制：' . $SYSTEM->Get('KAKIKO');
		push @$pLog, '　　　 連続投稿規制秒数：' . $SYSTEM->Get('SAMBATM');
		push @$pLog, '　　　 Samba待機秒数：' . $SYSTEM->Get('DEFSAMBA');
		push @$pLog, '　　　 Samba奉仕時間：' . $SYSTEM->Get('DEFHOUSHI');
		push @$pLog, '　　　 12桁トリップ：' . $SYSTEM->Get('TRIP12');
		push @$pLog, '　　　 Dan.me.uk：' . $SYSTEM->Get('DNSBL_TOREXIT');
		push @$pLog, '　　　 Captchaサイトキー：' . $SYSTEM->Get('CAPTCHA_SITEKEY');
		push @$pLog, '　　　 Captchaシークレットキー：' . $SYSTEM->Get('CAPTCHA_SECRETKEY');
		push @$pLog, '　　　 ProxyChecker APIキー：' . $SYSTEM->Get('PROXYCHECK_APIKEY');
		push @$pLog, '　　　 admin.cgiへのCaptcha：' . $SYSTEM->Get('ADMINCAP');
		push @$pLog, '　　　 search.cgiへのCaptcha：' . $SYSTEM->Get('SEARCHCAP');
		push @$pLog, '　　　 BoardGuard DSL：' . $SYSTEM->Get('BGDSL');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Plugin);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/plugin.pl';
	$Plugin = PLUGIN->new;
	$Plugin->Load($Sys);
	
	my (@pluginSet, @validSet, %order);
	
	$Plugin->GetKeySet('ALL', '', \@pluginSet);
	@validSet = $Form->GetAtArray('PLUGIN_VALID');
	
	for my $i (0 .. $#pluginSet) {
		my $id = $pluginSet[$i];
		my $valid = 0;
		foreach (@validSet) {
			if ($_ eq $id) {
				$valid = 1;
				last;
			}
		}
		
		if($Plugin->Get('TYPE', $id) & 64)
		{
			# パッチ用
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			
			require "./plugin/$file";
			my $Config = PLUGINCONF->new($Plugin, $id);
			my $command = $className->new($Config);
			my $status = $Config->GetConfig('patch_status');
			my $result = $command->execute($Sys, $Form, 64);

			if($result){
				push @$pLog, 'パッチ '.$Plugin->Get('NAME', $id) . 'の適用に失敗しました。' if $valid;
			}else{
				push @$pLog, 'パッチ '.$Plugin->Get('NAME', $id) . ($status ? ' は適用済みです。':' を適用しました。') if $valid;
			}
		}else{
			push @$pLog, $Plugin->Get('NAME', $id) . ' を' . ($valid ? '有効' : '無効') . 'に設定しました。';
		}

		$Plugin->Set($id, 'VALID', $valid);
		
		$_ = $Form->Get("PLUGIN_${id}_ORDER", $i + 1);
		$_ = $i + 1 if ($_ ne ($_ - 0));
		$_ -= 0;
		$order{$_} = [] if (! exists $order{$_});
		push @{$order{$_}}, $id;
	}
	$Plugin->{'ORDER'} = [];
	push @{$Plugin->{'ORDER'}}, @{$order{$_}} foreach (sort {$a <=> $b} keys %order);
	$Plugin->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Plugin, $errors_ref);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/plugin.pl';
	$Plugin = PLUGIN->new;
	
	# 情報の更新と保存
	$Plugin->Load($Sys);
	$errors_ref = $Plugin->Update();
	if (%$errors_ref) {
		foreach my $id (keys %$errors_ref) {
			$Plugin->Set($id, 'VALID', -1);
		}
	}
	$Plugin->Save($Sys);
	
	# ログの設定
	{
		push @$pLog, '■ プラグイン情報の更新';
		if (%$errors_ref) {
			push @$pLog, '[以下のプラグインでエラーが発生しています。]';
			foreach my $id (keys %$errors_ref) {
				push @$pLog, "Plugin ID $id: $errors_ref->{$id}\n";
			}
		}
		push @$pLog, '　プラグイン情報の更新を完了しました。';
	}
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
