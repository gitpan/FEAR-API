######################################################################
#       FEAR is for Fetch, Extract, Aggregate, and Reorganize        #
######################################################################
package FEAR::API;
$|++;
use strict;
no warnings 'redefine';

our $VERSION = '0.485';

use utf8;
our @EXPORT
  =
  (
   qw(
      fear
      io
      @default_query_terms
      Dumper
      Dump
     ),
     qw(
	_template
	_preproc
	_postproc
	_doc_filter
	_result_filter
	_export
	_foreach
	_foreach_result
	_save_as
	_save_as_tree
	_keep_links
	_remove_links
	_print
	_feedback
	_self
	_local_links
	_grep
	_map
	_sort
	_uniq
       )
  );




#================================================================================
# Dependencies
#================================================================================
use Spiffy -base;
use FEAR::API::Closure -base;
use FEAR::API::Agent;
use FEAR::API::Document;
use FEAR::API::Extract;
use FEAR::API::Filters;
use FEAR::API::Link;
use FEAR::API::Log;
use FEAR::API::SourceFilter;
use FEAR::API::Translate -base;
use FEAR::API::ChksumRepos;

require URI::URL;
use Carp;
use Cwd;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_hex);
use Encode;
use File::Path;
use File::Slurp;
use File::Spec::Functions qw(catfile splitpath rel2abs);
use Inline::Files::Virtual;
use IO::All;
use IPC::SysV qw(IPC_RMID);
use List::Util;
use Parallel::ForkManager;
use Storable qw(dclone freeze thaw);
use Switch;
use Template;
use Text::CSV;
use URI;
use URI::Split;
use URI::WithBase;
use URI::Escape;
use YAML;
sub LOCK_EX() {};
eval 'use Tie::ShareLite qw( :lock );';


#================================================================================
# Overloaded operators.
#================================================================================


use overload
  q/&{}/ => 'ol_subref',
  q/@{}/ => 'ol_aryref',
  q/${}/ => 'ol_scalarref',
  q/""/  => 'ol_quote',
  q/>/   => 'ol_redirect_to',
  q/</   => 'ol_redirect_from',
  q/+=/  => 'ol_push_url',
  q/-=/  => 'ol_remove_url',
  q'|'   => 'ol_filter',
  q/<>/  => 'ol_iter',
  q/>>/  => 'ol_dispatch_links',
  q/bool/=> 'ol_bool',
  q/++/  => 'ol_incr',
  q/--/  => 'ol_decr',
  fallback => 1,
  ;

const _feedback => 'feedback';
const _self => 'feedback';
const _local_links => '_local_links';


sub ol_incr {
  $self->push_document;
}

sub ol_decr {
  $self->pop_document;
}

sub ol_dispatch_links {
  my $ref = ref $_[0];
  if($ref eq 'ARRAY'){
    $self->fallthrough_report(0);
    $self->dispatch_links(@{$_[0]});
  }
  elsif($ref eq 'HASH'){
    $self->fallthrough_report(1);
    $self->dispatch_links(%{$_[0]});
  }
  elsif($ref eq 'FEAR::API'){
    push @{$_[0]->{url}}, $self->links;
  }
  elsif($ref eq 'IO::All'){ # however, this is not about links
    $_[0]->append($self->document->as_string);
  }
  elsif($_[0] eq _feedback){
    $self->push_all_links();
  }
  $self;
}

sub _preproc($;$)     {  [ sub { shift->preproc(@{shift()}) } => \@_ ] }
_alias _doc_filter => '_preproc';

sub _postproc($;$@)    {  [ sub { shift->postproc(@{shift()})} => \@_ ] }
_alias _result_filter => '_postproc';

sub _template($)      {  [ sub { shift->template(@{shift()})->extract } => \@_ ] }
_alias _extract => '_template';

sub _save_as($)       {  [ sub { shift->save_to_file(shift()) } => $_[0] ]      }
sub _save_as_tree(;$) {  [ sub { shift->save_as_tree(shift()) }=> $_[0] ]      }
sub _print()            {  [ sub {
			     my $self = shift;
			     if($_[0]){
			       if(ref($_[0]) eq 'SCALAR'){
				 ${$_[0]} = $self->document->as_string;
			       }
			       elsif(ref $_[0] eq 'GLOB'){
				 print { *{$_[0]} } $self->document->as_string;
			       }
			       else {
				 print { $_[0] } $self->document->as_string;
			       }
			     }
			     else {
			       &print( $self->document->as_string );
			     }
			   }, $_[0]  ] }
sub _keep_links()     {  [ sub { shift->keep_links(shift()) } , \@_ ]   }
sub _remove_links()   {  [ sub { shift->remove_links(shift()) }, \@_ ] }
sub _export($$)       {  [ sub {
			     my $self = shift;
			     my $field = $_[0]->[0];
			     my $varref = $_[0]->[1];
			     $varref = $self->{$field};
			   } => \@_ ] }

sub _map($)           {  [ sub { shift->document->d_map(shift()) }, $_[0] ] }
sub _grep($)          {  [ sub { shift->document->d_grep(shift()) }, $_[0] ] }
sub _sort(;$)         {  [ sub { shift->document->d_sort(shift()) }, $_[0] ] }
sub _uniq()           {  [ sub { shift->document->d_uniq() } ] }

sub _compress()       {  [ sub { shift->document->try_compress() } ] }
sub _uncompress()     {  [ sub { shift->document->try_uncompress() } ] }

sub _html_to_xhtml()    {  [ sub { shift->document->html_to_xhtml() } ] }
_alias _to_xhtml => '_html_to_xhtml';
sub _xpath()            {  [ sub { shift->document->xpath(@{$_[0]}) }, \@_ ] }

sub _foreach_result(&)      {  [ sub {
				   my $self = shift;
				   my $sub = $_[0]->[0];
				   my $aryref = $self->{extresult};
				   if( ref $self->{extresult} ){
				     for my $i (0..$#$aryref){
				       local $_ = $aryref->[$i];
				       &$sub($self);
				     }
				   }
				 },
				 [ shift() ] ]
			     }
_alias foreach => '_foreach_result';

chain_sub ol_filter {
  local $_;
  if(ref($_[0]) eq 'ARRAY'){
    my $method = $_[0]->[0];
    my $arg = $_[0]->[1];
    #  print "$method ($arg)\n";

    $method->($self, $arg);
  }
  else {
    $self->template($_[0])->extract;
  }
}

sub ol_subref {
  sub { 
      $self->fetch(@_);
  };
}

sub ol_aryref {
  $self->{extresult};
}

sub ol_scalarref {
  \$self->document->as_string;
}

sub ol_quote {
  $self;
}


chain_sub ol_redirect_to {
  my $ref = ref $_[0];
  if($ref eq 'ARRAY'){
    push @{$_[0]}, $self->document->as_string
  }
  elsif($ref eq 'IO::All'){
    $_[0]->print($self->document->as_string);
  }
  else {
    $_[0] = $self->document->as_string;
  }
}

chain_sub ol_redirect_from {
  $self->document->content( ref($_[0]) eq 'ARRAY' ? shift(@{$_[0]}) : shift );
}

chain_sub ol_push_url {
  push @{$self->{url}}, ref($_[0]) eq 'ARRAY' ? @{$_[0]} : $_[0];
}

chain_sub ol_remove_url {
  foreach my $pattern (ref($_[0]) eq 'ARRAY' ? @{$_[0]} : $_[0]){
    @{$self->{url}} = grep{!/$pattern/} @{$self->{url}};
  }
}

sub ol_iter {
}

sub ol_bool {
  $self->has_more_urls;
}



######################################################################
#
######################################################################

# Default query terms are used to help to retrieve results from search
# engines without a specific vocabulary
our @default_query_terms =
    List::Util::shuffle('a'..'z', 0..9, split(//, '(<$_-/>)'));

sub import() {
    my $caller = caller(0);
    __PACKAGE__->SUPER::import(@_, -package => $caller);

    local *boolean_arguments = sub { qw(-rss) };
    local *paired_arguments = sub {
	qw(
	   -url
	  ) };
    my ($arg, undef) = __PACKAGE__->parse_arguments(@_);

    if($arg->{-rss}) {
	eval 'use XML::RSS::SimpleGen;';
	die $@ if $@;
	no strict 'refs';
	foreach my $method (@XML::RSS::SimpleGen::EXPORT){
	    *{$caller.'::'.$method} = \*{$method};
	}
    }
    if(caller(0)->isa('FEAR::API') and ref $_ ne 'FEAR::API'){
	$_ = fear();
        $_->url($arg->{-url}) if $arg->{-url};
    }
}



#================================================================================
# Configuration variables
#================================================================================
$Storable::Deparse = 1;
$Storable::Eval = 1;

my $urlhistory = FEAR::API::ChksumRepos->new(remove_on_destroy => 1);

my $extor = +{FEAR::API::Extract->new_all};
_field 'extractor' => $extor;
_field 'extresult';
_field 'urlhistory';
_field 'dup';
_field 'inline_files';
_field fetching_count => 0;               # Count of fetchings
_field 'error';                                     # Contains error information
_field document => FEAR::API::Document->new();
_alias doc => 'document';

our @tabs;
_field current_tab => 0;

my $wua = FEAR::API::Agent->new();
_field wua => $wua;                     # Web user agent
_alias ua => 'wua';

_field preproc_prefix => '
sub ($) {
  local $_ = shift;
';

_field preproc_postfix => '
  return $_
}
';
_field postproc_prefix => '
sub ($) {
  my $data = shift;
  foreach (@$data) {
      foreach my $k (ref($_) eq q(HASH) ? keys %$_ : @$_){
        $_->{$k} =~ s/^\s*//;
        $_->{$k} =~ s/\s*$//;
      }
';

_field postproc_postfix => '
  }
  $data = [ grep {ref($_) eq q(HASH) ? %$_ : @$_} @$data ];
  return $data;
}
';

_field logger => FEAR::API::Log->new;
_field initial_timestamp => undef;
_field max_exec_time => undef;            # Exceed this limit and program exits.
_field extmethod => 'Template::Extract';
_field document_stack => [];
_field referer => undef;
_field max_processes => 5;
_field docsum_repos => undef;

_chain allow_duplicate => 0;
_chain eval_proc => 1;                    # Evaluate pre|post procesing code
_chain use_proc_affix => 1;               # Use pre-|post-fix around eval code
_chain use_TT_in_url => 1;                # Enable Template code in URL
_chain use_inline => 1;                   # Enable Inline::Files support
_chain fallthrough_report => 0;           # Fall through report_links' options
_alias fallthrough => 'fallthrough_report';
_chain random_delay => 1;                 # Interval of random delays, in seconds
_chain fetch_delay => 1;                  # The mininum delay between fetchings, in seconds
_chain quiet => 0;                        # Turn on/off warnings
_chain max_fetching_count => 0;           # Maximum number of fetching
_chain parallel => 0;                     # Use/Don't use parallel fetching
_chain auto_append_url => 0;              # Auto-append url to results. Default is Off.
                                         # Call append_url() to append manually.


#======================================================================
# Shared memory
#======================================================================

my $shared_key = '6666';
my $shared_handle;
my %shared_var;
if($INC{'Tie/ShareLite.pm'}){
    $shared_handle = tie %shared_var, 'Tie::ShareLite',
    -key     => $shared_key,
    -mode    => 0700,
    -create  => 'yes',
    -destroy => 'no'
	or croak("Could not tie to shared memory: $!");
}

_field shared_handle => $shared_handle;
_field shared_var => \%shared_var;

if(ref $shared_handle){
    $shared_handle->lock(LOCK_EX);
    $shared_var{fetching_count} = 0;
    $shared_handle->unlock;
}

sub output_filehandle {
    $self->{output_filehandle} = shift if $_[0];
    select($self->{output_filehandle});
    $self->{output_filehandle};
}

use subs 'print';
sub print {
    if(defined $shared_handle and ref $shared_handle){
	$shared_handle->lock(LOCK_EX);
    }

    select($self->{output_filehandle}) if $self->{output_filehandle};
    CORE::print(@_);

    if( defined $shared_handle and ref $shared_handle ){
	$shared_handle->unlock;
    }
};



#================================================================================
# Handler-related methods
#================================================================================

# Set the third-party data handler
chain_sub handler {
    my $handler = $_[0];
    return $self if defined($handler) && $self->{handler} && $handler eq $self->{handler};
    no strict 'refs';
    if($handler){
	if(ref($handler) eq 'CODE'){
	    $self->{handler} = $handler;
	}
	elsif(ref($handler) eq 'ARRAY') {
	    $self->{handler} = sub { push @{$handler}, shift };
	}
	elsif(ref($handler) eq 'SCALAR') {
	    $self->{handler} = sub { ${$handler} = shift };
	}
	elsif($handler eq 'Data::Dumper'){
	    $self->{handler} = sub { &print(Dumper shift) };
	}
	elsif($handler eq 'YAML'){
	    $self->{handler} = sub { &print( YAML::Dump shift) };
	}
	elsif($handler eq 'HashToArray'){
	  # This handler converts hash-based extresults into array-based results
	  # This is needed if need to invoke CSV handler
	    $self->{handler} = sub {
	      my $result_item = shift;
	      my $new_result_item;
#	      $result_item
	    }
	}
#	elsif($handler eq 'CSV'){
#	  my $outputfile = $_[1];
#	  $self->{handler} = sub {
#	    my $result_item = shift;
#	    my @fields;
#	    if(ref($result_item) eq 'HASH'){
#	    @fields = values %$result_item;
#	    }
#	    elsif(ref($result_item) eq 'ARRAY'){
#	    }
#	  };
#	  my $csv = Text::CSV->new;
#	  if ($csv->combine(@fields)) {
#	    my $string = $csv->string;
#	    print $string, "\n";
#	  } else {
#	    my $err = $csv->error_input;
#	    cluck "combine() failed on argument: ", $err, "\n";
#	  }
#	}
	else{
	    # If the handler's namespace cannot be seen, then try to load it
	    my $class = ref($handler) || $handler;
	    if(!%{$class.'::'}){
		if(not ref $_[0]){
		    eval "require $class;";
		    croak $@ if $@;
		}
	    }
	    if(
	       (ref($handler) &&
		(ref($handler)->isa('Class::DBI') or ref($handler)->isa('DBIx::Class::CDBICompat')))
	       ||
	       ($handler->isa('Class::DBI') or $handler->isa('DBIx::Class::CDBICompat'))
	       ){
		$self->{handler} = sub { $handler->find_or_create(shift()) };
		return;
	    }
	    else {
		$self->{handler} = \&{$handler . '::' . ($_[1] ? $_[1] : 'process') };
	    }
	}
    }
}


chain_sub invoke_handler {
    my $handler;
    $handler = shift if @_;
    $self->handler($handler) if $handler;
    croak "Please set handler first" if not defined $self->{handler};
    if(ref $self->{extresult}) {
      foreach (@{$self->{extresult}}){
	&{$self->{handler}}($_, @_);
      }
    }
}



#================================================================================
# Methods for inline file processing
#================================================================================

sub _load_inline_files {
    for ($0, (caller(2))[1], catfile(getcwd, $0)){
	return if
	    $_ eq '-e' # skip one-liner
	    ||
	    $_ eq '-'  # skip stdin program
	    ||
	    -B         # skip binary files, such as files generated using pp
	    ;
    }

    # Trying to load templates in module or script files
    my @fn = vf_load(((caller(2))[1]) => qr/^__(?!END)\w+__\n/);
    # Loading template in scripts
    if($0 ne (caller(2))[1]){
	push @fn, vf_load(catfile(getcwd(), $0) => qr/^__(?!END)\w+__\n/);
    }

    local $/;
    foreach my $filename (@fn){
	vf_open(my $f, $filename)
	    or croak "Couldn't open inline file: $filename. $!";
	(my $cont = <$f>) =~ s/\n+$//s;
	(my $marker = vf_marker($filename))=~ s/\n$//s;
#	print "===============$filename\n", $cont;
	$self->{inline_files}{$marker} = $cont;
	vf_close($f);
    }
}

#================================================================================
# Methods
#================================================================================


sub current_url {
  $self->wua->uri;
}


sub _load_templates {
    my $t = FEAR::API::Document->new();
    my $c = $self->_slurp_file(shift || croak "Please input template");
    $c =~ s/[\r\n]+$//so;
    $t->content($c);
    $t->utf8_on;
    $t;
}


chain_sub template {
    $self->{template} = $self->_load_templates(shift);
}

chain_sub try_templates {
  if(@_){
    $self->{template} = [ map{$_ && $self->_load_templates($_)} @_ ];
  }
}


sub _slurp_file {
  $self->{use_inline} && $_[0] =~ /^__\w+?__$/  # If it's inline file
    ?
      $self->{inline_files}{$_[0]} :
	(
	 -e $_[0] && $_[0]!~/\n/ ?              # If $_[0] is probably a physical file 
	 scalar(read_file($_[0]))
	 :
	 ($_[1] ?                               # load url
	  ($_[0] =~ m(\A\w+://) ?               # if no scheme is specified, use http://
	   $_[0] : 'http://'.$_[0])
	  :
	  $_[0])
	);
}

my $tt = Template->new;
sub invoke_TT {
    my $input = shift;
    my $output;
    $tt->process(\$input, undef, \$output);
    $output =~ s/^\s+//gmo;
    $output =~ s/\s+$//gmo;
    $output =~ s(^http://$)()mgo;
#    print $output;
    $output;
}

chain_sub url_from_file {
  my $file = shift;
  my $s = scalar read_file $file;
  push @{$self->{url}}, grep{$_} split /\n+/, $self->{use_TT_in_url} ? $self->invoke_TT($s) : $s;
}

chain_sub url_from_inline {
  my $file = shift;
  my $s = $self->_slurp_file($file, 1);
  push @{$self->{url}}, grep{$_} split /\n+/, $self->{use_TT_in_url} ? $self->invoke_TT($s) : $s;
}

chain_sub url {
  foreach my $u ((ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_)){
    if(ref $u){
      push @{$self->{url}}, $u;
    }
    else {
      my $s = $self->_slurp_file($u,1)."\n";
      
      push @{$self->{url}},
	grep { $_ && !$self->urlhistory->has($_) }
	  split /\n+/, ($self->{use_TT_in_url} ?  $self->invoke_TT($s) : $s);
    }
  }
}

chain_sub shuffle_urlqueue {
    @{$self->{url}} = List::Util::shuffle(@{$self->{url}});
}


sub new()  {
    my $self = bless {} , __PACKAGE__;

    $self->_init_chain_subs;
    $self->_init_field_subs;

    $self->_load_inline_files if $self->{use_inline};

    # Some more complicated options
    $self->urlhistory($urlhistory);
    $self->fetch_delay($self->{random_delay} ?
                       int(rand($self->{random_delay})) : 1);
    # add a dumb template for extors that don't need a template, such as 'emails'
    $self->template('...');
    $self->url($_[1]) if $_[1];
    $self->initial_timestamp(time());
    $self->extractor;
    $self;
}

sub fear() {
    my $f = __PACKAGE__->new(@_);
    if(defined wantarray){
	$f;
    }
    else {
	$_ = $f if !ref $_ or ref $_ ne __PACKAGE__;
    }
}


sub value {
  return $self->{shift()};
}

sub OK {
  ! $self->not_ok();
}

sub NOT_OK {
  $! || $@ || $? || $^E || $self->error
}

chain_sub try_decompress_document {
  $self->document->try_decompress;
}

chain_sub try_compress_document {
  $self->document->try_compress;
}

sub inc_fetching_count {
    if($self->{parallel}){
	if(ref $shared_handle){
	    $self->shared_handle->lock(LOCK_EX);
	    if( exists $self->shared_var->{fetching_count} ){
		$self->{fetching_count} = $self->shared_var->{fetching_count};
	    }
	}
    }

    $self->{fetching_count}++;
    
    if($self->{parallel}){
	if(ref $shared_handle){
	    $self->shared_var->{fetching_count} = $self->{fetching_count};
	    $self->shared_handle->unlock;
	}
    }
}

sub reach_max_fetching_count {
    $self->{max_fetching_count} > 0
	and
    $self->{fetching_count} == $self->{max_fetching_count}
}

sub getprint {
  $self->fetch(shift());
  &print($self->doc->as_string);
}

sub getstore {
  croak "Incorrect number of arguments" if not @_ == 2;
  $self->fetch(shift);
  $self->save_to_file(shift);
}

chain_sub fetch {
    exit if
	defined($self->{max_exec_time})
	and (time() - $self->{initial_timestamp}) > $self->{max_exec_time};

#    print Dumper $self->{url}->[0];
  FETCH:
    my $link = shift(@_) || shift @{$self->{url}} || croak "Please input a URL\n";
    my $append_to_document = shift;

    $link = WWW::Mechanize::Link->new($link !~ m(^\w+://)o ? # if there's no protocol specified
				      ($link !~ /\./o ?     # if there is no .com, .net stuff
				       'http://'.$link.'.com' : 'http://'.$link ) 
				      : $link
				     ) unless ref $link;
#    print Dumper $link;
    my $url = $link->url;
    my $referer = $link->referer || $self->value('referer');



    if( $url and $self->urlhistory->has($url) ){
      &print( "\n   $url has been visited.\n");
      goto FETCH;
    }
    if($self->reach_max_fetching_count){
	$self->document->content(undef);
	$self->{url} = [];
	return $self;
    }

    $self->urlhistory->add($url) unless $self->{allow_duplicate};
    if( $self->{docsum_repos} and ref $self->{docsum_repos} ){
	$self->{docsum_repos}->add( $url, $self->{document}->digest );
    }
    $self->{fetch_delay} && sleep ($self->{fetch_delay});


    $self->inc_fetching_count();
    &print( "\n> [".$self->fetching_count."] Fetching $url ...\n");

    my $wua = $self->wua;
    my $d =
	  do {
	    $wua->add_header(Referer => $referer) if $referer;
	    $wua->get_content($url);
	    $wua->delete_header('Referer') if $referer;
	    $wua->content;
	  };
    &print( "      [",$wua->title,"]",$/) if $wua->title;
    $append_to_document ?
      $self->document->append($d) : $self->document->content($d);
    $self
	->try_decompress_document()
	;
}

chain_sub fetch_and_append {
    $self->fetch($_[0], 1);
}

chain_sub file {
  my $file = rel2abs(shift);
  -e $file ? fetch("file://$file") : croak "$file does not exist";
}

chain_sub pfetch {
    my $callback = shift;
    if(not ref $shared_handle){
	print("Cannot use Tie::ShareLite.\npfetch() is disabled.\nPlease install Tie::ShareLite to get this work.\n");
	return;
    }
    my $pm = new Parallel::ForkManager($self->max_processes);
    while (my $link = shift @{$self->{url}}){
	my $pid = $pm->start and next;
	{
	    $self->parallel(1);
	    $self->fetch($link);
	    if( ref $callback ){
		$self->shared_handle->lock(LOCK_EX);
                local $_ = $self;
		&$callback();
		$self->shared_handle->unlock;
	    }
	    $self->parallel(0);
	}
	$pm->finish;
    }
    $pm->wait_all_children;
}


# Sync contents among FEAR::API::Agent and FEAR::API::Document
chain_sub sync_document {
  $self->document->content($self->wua->content);
}


chain_sub use_join {
    $self->{use_join} = shift if defined $_[0];
}

chain_sub start_join {
    $self->use_join(1);
}

chain_sub stop_join {
    $self->use_join(0);
}

chain_sub push_document {
    push @{$self->{document_stack}}, [ freeze($self->{wua}), freeze($self->{document}) ];
}

chain_sub pop_document {
    ($self->{wua}, $self->{document}) = @{pop @{$self->{document_stack}}};
    $self->{wua} = thaw $self->{wua};
    $self->{document} = thaw $self->{document};
}

sub _invoke_extractor {
    my $result;
#    print Dumper $self->{template};
    foreach my $template (ref($self->{template}) eq 'ARRAY' ?
			  @{$self->{template}} : $self->{template}){
      $result = 
	ref $self->{extmethod} eq 'CODE' ?
	  $self->{extmethod}->($self->document->as_string) :
	    $self
	      ->{extractor}->{$self->{extmethod}}
		->extract(template => $template->as_string,
			  document => $self->document->as_string,
			  extmethod => $self->{extmethod});
      last if ref($result) and @$result;
    }
    $result;
}

chain_sub extract {
#    print Dumper $self->{extractor};
    $self->template(shift) if $_[0];
    return $self unless $self->{template} && $self->document->size; # Do nothing
#    print "($self->{template})\n";
    if($self->{use_join}){
	# extracted results
	my $extres = $self->_invoke_extractor || [];
	@{$self->{extresult}} = map{
	  my %r = %{ $self->{extresult}->[$_] || {} };
	  while (my($k, $v) = (
			       each(%{ $extres->[$_] || {} })
			      )){
	    $r{$k} = $v;
	  }
	  \%r;
	} 0..$#$extres;
#	print Dumper $self->{extresult};
    }
    else {
	$self->extresult($self->_invoke_extractor);
    }
#    print Dumper $self->{extresult};
    $self->append_url if $self->{auto_append_url};
}

chain_sub append_url {
    foreach my $r (@{$self->{extresult}}){
	if(ref($r) eq 'HASH'){
	    $r->{url} = $self->current_url;
	}
    }
}

chain_sub remove_fetched_links {
  if(ref($_[0]) eq 'ARRAY'){
    @{$_[0]} = grep{!$self->urlhistory->has($_)}  @{$_[0]};
  }
  else {
    @{$self->{url}} = grep{!$self->urlhistory->has($_)} @{$self->{url}};
  }
}

chain_sub remove_duplicated_results {
    my %h;
    @{$self->{extresult}} =
      grep{!$h{join q//, %$_}++ ? $_ : undef}
    @{$self->{extresult}};
}

chain_sub keep_first_result {
    @{$self->{extresult}} = ( $self->{extresult}[0] );
}

chain_sub keep_results {
  if(@_){
    @{$self->{extresult}} = @{$self->{extresult}}[@_];
  }
}

sub find_link {
  $self->wua->find_link(@_);
}

chain_sub follow_link {
  my $link = $self->wua->find_link(@_);
#  print Dumper $link;
  $self->fetch($link) if $link;
}

chain_sub try_follow_link {
  if($self->find_link(@_)){
    $self->push_document;
    $self->follow_link(@_);

    if(not $self->wua->success){
      $self->pop_document;
    }
    else {
      shift @{$self->{document_stack}} # discard the pushed document if success
    }
  }
}


chain_sub back {
  $self->wua->back();
  $self->sync_document;
}

chain_sub flatten {
    my $field = shift || croak "Please specify a field in results\n";
    foreach my $r (@{$self->{extresult}}){
	%$r = (%$r, %{$r->{$field}});
    }
}


chain_sub unflatten {
    @{$self->{extresult}} = ([ @{$self->{extresult}} ]);
}


sub links {
  return @{$self->wua->links};
}

chain_sub sort_links {
  $self->wua->sort_links(@_);
}

chain_sub keep_links {
  $self->wua->keep_links(@_);
}

chain_sub remove_links {
  $self->wua->remove_links(@_);
}

sub uniq {
    my $aryref = shift;
    my %h;
    @$aryref = grep{!$h{
	ref $_ eq 'HASH' ? %$_ :
        ref $_ eq 'ARRAY' ? @$_ :
	ref $_ eq 'SCALAR' ? $$_ :
        $_
	}++} @$aryref;
}

_alias dispatch_links => 'report_links';
chain_sub report_links {
    my @dispatch_table = @_ or return $self;

    foreach my $item ($self->links){
      for (my $i= 0; $i<$#dispatch_table; $i+=2){
	my ($pattern, $action) = @dispatch_table[$i, $i+1];
	if( (ref($pattern) eq 'CODE' && do { local $_ = $item; $pattern->() } )
             ||
	    $item->url =~ m($pattern)){
	  if($action eq _feedback){
	    if($self->value('allow_duplicate') || !$self->urlhistory->has($item->url)){
	      &print( "   Feed back [".$item->text."] ".$item->url."\n");
	      push @{$self->{url}}, $item;
	    }
	  }
	  elsif($action eq 'Data::Dumper'){
	    &print( Dumper $item);
	  }
	  elsif(ref $action eq 'ARRAY'){
	    push @{$action}, dclone $item;
	  }
	  elsif(ref $action eq 'HASH'){
	    $action->{$item} = 1;
	  }
	  elsif(ref $action eq 'CODE'){
	    local $_ = $self;
	    &{$action}($item);
	  }
	  last if not $self->{fallthrough_report};
	}
      }
    }
    #    print "Remove fetched links\n";
    $self->remove_fetched_links;
    $self->uniq($self->{url});
}

########################################
# Shortcut for 'feedback' with report_links()
########################################
chain_sub push_link {
  push
    @{$self->{url}},
      ($self->links)[
		     @_ # Just feed back the first link if no index is given 
		     ||
		     0];
}

chain_sub unshift_link {
  unshift
      @{$self->{url}},
      ($self->links)[
                     @_
                     ||
                     0];
}




########################################
# Shortcut for feeding back all links
########################################
chain_sub push_all_links {
  push @{$self->{url}}, $self->links;
}

chain_sub push_local_links {
  push @{$self->{url}}, grep{$_->is_local_link} $self->links;
}

chain_sub unshift_all_links {
  unshift @{$self->{url}}, $self->links;
}

chain_sub unshift_local_links {
  unshift @{$self->{url}}, grep{$_->is_local_link} $self->links;
}

########################################
# Usage:
# absolutize_url(qw(field1 field2));
########################################
chain_sub absolutize_url {
    foreach my $field (@_){
	foreach my $r (@{$self->{extresult}}){
	    if( exists $r->{$field} &&
		$r->{$field} !~ /^(?:\w+):/o ){
		$r->{$field} =
		    URI::WithBase
		    ->new($r->{$field}, $self->current_url)
		    ->abs
		    ->as_string;
	    }
	}
    }
}

sub _create_proc_sub {
    my $snippet = shift;
    my $type = shift;
#    print $self->{$type.'proc_prefix'} .$snippet . ';' . $self->{$type.'proc_postfix'}
    ;
    my $sub =
	$self->{eval_proc} ? ($self->{use_proc_affix} ?
			      eval ($self->{$type.'proc_prefix'} .
				    $snippet . ';' .
				    $self->{$type.'proc_postfix'}
				    ) :
			      eval ($snippet)
			      )
	:
	$snippet;
    croak $@ if $@;
    $sub;
}


_alias doc_filter => 'preproc';
chain_sub preproc {
    return $self if !$_[0];
    no strict 'refs';
    my $sub;
    if(($_[0] eq 'use' || $_[0] eq 'use_filter') && $_[1]){
	$sub = $filter->{$_[1]};
	$self->document->content( $sub->($self->document->as_string) );
    }
    else {
	my $snippet = $self->_slurp_file($_[0]);
	$sub = $self->_create_proc_sub($snippet, 'pre');
	croak "Preproc code is not working" unless ref($sub) eq 'CODE';
	$self->document->content( $sub->($self->document->as_string) );
    }
}

_alias result_filter => 'postproc';
chain_sub postproc {
    return $self if !$_[0];
    no strict 'refs';
    my $sub;
    if(($_[0] eq 'use' || $_[0] eq 'use_filter') && $_[1]){
	$sub = $filter->{$_[1]};
	my @f = @_[2..$#_];
	foreach my $r (@{$self->{extresult}}){
#	    print Dumper $r;
	    foreach my $f (@f){
		$r->{$f} = $sub->($r->{$f});
	    }
	}
    }
    else {
	my $snippet = $self->_slurp_file($_[0]);
	$sub = $self->_create_proc_sub($snippet, 'post');
	croak "Postproc code is not working" unless ref($sub) eq 'CODE';
	$sub->($self->{extresult});
    }
}

chain_sub add_field {
    foreach my $r (@{$self->{extresult}}){
	$r->{$_[0]} = $_[1];
    }
}

chain_sub clear_extresult {
    $self->{extresult} = undef;
}

chain_sub clear_urlhistory {
    $self->urlhistory->empty;
}



#================================================================================
# Delegates for LWP::UserAgent object ($self->wua)
#================================================================================
_alias res => 'response';
_alias resp => 'response';
sub response {
  $self->wua->response;
}

sub _process_ua_resp {
    return $self if $self->reach_max_fetching_count;

    my $resp = shift;
    $self->sync_document if $resp->is_success;
    $self
        ->try_decompress_document()
	->inc_fetching_count()
	;
}


chain_sub get {
    my $u = URI::URL->new(shift());
    $u->query_form(@_);
    &print( $u->as_string,$/);
    $self->fetch($u->as_string);
}


chain_sub post {
    my $u = shift;

    my %arg = @_;
    $self->urlhistory->add(URI::URL->new($u)->query_form(@_))
      if not $self->{allow_duplicate};
    $self->_process_ua_resp($self->wua->post($u, \%arg));
}


chain_sub agent_alias {
    $self->wua->agent_alias(shift() || 'Windows IE 6');
}

chain_sub submit_form {
  my %arg = @_;
  &print( "     Submit form [ ".($arg{form_name} || $arg{form_number})." ]\n");
  $self->wua->submit_form(%arg);
  $self->sync_document;
}


sub force_content_type {
  $self->wua->force_content_type(@_);
}

sub title {
  $self->wua->title;
}

sub forms {
  $self->wua->forms;
}


#================================================================================
# Additional utilities
#================================================================================
_alias save_as =>'save_to_file';
chain_sub save_to_file {
    my $filename = shift || croak 'Please input file name';
    open my $f, '>', $filename or croak "Cannot open $filename for writing";
    binmode $f;
    print {$f} $self->document->as_string;
}

chain_sub save_as_tree {
    my $root = shift || '.';
    my ($scheme, $auth, $path, $query, $frag) 
	= URI::Split::uri_split($self->current_url);
#    print "($scheme, $auth, $path, $query, $frag) \n";
    my (undef, $dir, $file) = splitpath($path);
#    print join q/ /, splitpath($path),$/;
#    print "mkdir ".catfile($root, $auth, $dir).$/;
#    print "write doc to ".catfile($root, $auth, $dir, $file.'?'.$query).$/;
    mkpath([catfile($root, $auth, $dir)],0,0755);
    my $content_file = 
	catfile($root, $auth, $dir, ($file?$file:'index.html') . ($query?'?'.uri_escape($query):''));
#    print $content_file.$/;
    open my $f, '>', $content_file or croak $!;
    binmode $f;
    print {$f} $self->document->as_string;
}

chain_sub visit_tree {
    my @path = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : ($_[0]);
    my $coderef = $_[1];
    local $_ = $self;
    foreach my $path (@path){
	foreach my $p (io($path)->All){
	    next if "$p" eq 'dir';
	    $coderef->($p);
	}
    }
}


#================================================================================
# Template generation methods. Pending
#================================================================================
chain_sub data {
}

chain_sub generate_template {
}

chain_sub output_template {
}

# ======================================================================
# Tab scraping
# ======================================================================

sub tab {
    my $tab_number = shift;
    my $fear_object;
    if(defined $tab_number){
#  	print "$self->{current_tab} => $tab_number\n";
# 	print "@tabs\n";
	$tabs[$self->{current_tab}] = $self;
	undef $self;
	$fear_object = defined $tabs[$tab_number] ?
	    $tabs[$tab_number] : do {
# 		print "Creating new\n";
		my $f = __PACKAGE__->new();
 		$f->document(FEAR::API::Document->new);
  		$f->wua(FEAR::API::Agent->new);
  		$f->urlhistory(FEAR::API::ChksumRepos->new(
							  remove_on_destroy => 1
							  )
			      );
  		$f->extractor(+{FEAR::API::Extract->new_all});
		$f->logger(FEAR::API::Log->new);
		$f;
	    };
	$fear_object->current_tab($tab_number);
	$tabs[$tab_number] = $fear_object;

	if(caller(0)->isa('FEAR::API')){
	    $_ =  $fear_object;
	}
	else {
	    $self = $fear_object;
	}
    }
    return $fear_object;
}

sub keep_tab {
    if(my $tab_number = shift){
	@tabs = ($tabs[$tab_number]);
	$tabs[0]->{current_tab} = 0;
    }
}

sub close_tab {
    my $tab_number = shift;
    if( defined $tab_number ){
# 	print "Closing $tab_number\n";
	undef $tabs[$tab_number];
	@tabs = grep{defined $_} @tabs;
	my $count = 0;
	for my $t (@tabs){
	    $t->{current_tab} = $count++;
	}
    }
}

######################################################################
# Document checksum
######################################################################

sub use_docsum {
    my $file = shift || croak "Please specify document checksum file";
    my %opt = @_;
    $self->{docsum_repos} = FEAR::API::ChksumRepos->new(
							file => $file,
							remove_on_destroy => 0
						       );
    if($opt{cleanup}){
	$self->{docsum_repos}->empty;
    }
}

sub no_docsum {
    undef $self->{docsum_repos};
}

sub doc_changed {
    return 1
	if
	    ref $self->{docsum_repos} and
	    $self->{docsum_repos}->has($self->current_url) and
		(
		 $self->{docsum_repos}->value($self->current_url)
		 ne
		 $self->{document}->digest
		 );
}

sub remove_docsum {
    $self->{docsum_repos}->remove;
}


# ======================================================================
# Code generation
# ======================================================================

# SST is for 'site scraping template'
_field 'sst';
_field 'sst_source';
_field 'sst_compiled';

chain_sub load_sst {
    $self->sst(shift);
}

chain_sub load_sst_file {
    $self->sst(io(shift)->all);
}

chain_sub run_sst {
    my $output;
    $tt->process(\$self->sst, shift, \$output);
    if(md5_hex $self->sst_source ne md5_hex $output){
	$self->sst_source($output);
	$self->{sst_compiled} = eval 'sub {' . $output . '}';
    }
    $self->sst_compiled->();
}

_alias ___ => 'has_more_urls';
_alias has_more_links => 'has_more_urls';

sub has_more_urls { 
    ref($self->{url}) && @{$self->{url}} ?
	($self->reach_max_fetching_count ? 0 : 1 ) : 0;
}

_alias has_more_links_like => 'has_more_urls_like';
sub has_more_urls_like {
    my $pattern = shift;
    (ref($_) ? $_->[0] : $_) =~ m($pattern) and return 1 foreach @{$self->{url}};
}

sub list_filters { wantarray ? %$filter_source : $filter_source }


1;
__END__

=head1 NAME

FEAR::API - There's no fear with this elegant site scraper

=head1 DESCRIPTION

FEAR::API is a tool that helps reduce your time creating site scraping
scripts and help you do it in a much more elegant way. FEAR::API
combines many strong and powerful features from various CPAN modules,
such as LWP::UserAgent, WWW::Mechanize, Template::Extract, Encode,
HTML::Parser, etc. and digests them into a deeper Zen.

However, this module violates probably every single rule of any Perl
coding standards. Please stop here if you don't want to the yucky
code.

=head1 EXAMPLES

    use FEAR::API -base;
    
=head2 Fetch a page and store it in a scalar

    fetch("google.com") > my $content;
    
    my $content = fetch("google.com")->document->as_string;

=head2 Fetch a page and print to STDOUT

    getprint("google.com");
   
    print fetch("google.com")->document->as_string;

    fetch("google.com");
    print $$_;    

    fetch("google.com") | _print;


=head2 Fetch a page and save it to a file

    getstore("google.com", 'google.html');

    url("google.com")->() | _save_as("google.html");
    
    fetch("google.com") | io('google.html');

=head2 Follow links in Google's homepage

    url("google.com")->() >> _self;
    &$_ while $_;

=head2 Save links in Google's homepage

    url("google.com")->() >> _self | _save_as_tree("./root");
    $_->() | _save_as_tree("./root") while $_;


=head2 Recursively get web pages from Google

    url("google.com");
    &$_ >> _self while $_;

=head2 Recursively get web pages from Google

    url("google.com");
    &$_ >> _self | _save_as_tree("./root") while $_;

=head2 Follow the second link of Google

    url("google.com")->()->follow_link(n => 2);

=head2 Return links from Google's homepage

    print Dumper fetch("google.com")->links;

=head2 Submit a query to Google

    url("google.com")->();
    submit_form(
                form_number => 1,
                fields => { q => "Kill Bush" }
                );

=head2 Get links of some pattern

    url("[% FOREACH i = ['a'..'z'] %]
         http://some.site/[% i %]
         [% END %]");
    &$_ while $_;
    
=head2 Get pages in parallel

    url("google.com")->() >> _self;
    pfetch(sub{
               local $_ = shift;
               print join q/ /, title, current_url, document->size, $/;
           });

=head2 Deal with links in a web page (I)

=head3 Minimal

    url("google.com")->()
      >> [
          qr(^http:) => _self,
          qr(google) => \my @l,
          qr(google) => sub {  print ">>>".$_[0]->[0],$/ }
         ];
    $_->() while $_;
    print Dumper \@l;

=head3 Verbose

    fetch("http://google.com")
    ->report_links(
                   qr(^http:) => _self,
                   qr(google) => \my @l,
                   qr(google) => sub {  print ">>>".$_[0]->[0],$/ }
                  );
    fetch while has_more_urls;
    print Dumper \@l;

=head2 Deal with links in a web page (II)

=head3 Minimal

    url("google.com")->()
      >> {
          qr(^http:) => _self,
          qr(google) => \my @l,
          qr(google) => sub {  print ">>>".$_[0]->[0],$/ }
         };
    $_->() while $_;
    print Dumper \@l;

=head3 Verbose

    fetch("http://google.com")
    ->fallthrough_report(1)
    ->report_links(
                   qr(^http:) => _self,
                   qr(google) => \my @l,
                   qr(google) => sub {  print ">>>".$_[0]->[0],$/ }
                  );
    fetch while has_more_urls;
    print Dumper \@l;

=head2 Extraction

=head3 Extract data from CPAN

    url("http://search.cpan.org/recent")->();
    submit_form(
            form_name => "f",
            fields => {
                       query => "perl"
                      });
    template("<!--item-->[% p %]<!--end item-->");
    extract;
    print Dumper extresult;

=head3 Extract data from CPAN after some HTML cleanup 

    url("http://search.cpan.org/recent")->();
    submit_form(
            form_name => "f",
            fields => {
                       query => "perl"
                      });
    preproc(q(s/\A.+<!--results-->(.+)<!--end results-->.+\Z/$1/s));
    print document->as_string;    # print content to STDOUT
    template("<!--item-->[% p %]<!--end item-->");
    extract;
    print Dumper extresult;

=head3 HTML cleanup, extract data, and refine results

    url("http://search.cpan.org/recent")->();
    submit_form(
            form_name => "f",
            fields => {
                       query => "perl"
                      });
    preproc(q(s/\A.+<!--results-->(.+)<!--end results-->.+\Z/$1/s));
    print $$_;    # print content to STDOUT
    template("<!--item-->[% rec %]<!--end item-->");
    extract;
    postproc(q($_->{rec} =~ s/<.+?>//g));     # Strip HTML tags
    print Dumper extresult;


=head3 Use filtering syntax

    fetch("http://search.cpan.org/recent");
    submit_form(
                form_name => "f",
                fields => {
                           query => "perl"
                })
       | _doc_filter(q(s/\A.+<!--results-->(.+)<!--end results-->.+\Z/$1/s))
       | _template("<!--item-->[% rec %]<!--end item-->")
       | _result_filter(q($_->{rec} =~ s/<.+?>//g));
    print Dumper \@$_;

=head3 Invoke handler for extracted results

    fetch("http://search.cpan.org/recent");
    submit_form(
                form_name => "f",
                fields => {
                           query => "perl"
                })
       | _doc_filter(q(s/\A.+<!--results-->(.+)<!--end results-->.+\Z/$1/s))
       | "<!--item-->[% rec %]<!--end item-->"
       | _result_filter(q($_->{rec} =~ s/<.+?>//g));
    invoke_handler('Data::Dumper');


=head2 Forward extracted data to relational database

    template($template);
    extract;
    invoke_handler('Some::Module::based::on::Class::DBI');
    # or
    invoke_handler('Some::Module::based::on::DBIx::Class::CDBICompat');

=head2 Preprocess document

    url("google.com")->()
    | _preproc(use => "html_to_null")
    | _preproc(use => "decode_entities")
    | _print;

=head2 Postprocess extraction results

    fetch("http://search.cpan.org/recent");
    submit_form(
                form_name => "f",
                fields => {
                           query => "perl"
                })
       | _doc_filter(q(s/\A.+<!--results-->(.+)<!--end results-->.+\Z/$1/s))
       | _template("<!--item-->[% rec %]<!--end item-->")
       | _result_filter(use => "html_to_null",    qw(rec));
       | _result_filter(use => "decode_entities", qw(rec))
    print Dumper \@$_;

=head2 Scraping a file

    file('some_file');

    url('file:///the/path/to/your/file');

=head2 Convert HTML to XHTML


    print fetch("google.com")->document->html_to_xhtml->as_string;

    fetch("google.com") | _to_xhtml;
    print $$_;

=head2 Select content of interest using XPath

    print fetch("google.com")->document->html_to_xhtml->xpath('/html/body/*/form')->as_string;

    fetch("google.com") | _to_xhtml | _xpath('/html/body/*/form');
    print $$_;

=head2 Make your site scraping script a subroutine

    # sst is for site scraping template;
    load_sst('fetch("google.com") >> _self; $_->() while $_');
    run_sst;

    load_sst('fetch("[% initial_link %]") >> _self; $_->() while $_');
    run_sst({ initial_link => 'google.com'});


=head2 Tabbed scraping

    fetch("google.com");        # Default tab is 0
    tab 1;                             # Create a new tab, and switch to it.
    fetch("search.cpan.org");  # Fetch page in tab 1
    tab 0;                             # Switch back to tab 0
    template($template);       # Continue processing in tab 0
    extract();

    keep_tab 1;                    # Keep tab 1 only and close others
    close_tab 1;                    # Close tab 1

=head2 Create RSS file

    use FEAR::API -base, -rss;
    my $url = "http://google.com";
    url($url)->();
    rss_new( $url, "Google", "Google Search Engine" );
    rss_language( 'en' );
    rss_webmaster( 'xxxxx@yourdomain.com' );
    rss_twice_daily();
    rss_item(@$_) for map{ [ $_->url(), $_->text() ] } links;
    die "No items have been added." unless rss_item_count;
    rss_save('google.rss');

See also L<XML::RSS::SimpleGen>


=head1 Use FEAR::API in one-liners


    fearperl -e 'fetch("google.com")'

    perl -M'FEAR::API -base' -e 'fetch("google.com")'

=head1 DEBATE

This module has been heavily criticized on Perlmonks.
Please go to L<http://perlmonks.org/?node_id=537504> for details.


=head1 AUTHOR & COPYRIGHT

Copyright (C) 2006 by Yung-chung Lin (a.k.a. xern) <xern@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself


=cut
