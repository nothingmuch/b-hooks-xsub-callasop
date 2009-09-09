use strict;
use warnings;

package B::Hooks::XSUB::CallAsOp;

require 5.008001;
use parent qw(DynaLoader);

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=pod

=head1 NAME

B::Hooks::XSUB::CallAsOp - Invoke code from an XSUB in opcode context

=head1 SYNOPSIS

	#include "hook_xsub_callasop.h"

	static TRAMPOLINE_HOOK(foo)
	{
		printf("IM IN UR CALLER MUNGING UR STACK\n");

		return NORMAL; /* you must always return like from a PP function, see
						  also the RETURN macro */

		/* or you can also delegate: */
		return PL_ppaddr[OP_FOO](aTHX);
	}



	MODULE = Some::XS	PACKAGE = Some::XS

	void foo ()
		PPCODE:
			TRAMPOLINE(foo);


	# later, in Perl land...
	# the trampoline hook is invoked in an opcode context, instead of as an XSUB
	Some::XS::foo();

=head1 USAGE

This module requires L<ExtUtils::Depends> to be used in your XS modules.

See L<B::Utils> for an explanation.

=head1 MACROS

=over 4

=item TRAMPOLINE_HOOK(hook_name)

Declares a function with PP's calling conventions. It's the same as perl's own
PP macro but without the Perl_ prefix (you can also use it for declaring a
function pointer)

=item TRAMPOLINE(hook)

Given a function pointer C<hook>, trampoline to it on the next PL_op dispatch.

This will C<PUTBACK>, invoke C<b_hooks_xsub_callasop_setup_trampoline>, and
then return from the current XSUB with no value.

=back

=head1 TYPES

=over 4

=item b_hooks_xsub_callasop_hook_t

A function pointer type describing a Perl push/pop function:

	OP *(*foo) (pTHX)

=back

=head1 FUNCTION

=over 4

=item void b_hooks_xsub_callasop_setup_trampoline (pTHX_ b_hooks_xsub_callasop_setup_trampoline)

The underlying implementation of the C<TRAMPOLINE> macro.

Using the macro is reccomended.

=back

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/b-hooks-xsub-callasop>

=head1 AUTHOR

Yuval Kogman, Florian Ragwitz

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2009 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
