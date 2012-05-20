package MyLibs::Common::DB::Schema::Tclipers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tclipers");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "url",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "url_hash",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "comment",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("url_hash_index", ["url_hash"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-12 01:49:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YCPFZVg0EvGhZEbLwsh2AA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
