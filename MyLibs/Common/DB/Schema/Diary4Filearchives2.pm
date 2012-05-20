package MyLibs::Common::DB::Schema::Diary4Filearchives2;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("diary4_filearchives2");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "filename",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 15,
  },
  "original_filename",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "date",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
  "filetype",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 0, size => 4 },
  "filesize",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-20 16:48:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J9SKhNIM8NRwtGlMupy7/Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
