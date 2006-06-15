#!/opt/local/bin/perl

use strict;
use FEAR::API -base;

my $output_file = io('output.buy-yahoo-tw');

url('http://buy.yahoo.com.tw/');

extmethod('Regexp::GlobalBind');
while ( has_more_links ) {
    fetch >> [
	      qr(gdid=\d+$) => sub {
		  fetch($_[0]) >> [ qr(gdid=\d+$) => _self ];
 		  template(qr(<!--st_catrank-->.+?<img src="(?#<image>http://211.78.161.57/res/gdsale/st_pic/.+?\.jpg)".+?<!--gd_name_start-->(?#<product_name>.+?)<!--gd_name_end-->.+?<div align="left"><span id="TOTAL_Price_CARD" class="price_s">(?#<price>\d+)</span>)s);
		  extract;
		  result_filter('$_->{product_name} =~ s/[\r\t\n]+//g');
		  invoke_handler(sub {
				     print Dump $_;
 				     $output_file->println(Dump $_);
				 });
	      },
	      qr(catid=\d+$) => _self,
	     ];
}

