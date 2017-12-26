package Dist::Zilla::Plugin::MetaMergeFile;

use Moose;
use namespace::autoclean;

with qw/Dist::Zilla::Role::MetaProvider Dist::Zilla::Role::PrereqSource/;

use MooseX::Types::Stringlike 'Stringlike';
use Parse::CPAN::Meta;

my @defaults = qw/metamerge.json metamerge.yml/;

has filename => (
	is       => 'ro',
	isa      => Stringlike,
	default  => sub {
		return (grep { -f } @defaults)[0];
	},
);

has _rawdata => (
	is       => 'ro',
	lazy     => 1,
	builder  => '_build_rawdata',
);

sub _build_rawdata {
	my $self = shift;
	return Parse::CPAN::Meta->load_file($self->filename);
}

sub metadata {
	my $self = shift;
	my %data = %{ $self->_rawdata };
	delete $data{prereqs};
	return \%data;
}

sub register_prereqs {
	my $self = shift;
	my $prereqs = $self->_rawdata->{prereqs};
	for my $phase (keys %{ $prereqs }) {
		for my $type (keys %{ $prereqs->{$phase} }) {
			$self->zilla->register_prereqs(
				{ phase => $phase, type => $type },
				%{ $prereqs->{$phase}{$type} }
			);
		}
	}
}

__PACKAGE__->meta->make_immutable;

1;
