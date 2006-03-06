use inc::Module::Install;

name            ('FEAR-API');
abstract        ('An elegant site scraper');
author          ('Yung-chung Lin <xern@cpan.org>');
version_from    ('lib/FEAR/API.pm');
license         ('perl');

requires  ('Compress::Zlib');
requires  ('DB_File');
requires  ('Digest::MD5');
requires  ('Email::Find');
requires  ('File::MMagic');
requires  ('File::Slurp');
requires  ('File::Temp');
requires  ('Filter::Simple');
requires  ('HTML::Encoding');
requires  ('HTML::Entities');
requires  ('HTML::LinkExtractor');
requires  ('Inline');
requires  ('Inline::Files');
requires  ('IO::All');
requires  ('IO::String');
requires  ('IPC::SysV');
requires  ('Regexp::Bind');
requires  ('Regexp::Common');
requires  ('Spiffy');
requires  ('Template');
requires  ('Template::Extract');
requires  ('Tie::ShareLite');
requires  ('WWW::Mechanize');
requires  ('XML::XPath');
requires  ('YAML');

build_requires  ('Test::More');
install_script  ('bin/fearperl');
auto_install();

&WriteAll;

