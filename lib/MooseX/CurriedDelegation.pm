package MooseX::CurriedDelegation;

# ABSTRACT: Curry your delegations with methods

use strict;
use warnings;

use Moose ( );
use Moose::Exporter;

my $trait = 'MooseX::CurriedDelegation::Trait::Attribute';

Moose::Exporter->setup_import_methods(
    trait_aliases => [ [ $trait => 'CurriedDelegation' ] ],

    as_is => [ qw{ curry_to_self } ],
    class_metaroles => { attribute         => [ $trait ] },
    role_metaroles  => { applied_attribute => [ $trait ] },
);

sub curry_to_self() { sub { shift } }

!!42;

__END__

=head1 SYNOPSIS

    use Moose;
    use MooseX::CurriedDelegation;

    has one => (is => 'ro', isa => 'Str', default => 'default');

    has foo => (

        is      => 'rw',
        isa     => 'TestClass::Delagatee', # has method curried()
        default => sub { TestClass::Delagatee->new },

        handles => {

            # method-curry
            #   Note the hashref, not arrayref, we employ
            #   first arg is the remote method to delegate to
            #   second is an arrayref comprising:
            #       coderef to call as a method on the instance, followed by
            #       "static" curry args
            #
            # so, essentially:
            #   $self->foo->remote_method($self->$coderef(), @remaining_args);
            #
            # foo_del_one => {
            #   remote_method => [ sub { ... }, qw{ static args } ],
            # },

            foo_del_one => { curried => [ sub { shift->one }, qw{ more curry args } ] },

            # curry_to_self() always returns: sub { shift }
            foo_del_two => { other_method => [ curry_to_self ] },
        },
    );


=head1 DESCRIPTION

Method delegation is awfully handy -- but sometimes it'd be awfully handier if
it was a touch more dynamic.  This is an attribute trait that provides for a
delegated method to be curried.

=head1 USAGE

Using this package will cause the relevant attribute trait to be applied
without requiring further intervention.  We use the standard

    handles => { local_method => delegate_info, ... }

delegation methodology, however our currying is invoked when delegate_info is
a hashref.  We expect delegate info to look like:

    { remote_method => [ $coderef, @more_curry_args ] }

Only $coderef is ever executed by the delegation.  This means that it is safe
to have any number of additional coderefs in @more_curry_args: they will be
passed through to remote_method without additional manipulation.

=head1 ADDITIONAL SUGAR

In addition, we export a number of helper functions.

=head2 curry_to_self()

This function always returns a coderef like "sub { shift }".  That is, this:

    local => { remote => [ curry_to_self ] }

is equivalent to:

    local => { remote => [ sub { shift } ] }

is equivalent to:

    $self->attribute_accessor->remote($self)

=head1 TRAIT ALIASES

=head2 CurriedDelegation

Resolves out to the full name of our attribute trait; you can use it as:

    has foo => (traits => [CurriedDelegation], ...)

=head1 SEE ALSO

L<Moose>
L<Moose::Meta::Method::Delegation>

=cut
