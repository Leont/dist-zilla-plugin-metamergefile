package Dist::Zilla::Plugin::PrereqsFile;

use 5.020;
use Moose;
use experimental qw/signatures postderef/;
use namespace::autoclean;

with qw/Dist::Zilla::Role::PrereqSource/;

use MooseX::Types::Moose 'ArrayRef';
use MooseX::Types::Stringlike 'Stringlike';

my @defaults = qw/prereqs.json prereqs.yml/;

has filenames => (
	is        => 'ro',
	isa       => ArrayRef[Stringlike],
	default   => sub {
		return [ grep { -f } @defaults ];
	},
);

sub register_prereqs($self) {
	for my $filename ($self->filenames->@*) {
		require Parse::CPAN::Meta;
		my $prereqs = Parse::CPAN::Meta->load_file($filename);
		for my $phase (keys $prereqs->%*) {
			for my $type (keys $prereqs->{$phase}->%*) {
				$self->zilla->register_prereqs(
					{ phase => $phase, type => $type },
					$prereqs->{$phase}{$type}->%*
				);
			}
		}
	}
}

sub mvp_aliases($self) {
	return {
		filename => 'filenames',
	};
}

__PACKAGE__->meta->make_immutable;

1;

#ABSTRACT: Add static prereqs using a prereqs file

=head1 SYNOPSIS

=head3 dist.ini:

 [PrereqsFile]

=head3 prereqs.yml

 runtime:
   recommends:
     Foo: '0.023'
   suggests:
     Bar: 0

=head1 DESCRIPTION

This plugin implements prereqs files. These allow you to easily add static prerequisites to your metadata.

=head2 Why prereqs files?

Prereqs files are somewhat similar to cpanfiles, but with an important difference. They don't involve evaluating code to produce data, data should be data.

=head2 Names and formats

This file reads either a JSON formatted F<prereqs.json>, and/or a YAML formatted F<prereqs.yml> (or another file if passed with the C<filename> parameter). Regardless of the format, it will parse them as L<META 2.0|CPAN::Meta::Spec> prereqs.
