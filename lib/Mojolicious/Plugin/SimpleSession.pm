package Mojolicious::Plugin::SimpleSession;

use warnings;
use strict;

use base 'Mojolicious::Plugin';
use Digest;
use Data::Dumper;

sub register {
    my ( $self, $app ) = @_;

    my $stash_key = 'session';

    $app->plugins->add_hook(
        before_dispatch => sub {
            my ( $self, $c ) = @_;

            warn "BEFORE DISPATCH\n";
            warn "--------------\n";

            warn "PROCESSING " . $c->tx->req->url . "\n";

            # fetch session from cookie if it exists,
            # check for validity and load the data into
            # the data structure.

            # grab session hash from cookie, if we can.
            my $oldcookies = $c->tx->req->cookies;
            my $cookie_hash;
            foreach my $cookie (@$oldcookies) {
                warn "EXAMING COOKIE " . $cookie->name . "\n";
                if ( $cookie->name eq 'session' ) {
                    $cookie_hash = $cookie->value->to_string;
                    warn "FOUND SESSION COOKIE $cookie_hash\n";
                    last;
                }
            }

            my $session_data = {};
            if ( $cookie_hash && -e _hash_filename($cookie_hash) ) {
                warn "READING FROM LCOAL SESSOIN FILE\n";
                open my $fh, "<", _hash_filename($cookie_hash) || die "$!";
                my $content = '';
                while (<$fh>) {
                    $content .= $_;
                }
                close($fh);
                eval $content;
                die $@ if $@;
            }

            # No cookie was given to us, or there was no file for it,
            # so create it.
            else {
                warn "CREATING NEW LCOAL SESSION\n";
                my $cookie_hash_value
                    = time() . rand(1) . $c->tx->remote_address;
                my $digester = Digest->new('SHA-1');
                $digester->add($cookie_hash_value);
                my $cookie_hash = $digester->hexdigest;

                my $cookie = Mojo::Cookie::Response->new;
                $cookie->name('session');
                $cookie->path('/');
                $cookie->value($cookie_hash);
                $c->tx->res->cookies($cookie);
                warn "CREATING NEW COOKIE $cookie_hash\n";

                # create the disk file to match
                $session_data->{last_update} = time();
                _dump_session( _hash_filename($cookie_hash), $session_data );
            }

            $session_data->{cookie_hash} = $cookie_hash;
            $c->stash->{$stash_key} = $session_data;

        }
    );

    $app->plugins->add_hook(
        after_dispatch => sub {
            my ( $self, $c ) = @_;

            warn "AFTER DISPATCH\n";
            warn "--------------\n";

            warn "PROCESSING " . $c->tx->req->url . "\n";

            # update the session data on-disk with the new
            # data from the data structure;
            my $session_data = $c->stash->{$stash_key};

            # hash is in session data
            my $cookie_hash = $session_data->{cookie_hash};
            delete $session_data->{cookie_hash};

            $session_data->{last_update} = time();

            if ($cookie_hash) {
                _dump_session( _hash_filename($cookie_hash), $session_data );
            }

        }
    );
}

sub _dump_session {
    my ( $filename, $session_data ) = @_;
    open my $fh, ">", $filename || die "$!";
    print $fh Data::Dumper->Dump( [$session_data], ['$session_data'] );
    close $fh || die "$!";
}

sub _hash_filename {
    my $hash = shift;
    warn "EXAMING $hash\n";

    return "/tmp/$hash.txt";
}

=head1 NAME

Mojolicious::Plugin::SimpleSession - The great new Mojolicious::Plugin::SimpleSession!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Mojolicious::Plugin::SimpleSession;

    my $foo = Mojolicious::Plugin::SimpleSession->new();
    ...

=head1 AUTHOR

Justin Hawkins, C<< <justin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-simplesession at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-SimpleSession>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::SimpleSession


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-SimpleSession>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-SimpleSession>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-SimpleSession>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-SimpleSession/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Justin Hawkins.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Mojolicious::Plugin::SimpleSession
