package MyLibs::Common::DB::Schema::Apikey;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("apikey");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "domain",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "date",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "apikey",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 64,
  },
  "api_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("apikey", ["apikey"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-12 16:06:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0LYMwOGi9+cPTue29JoSZQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
