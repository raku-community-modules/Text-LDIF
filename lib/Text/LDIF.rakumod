use Text::LDIF::Grammar;
use Text::LDIF::Actions;

class Text::LDIF {
    method parse(Str:D $txt) {
        my $text := $txt
          .subst(/"\n "/, '', :g)
          .subst(/'#' .*? "\n"/, "", :g);
        Text::LDIF::Grammar.parse($text, actions => Text::LDIF::Actions).made
    }
}

=begin pod

=head1 NAME

Text::LDIF - Pure Raku LDIF file parser

=head1 SYNOPSIS

=begin code :lang<raku>

use Text::LDIF;

my $ldif-content = slurp @*ARGS[0];

my $ldif = Text::LDIF.new;

my $result = $ldif.parse($ldif-content);

if $result {
	for $result<entries><> -> $entry {
        say "dn -> ", $entry<dn>;
        my %attrs = $entry<attrs>;
        for %attrs.kv -> $attr, $value {
            say "\t$attr ->\t$_" for @$value;
            # some further processing for cases of attributes with options,
            # base64, file urls, etc
        }
		say "-" x 40;
	}
}
else {
    say "Parsing error";
}

=end code

=head1 DESCRIPTION

C<Text::LDIF> is a Raku module for parsing LDIF files according to RFC 2849.

For the end-user, the C<Text::LDIF> class is available to use.  It has
a C<parse> method that accepts a C<Str> that contains text of LDIF file
and returns a structure that describes the file.

=head1 OUTPUT STRUCTURE

LDIF can contain either a description of a number of LDAP entries
or a set of changes made to directory entries. In case of LDAP entries
description, the parsing result looks this way:

=begin output
{
  version => 1, # exact number is parsed from file
  entries => [
    {
      dn => $dn-string,
      attrs => {
        # For a simple value, just string
        attr1 => 'foo',
        # For an attribute with many values, a list
        attr2 => ['foo', 'baz', 'bar'],
        # For base64 string a Pair
        attr3 => base64 => 'V2hhdCBh...',
        attr-with-opts => { # OPTIONS
          '' => 'value-of-just-attr-with-opts',
          lang-ja => 'value of attr-with-opts:lang-ja',
          lang-ja,phonetic => 'value of attr-with-opts:lang-ja:phonetic',
        },
        fileattr => file => 'file://foo.jpg', # eternal file url
        ...
      }
    },
        ...
  ]
}
=end output

A parsing result of modifications looks this way:

=begin output
{
  version => 1,
  changes => [
    { # ADD
      dn => $dn-string,
      change => add => {
        attr1 => ...
      },
      controls => []
    },
    { # DELETE
      dn => $dn-string,
      change => 'delete',
      controls => []
    },
    { # MODDN
      dn => $dn-string,
      change => moddn => {
        delete-on-rdn => True, # Bool value
        newrdn => 'foo=baz',
        superior => Any # if not specified
      },
      controls => []
    },
    { # MODIFY
      dn => $dn-string,
      change => modify => [
        add => attr1 => 'attr1-value',
        delete => attr2,
        replace => attr3 => ['old-value', 'new-value'],
        ...
      ],
      controls => [ # CONTROLS
        {
          ldap-oid => '1.2.840...',
          criticality => True, # Bool value
          value => 'new-foo-value'
        },
        ...
      ]
    },
    ...
  ]
}
=end output

=head1 AUTHOR

=item Sylwester Lunski
=item Alexander Kiryuhin

=head1 COPYRIGHT AND LICENSE

Copyright 2016 - 2021 Alexander Kiryuhin

Copyright 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
