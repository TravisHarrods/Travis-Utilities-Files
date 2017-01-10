use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'Travis::Utilities::Files',
  licence            => 'perl',
  dist_author        => 'Travis Harrods <travis.harrods@gmail.com>',
  dist_abstract      => 'A module to manage file handlers.',
  dist_version_from  => 'lib/Travis/Utilities/Files.pm',
  requires           => {
    'Moose'          => 0,
    'English'        => 0,
    'File::Basename' => 0,
    'Travis::Utilities::Log' => 0.01
  },
  meta_merge => {
    ressources => {
      repository => 'https://github.com/TravisHarrods/Travis-Utilities-Files'
    }
  },
  create_makefile_pl => 'traditional',
  installdir         => 'vendor'
);

$builder->create_build_script();
