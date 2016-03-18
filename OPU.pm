package Parsers::TargetParser::ILLiad::DDL;

#============================================================#
# Version: $Id: DDL.pm,v 1.13 2015/05/11 03:55:22 eldada Exp $
#============================================================#

# a little bit of the parser logic
#There are several rules:
#1.      if rft.object_type contain the string "PROCEEDING" and rft.isbn or rft.isbn13 exists rft.genre will be "article" (in order to prevent from Sp change the genre to book.
#2.      if rft.doi exist then will add "id=doi:< rft.doi>".
#3.      
#a.      if rft.genre is "book" and rft_val_fmt doesn't contain the string "dissertation" then rft.title will get the value of rft.btitle if rft.btitle exist.
#b.      Otherwise, if rft.genre is "book" and rft_val_fmt contain the string "dissertation" then rft.title will get the value of rft.title.
#c.      Otherwise, if if rft.genre is "journal" or "article" then rft.title will get the value of rft.jtitle.
#4. if the genre is book and the type is not dissertation then rft.btitle (and not rft.title) will store the rft.btitle

#=====================================================================================

use strict;
use base qw(Parsers::TargetParser);
use NetWrap::Escape qw(uri_escape);
use URI;
use Encode 'decode_utf8';

sub getDocumentDelivery 
{
	my ($this)  = @_;
	my $ctx_obj = $this->{'ctx_obj'};
	my $svc     = $this->{'svc'};
	my $doi     = $ctx_obj->get('rft.doi')     || '';
	my $id_type = $svc->parse_param('id_type') || '';
	my $host    = $svc->parse_param('url')     || '';
	my $doiurl  = $ctx_obj->get('sfx.doi_url') || '';;
	my %query   = ();
	my $uri     = '';
        my $openurl = $ctx_obj->get('sfx.openurl') || '';
        
        my %genre_map = (   journal     => 1,
                            article     => 1,
                            issue       => 1,
                            book        => 1,
                            bookitem    => 1,
                            report      => 1,
                            document    => 1,
                            patent      => 1
                    ) ; 
	
	$query{'Action'} = 10;
	$query{'Form'} = 30;

	if(($ctx_obj->get('@rft.aulast')) && $ctx_obj->get('@rft.aulast')->[0]){
		$query{'rft.aulast'}  = $ctx_obj->get('@rft.aulast')->[0];
	}
	if(($ctx_obj->get('@rft.aufirst')) && $ctx_obj->get('@rft.aufirst')->[0]){
		$query{'rft.aufirst'} = $ctx_obj->get('@rft.aufirst')->[0];
	}
	if(($ctx_obj->get('@rft.auinitm')) && $ctx_obj->get('@rft.auinitm')->[0]){
		$query{'rft.auinitm'} = $ctx_obj->get('@rft.auinitm')->[0];
	}
	if(($ctx_obj->get('@rft.auinit')) && $ctx_obj->get('@rft.auinit')->[0]){
		$query{'rft.auinit'}  = $ctx_obj->get('@rft.auinit')->[0];
	}
	if(($ctx_obj->get('@rft.auinit1')) && $ctx_obj->get('@rft.auinit1')->[0]){
		$query{'rft.auinit1'} = $ctx_obj->get('@rft.auinit1')->[0];
	}
	if(($ctx_obj->get('@rfr_id')) && $ctx_obj->get('@rfr_id')->[0]){
		my $rfr_id = $ctx_obj->get('@rfr_id')->[0];
		$rfr_id =~ s/'//g;
		$query{'rfr_id'} = $rfr_id . "(Via SFX)";
	}
	if(($ctx_obj->get('@rft.stitle')) && $ctx_obj->get('@rft.stitle')->[0]){
		$query{'rft.stitle'}  = $ctx_obj->get('@rft.stitle')->[0];
	}
	
	$query{'rft.doi'}       = $ctx_obj->get('rft.doi')       if($ctx_obj->get('rft.doi'));
	$query{'rft.isbn'}      = $ctx_obj->get('rft.isbn')      if($ctx_obj->get('rft.isbn'));
	$query{'rft.isbn13'}    = $ctx_obj->get('rft.isbn13')    if($ctx_obj->get('rft.isbn13'));
	$query{'rft.eisbn'}     = $ctx_obj->get('rft.eisbn')     if($ctx_obj->get('rft.eisbn'));
	$query{'rft.eisbn13'}   = $ctx_obj->get('rft.eisbn13')   if($ctx_obj->get('rft.eisbn13'));
	$query{'rft.genre'}     = $ctx_obj->get('rft.genre')     || '';
	$query{'rft.date'}      = $ctx_obj->get('rft.date')      if($ctx_obj->get('rft.date'));
	$query{'rft.date'}      = $ctx_obj->get('rft.year')      if(!$query{'rft.date'} && $ctx_obj->get('rft.year'));
	$query{'rft.atitle'}    = $ctx_obj->get('rft.atitle')    if($ctx_obj->get('rft.atitle'));
	$query{'rft.issue'}     = $ctx_obj->get('rft.issue')     if($ctx_obj->get('rft.issue'));
	$query{'rft.volume'}    = $ctx_obj->get('rft.volume')    if($ctx_obj->get('rft.volume'));
	$query{'rft.epage'}     = $ctx_obj->get('rft.epage')     if($ctx_obj->get('rft.epage'));
	$query{'rft.spage'}     = $ctx_obj->get('rft.spage')     if($ctx_obj->get('rft.spage'));
	
    #set the rfe_dat accordingly to the xml tag name and its value
	if($ctx_obj->get('rfe_dat') =~ /<(.+?)>(.+?)<\/(.+?)>/){
		$query{'rfe_dat'} = "$1=$2" if($1 eq $3);  
	}
	
	$query{'url_ver'}       = $ctx_obj->get('url_ver')       if($ctx_obj->get('url_ver'));
    $query{'linktype'}      = "openurl";
	$query{'rft.aucorp'}    = $ctx_obj->get('rft.aucorp')    if($ctx_obj->get('rft.aucorp'));
    $query{'rft.place'}     = $ctx_obj->get('rft.place')     if($ctx_obj->get('rft.place'));
    $query{'rft.pub'}       = $ctx_obj->get('rft.pub')       if($ctx_obj->get('rft.pub'));
	$query{'rft.issn'}      = $ctx_obj->get('rft.issn')      if($ctx_obj->get('rft.issn'));
	$query{'rft.month'}     = $ctx_obj->get('rft.month')     if($ctx_obj->get('rft.month'));
	$query{'rft.eissn'}     = $ctx_obj->get('rft.eissn')     if($ctx_obj->get('rft.eissn'));
	$query{'rft.pmid'}      = $ctx_obj->get('rft.pmid')      if($ctx_obj->get('rft.pmid'));
	$query{'rft.ED_NUMBER'} = $ctx_obj->get('rft.ED_NUMBER') if($ctx_obj->get('rft.ED_NUMBER'));
	

	my $type = $ctx_obj->get('rft_val_fmt');
	$query{'rft_val_fmt'} = ($type =~ /fmt:kev:mtx/) ? $type : "info:ofi/fmt:kev:mtx:$type";

	my ($openurl_genre) = $openurl =~ /rft\.genre=(.*?)(&|$)/;
        $openurl_genre = lc($openurl_genre);
        if (!$openurl_genre && $openurl =~ /(&|\?)genre=(.*?)(&|$)/){
            $openurl_genre = $2;
        }
        my $ctx_genre = $ctx_obj->get('rft.genre') || '';
        $ctx_genre = lc($ctx_genre);

        if ($openurl_genre && $genre_map{$openurl_genre}){
            $query{'rft.genre'} = $openurl_genre;                
        }
        elsif ($ctx_genre && $genre_map{$ctx_genre}){
            $query{'rft.genre'} = $ctx_genre;
        }
	elsif($ctx_obj->get('rft.object_type') =~ /PROCEEDING/i && ($query{'rft.isbn'} || $query{'rft.isbn13'})){
		$query{'rft.genre'} = "article";
	}
	elsif ( $query{'rft.atitle'} && $ctx_obj->get('rft.btitle') ){
		$query{'rft.genre'} = "bookitem";
	}
	elsif(!$query{'rft.issn'}&& !$query{'rft.isbn'}&& !$query{'rft.isbn13'} && $query{'rft.pmid'}){
		$query{'rft.genre'} = "article";
	}
	
	if ($id_type && lc($id_type) eq 'doi' && $query{'rft.doi'}){
		$query{'id'} = $query{'rft.doi'};
	}
	elsif($id_type && lc($id_type) eq 'pmid' && $query{'rft.pmid'}){
		$query{'id'} = $query{'rft.pmid'};
	}
	elsif($query{'rft.pmid'}){
		$query{'id'} = $query{'rft.pmid'};
	}
	elsif($query{'rft.doi'}){
		$query{'id'} = $query{'rft.doi'};
	}


	if(($query{'rft.genre'} eq "book" && (!$type || $type !~ /dissertation/)) || $query{'rft.genre'} eq "bookitem"){
		if ($ctx_obj->get('rft.btitle')) { $query{'rft.btitle'} =  $ctx_obj->get('rft.btitle'); }
		elsif ($ctx_obj->get('rft.title')) { $query{'rft.btitle'} =  $ctx_obj->get('rft.title'); }
	
		#$query{'rft.btitle'} =  $ctx_obj->get('rft.btitle') if($ctx_obj->get('rft.btitle'));
	}
	elsif($query{'rft.genre'} eq "book"){
		$query{'rft.title'}  =  $ctx_obj->get('rft.title')  if($ctx_obj->get('rft.title'));
	}
	elsif($query{'rft.genre'} eq "journal" || $query{'rft.genre'} eq "article"){
		$query{'rft.title'}  =  $ctx_obj->get('rft.jtitle') if($ctx_obj->get('rft.jtitle'));
	}
	elsif($ctx_obj->get('rft.title')||$ctx_obj->get('rft.jtitle')||$ctx_obj->get('rft.btitle')||$ctx_obj->get('rft.ctitle')){
		$query{'rft.title'}  = $ctx_obj->get('rft.title')  || 
							   $ctx_obj->get('rft.jtitle') || 
							   $ctx_obj->get('rft.btitle') || 
							   $ctx_obj->get('rft.ctitle') 
	}	

	if($ctx_obj->get('rft.language') eq 'chi'){
		$query{'rft.title'} = decode_utf8($query{'rft.title'}) if($query{'rft.title'});
		$query{'rft.btitle'} = decode_utf8($query{'rft.btitle'}) if($query{'rft.btitle'});
	}
	$uri = URI->new($host);
	$uri->query_form(%query);
	return ($uri);


}
1;                                                         

