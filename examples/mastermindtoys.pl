#!/opt/local/bin/perl

use strict;
use FEAR::API -base;

my $output_file = io('output.mastermindtoys');

url('http://www.mastermindtoys.com/');

extmethod('Regexp::GlobalBind');

while ( has_more_links ) {
    fetch >> [
	      qr(product\.asp\?product_code) => sub {
		  fetch($_[0]) >> [ qr(product_code) => _self ];
 		  template(qr(<img src="(?#<image>/store[^>]+?gif)" alt="(?#<product_name>.+?)" height="250" width="250" border="0">.+?<span style="color:#990000;font-size:20px;"><b>\$(?#<price>[\d\.,]+)</b>&nbsp;)so);
		  extract;
		  absolutize_url('image');
		  invoke_handler(sub {
				     print Dump $_;
				     $output_file->println(Dump $_);
				 });
	      },
	      qr(category\.asp\?cat=\d+) => _self,
	     ];
}

