#!/opt/local/bin/perl

use strict;
use FEAR::API -base;

my %prod_id;
my $output_file = io('output.ecost');

url('http://www.ecost.com/ecost/ecsplash/shop/detail~dpno~604639.asp');

extmethod('Regexp::GlobalBind');
while ( has_more_links ) {
    fetch >> [
	      qr(shop/detail~dpno~) => sub {
		  return if $_[0]->url =~ /detail~dpno~(\d+)~/ and $prod_id{$1};
		  $prod_id{$1} = 1;
		  fetch($_[0]) >> [ qr(shop/detail~dpno~) => _self ];
		  template(qr(<img src="(?#<image>http://eimages.ecost.com/prod/.+?jpg)".+?NAME="LRGMerchandiseImage".+?border="0" onError=".+?<td height="19" colspan="4" class="lbluebold">(?#<product_name>.+?)</strong></td>.+?<td colspan="" align="center" nowrap class="detailPageBargainCountdownPrice"><b>\$(?#<price>[\d,\.]+?)</b></td>)s);
		  extract;
		  postproc('$_->{product_name} =~ s([\r\n\t])()g;');
		  invoke_handler(sub {
				     print Dump $_;
				     $output_file->println(Dump $_);
				 });
	      },
	      qr(shop/category~eStore.+asp) => _self,
	     ];
}

