package CPAN::DBI;
use base 'Class::DBI::SQLite';
__PACKAGE__->set_db('Main', 'dbi:SQLite:dbname=t/data/cpan.db', '', '');
__PACKAGE__->set_up_table('cpan');
1;
