package Markup::Unified;

use strict;
use warnings;
use base qw(Class::Accessor);
use Module::Load::Conditional qw/can_load check_install/;

use overload	(	'fallback' => 1,
			'""'  => 'formatted',
		);

__PACKAGE__->mk_accessors(qw/value fvalue/);

=head1 NAME

Markup::Unified - A simple, unified interface for Textile, Markdown and BBCode.

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;

# attempt to load Text::Textile
our $t = undef;
if (can_load(modules => { 'Text::Textile' => '2.12' })) {
	$t = Text::Textile->new();
	$t->charset('utf-8');
}

# attempt to load Text::Markdown
our $m = can_load(modules => { 'Text::Markdown' => '1.0.25' }) ? Text::Markdown->new() : undef;

# attempt to load HTML::BBCode
our $b = can_load(modules => { 'HTML::BBCode' => '2.06' }) ? HTML::BBCode->new({ stripscripts => 1, linebreaks => 1 }) : undef;

# attempt to load HTML::Truncate
our $trunc = can_load(modules => { 'HTML::Truncate' => '0.20' }) ? 1 : undef;

=head1 SYNOPSIS

    use Markup::Unified;

    my $o = Markup::Unified->new();
    my $text = 'h1. A heading';
    $o->format($text, 'textile');

    print $o->formatted; # produces "<h1>A heading</h1>"
    print $o->unformatted; # produces "h1. A heading"

    # you can also just say:
    print $o; # same as "print $o->formatted;"

=head1 DESCRIPTION

This module provides a simple, unified interface for the L<Text::Textile>,
L<Text::Markdown> and L<HTML::BBCode> markup languages modules. This module is
primarily meant to provide a simple way for application developers to deal
with texts that use different markup languages, for example, a message
board where users have the ability to post with their preferred markup language.

Please note that this module expects your texts to be UTF-8.

In order for this module to be useful at any way, at least one of the three
parsing modules (L<Text::Textile>, L<Text::Markdown> or L<HTML::BBCode>)
must be installed. None of these are required, but if you try to parse
a text formatted in any of these markup languages without the respective
module being installed on your system, then the text will be returned
unformatted, and no errors will be raised.

=head1 METHODS

=head1 new()

Creates a new, empty instance of Markup::Unified.

=head2 format( $text, $markup_lang )

Formats the provided text with the provided markup language.
C<$markup_lang> must be one of 'bbcode', 'textile' or 'markdown' (case
insensitive); otherwise the text will remain unprocessed (which is also
true if the appropriate markup module is not installed on your system).

=cut

sub format {
	my ($self, $text, $markup_lang) = @_;

	$self->value($text); # keep unformatted text

	# format according to the formatter
	if ($markup_lang && $markup_lang =~ m/^bbcode/i) {
		$self->fvalue($self->_bbcode($text));
	} elsif ($markup_lang && $markup_lang =~ m/^textile/i) {
		$self->fvalue($self->_textile($text));
	} elsif ($markup_lang && $markup_lang =~ m/^markdown/i) {
		$self->fvalue($self->_markdown($text));
	} else {
		# either no markup language given or unrecognized language
		# so formatted = unformatted
		$self->fvalue($text);
	}

	return $self;
}

=head2 formatted()

Returns the formatted text of the object, with whatever markup language
it was set.

This module also provides the ability to print the formatted version of
an object without calling C<formatted()> explicitly, so you can just use
C<print $obj>.

=cut

sub formatted { $_[0]->fvalue; }

=head2 unformatted()

Returns the unformatted text of the object.

=cut

sub unformatted { $_[0]->value; }

=head2 truncate([ $length_str, $ellipsis ])

NOTE: This feature requires the presence of the L<HTML::Truncate> module.
If it is not installed, this method will simply return the output of the
L<formatted()> method without raising any errors.

This method returns the formatted text of the object, truncated according to the
provided length string. This string should be a number followed by one
of the characters 'c' or '%'. For example, C<$length_str = '250c'> will
return 250 characters from the object's text. C<$length_str = '10%'> will
return 10% of the object's text (characterwise). If a length string is
not provided, the text will be truncated to 250 characters by default.

This is useful when you wish to display just a sample of the text, such
as in a list of blog posts, where every listing displays a portion of the
post's text with a "Read More" link to the full text in the end.

If an C<$ellipsis> is provided, it will be used as the text that will be
appended to the truncated HTML (i.e. "Read More"). Read L<HTML::Truncate>'s
documentation for more info. Defaults to &#8230; (HTML entity for the
'...' ellipsis character).

=cut

sub truncate {
	my ($self, $length_str, $ellipsis) = @_;

	# make sure HTML::Truncate is loaded, otherwise just return the
	# formatted text in its entirety
	return $self->formatted unless $trunc;

	my $ht = HTML::Truncate->new(utf8_mode => 1, on_space => 1);

	$length_str =~	m/^(\d+)c$/i ? $ht->chars($1) :
			m/^(\d+)%$/ ? $ht->percent($1) : $ht->chars(250);

	$ht->ellipsis($ellipsis) if $ellipsis;

	return $ht->truncate($self->formatted);
}

=head2 supports( $markup_lang )

Returns a true value if the requested markup language is supported by
this module (which basically means the appropriate module is installed
and loaded). C<$markup_lang> must be one of 'textile', 'bbcode' or 'markdown'
(case insensitive).

Returns a false value if the requested language is not supported.

=cut

sub supports {
	my ($self, $markup_lang) = @_;

	if ($markup_lang =~ m/^textile$/i) {
		return $t ? 1 : undef;
	} elsif ($markup_lang =~ m/^markdown$/i) {
		return $m ? 1 : undef;
	} elsif ($markup_lang =~ m/^bbcode$/i) {
		return $b ? 1 : undef;
	}

	return undef;
}

=head1 INTERNAL METHODS

=head2 _bbcode( $text )

Formats C<$text> with L<HTML::BBCode>.

=cut

sub _bbcode {
	my ($self, $text) = @_;

	return $b ? $b->parse($text) : $text;
}

=head2 _textile( $text )

Formats C<$text> with L<Text::Textile>.

=cut

sub _textile {
	my ($self, $text) = @_;

	return $t ? $t->textile($text) : $text;
}

=head2 _markdown( $text )

Formats C<$text> with L<Text::Markdown>.

=cut

sub _markdown {
	my ($self, $text) = @_;

	return $m ? $m->markdown($text) : $text;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-markup-unified at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Markup-Unified>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Markup::Unified

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Markup-Unified>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Markup-Unified>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Markup-Unified>

=item * Search CPAN

L<http://search.cpan.org/dist/Markup-Unified/>

=back

=head1 SEE ALSO

L<Text::Textile>, L<Text::Markdown>, L<HTML::BBCode>, L<HTML::Truncate>,
L<DBIx::Class::InflateColumn::Markup::Unified>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Markup::Unified
