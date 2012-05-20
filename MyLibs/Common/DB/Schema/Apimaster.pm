package MyLibs::Common::DB::Schema::Apimaster;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("apimaster");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 15,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-12 16:06:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eXb2mMf/LRNfkqOFJzW4Hg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
