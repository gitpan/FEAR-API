   CREATE TABLE cpan (
      module      varchar(64),
      dist        varchar(64),
      link        varchar(256),
      description varchar(128),
      date        varchar(32),
      author      varchar(64),
      url         varchar(256),
      primary key (module)
   );

