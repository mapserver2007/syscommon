package MyLibs::Common::DB::Schema::SchemaMigrations;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("schema_migrations");
__PACKAGE__->add_columns(
  "version",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
);
__PACKAGE__->add_unique_constraint("unique_schema_migrations", ["version"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-12 01:49:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wcs+cNv6z/LNx79RUiJtsg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
