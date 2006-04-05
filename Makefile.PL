use inc::Module::Install;

name            ('FEAR-API');
abstract        ("There's no fear with this elegant site scraper");
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
reuiqres  ('HTTP::Proxy');
reuiqres  ('HTTP::Recorder');
requires  ('Inline');
requires  ('Inline::Files');
requires  ('IO::All');
requires  ('IO::String');
requires  ('IPC::SysV');
requires  ('Parallel::ForkManager');
requires  ('Regexp::Bind');
requires  ('Regexp::Common');
requires  ('Sort::Versions');
requires  ('Spiffy');
requires  ('Template');
requires  ('Template::Extract');
requires  ('Text::CSV');
requires  ('Text::Iconv');
requires  ('WWW::Mechanize');
requires  ('XML::XPath');
requires  ('YAML');

recommends  ('Tie::ShareLite');

build_requires  ('Test::More');
install_script  ('bin/fearperl');
install_script  ('bin/fear-recorder');
auto_install();

&WriteAll;

