package FEAR::API::SourceFilter;

use Filter::Simple;
FILTER_ONLY 
  all => \&filter
  ;

sub filter {
  local $/;
  s/\A\n+//o;
  s/^/our \@EXPORT_BASE;\n/;

  # A chain_sub is a method that returns
  # itself after its function is done.
  s[^chain_sub\s+(\w+\s*\{)(.*?)^\}]
    [sub $1\n $2    ;\$self\n}]msg;
  
  
  # Filters adapted from Spiffy.pm

  # Subs with $self auto-created
  s[^sub\s+(\w+)\s+\{(.*\n)]
    [push \@EXPORT_BASE, '$1';\nsub ${1} {\n&know_myself;$2]gm;

  # Subs without $self auto-created
  s[^sub\s+(\w+)\s*\(\s*\)(\s+\{.*\n)]
    [push \@EXPORT_BASE, '$1';\nsub ${1}${2}]gm;

  # Constant sub
  s[^const\s+(\w+)\s*(?:,|=>)\s*(.*)\n]
    [push \@EXPORT_BASE, '$1';\nsub ${1}() { ${2} }]gm;
  
  
  # I guess I don't need to meddle with lexical subs
  s[^my[\s\n]+sub\s+(\w+)(\s+\{)(.*)((?s:.*?\n))\}\n]
    [push @my_subs, $1; "\$$1 = sub$2my \$self = shift;$3$4\};\n"]gem;
  
  
  # Convert filter declarations for create_filter()
  # in FEAR::API::Filters
  s[^filter\s+(\w+)\s*\{(.*?)^\}]
    [create_filter '$1' => << 'FEAR_FILTER';\n$2\nFEAR_FILTER\n]msg;

  # This is for invoking methods without specifying FEAR::API objects
  s(&know_myself)
    (q(my $self = ref ($_[0]) =~ /^FEAR::API/o ? shift : $_))mego;
  

  # For debugging
  if($ENV{DUMP_FILTERED}){
    my $c = 1;
    foreach my $line (split /\n/){
      printf "[%4d] %s\n", $c++, $line;
    }
  }
};




1;
__END__
