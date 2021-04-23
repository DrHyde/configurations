#!/usr/bin/env perl
#
# See https://github.com/gnarf/osx-compose-key
# and http://xahlee.info/comp/unicode_emoticons.html
#
# In Karabiner, map From 'application' to 'non_us_backslash' for
# the Sun keyboard, and copy what this generates to DefaultKeyBinding.dict
# and hence to ~/Library/KeyBindings/...
#
# 'Application' is what Apple calls the real Compose key. 'non_us_backslash'
# is what Apple calls the utterly useless § symbol.


use 5.010;
use strict;
use warnings;
use utf8;
use experimental 'signatures';
use charnames ':full';
binmode STDOUT, ':utf8';

my $compose = "§";

my @mappings = ( map { s/\s*#.*//; [ split(/\s+/, $_) ] } split("\n", <<"END_OF_MAPPINGS"));
l - ł
L - Ł
d - ð
D - Ð
T H Þ
t h þ      # NB potential clash with Greek theta
A E Æ
a e æ
O E Œ
o e œ
s s ß
GBP £
EUR €
YOGH Ȝ
yogh ȝ
WYNN Ƿ
wynn ƿ
aleph ℵ
complex ℂ
real ℝ
rational ℚ
integer ℤ
natural ℕ
prime ℙ
sing flat welsh
END_OF_MAPPINGS

# cope with lazy multi-char mappings like 'sing flat welsh'
foreach my $mapping (@mappings) {
    $mapping = [
        ( map { split(//, $_) } (@{$mapping})[0 .. $#{$mapping} - 1] ),
        $mapping->[-1]
    ]
}

push @mappings, _fractions(), _super_sub_scripts(), _accents(), _greek(), _emoji(),
    [ qw(z a l g o), "H̸̡̪̯ͨ͊̽̅̾̎Ȩ̬̩̾͛ͪ̈́̀́͘ ̶̧̨̱̹̭̯ͧ̾ͬC̷̙̲̝͖ͭ̏ͥͮ͟Oͮ͏̮̪̝͍M̲̖͊̒ͪͩͬ̚̚͜Ȇ̴̟̟͙̞ͩ͌͝S̨̥̫͎̭ͯ̿̔̀ͅ" ],
    ;

my $tree = {};

MAPPING: foreach my $mapping (@mappings) {
    my @keys = ($compose, @{$mapping});

    my $output = pop(@keys);

    my $prev_container = $tree;
    my $this_mapping   = join('', (@keys)[1..$#keys]);
    my $found_mapping  = '';

    while(@keys) {
        my $this_key = shift(@keys);
        if(!ref($prev_container)) {
            warn("Clash: $this_mapping clashes with $found_mapping; ignoring\n");
            next MAPPING;
        }
        if(!exists($prev_container->{$this_key})) {
            if(@keys) {
                $prev_container->{$this_key} = {};
                $prev_container = $prev_container->{$this_key};
            } else {
                $prev_container->{$this_key} = $output;
            }
        } else {
           $found_mapping .= $this_key unless($this_key eq $compose);
           $prev_container = $prev_container->{$this_key};
        }
    }
}

say substr(_convert_to_dict($tree, '  '), 0, -1);

sub _convert_to_dict ($tree, $indent) {
    join("\n$indent",(
        '{',
        (map {
            '"'.$_.'" = '.
            (ref($tree->{$_})
                ? _convert_to_dict($tree->{$_}, "$indent  ")
                : '("insertText:", "'.$tree->{$_}.'");'
            )
        } sort keys(%{$tree}))
    ))."\n".substr($indent, 2)."};";
}

sub _greek {
    my @mappings = ();
    foreach my $word (qw(
        alpha beta gamma delta epsilon zeta eta theta iota kappa lambda
        mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega
    )) {
        push @mappings, [
            qw(G R),
            split(//, uc($word)),
            charnames::string_vianame('GREEK CAPITAL LETTER '.uc($word))
        ], [
            qw(g r),
            split(//, $word),
            charnames::string_vianame('GREEK SMALL LETTER '.uc($word))
        ];
    }
    return @mappings;
}

sub _emoji {
    return map {
        [ split(//, $_->[0]), $_->[1] ]
    } (
        [ 'go', "\N{U+7881}" ],
        map { [ $_->[0], charnames::string_vianame($_->[1]) ] } (
            [ 'cricket', 'CRICKET BAT AND BALL' ],
            [ 'rugby',   'RUGBY FOOTBALL'       ],
        )
    );
}

sub _accents {
    my @mappings = ();
    foreach my $letter (qw(a c e i n o u w y A C E I N O U W Y)) {
        my %accent_table = (
            ACUTE        => "'", GRAVE     => '`', CIRCUMFLEX => '^',
            TILDE        => '~', DIAERESIS => ':', CEDILLA    => ',',
            STROKE       => '/', MACRON    => '_', CARON      => 'v',
            'RING ABOVE' => 'o',
        );
        foreach my $accent (keys %accent_table) {
            if(my $char = charnames::string_vianame(
                'LATIN '.
                ($letter eq uc($letter) ? 'CAPITAL' : 'SMALL').' '.
                'LETTER '.
                uc($letter).' '.
                'WITH '.
                $accent
            )) {
                push @mappings, [ $letter, $accent_table{$accent}, $char ];
            }
        }
    }
    return @mappings;
}

sub _super_sub_scripts {
    my @mappings = ();
    foreach my $number (0 .. 9) {
        push @mappings, [
            $number, '$\\UF700', # 0, shift-up
            charnames::string_vianame('SUPERSCRIPT '._number_name($number))
        ], [
            $number, '$\\UF701', # 0, shift-down
            charnames::string_vianame('SUBSCRIPT '._number_name($number))
        ]
    }
    return @mappings;
}

sub _fractions {
    my @mappings = ();
    foreach my $numerator (0 .. 9) {
        foreach my $denominator (2 .. 10) {
            if(my $char = charnames::string_vianame(
                'VULGAR FRACTION '.
                _number_name($numerator).' '.
                _denominator_name($denominator).
                ($numerator == 1 ? '' : 'S')
            )) {
                push @mappings, [ $numerator, split(//, $denominator), $char ];
            }
        }
    }
    return @mappings;
}
sub _number_name ($n) {
    [ qw(ZERO ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE) ]->[$n]
}
sub _denominator_name ($n) {
    [ '', '', qw(HALF THIRD QUARTER FIFTH SIXTH SEVENTH EIGHTH NINTH TENTH) ]->[$n]
}
