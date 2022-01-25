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

my $output_file = shift || '-';
my $out_fh;
if($output_file ne '-') {
    open $out_fh, '>', $output_file
        || die("Couldn't write to $output_file: $!\n");
    binmode $out_fh, ':utf8';
    select $out_fh;
}

my @warnings = ();
END {
    warn("$_\n") foreach @warnings;

    if($output_file ne '-') {
        exec(qw(plutil -lint), $output_file);
    }
}

my $compose = "§";

my @mappings = ( map { s/\s*#.*//; [ split(/\s+/, $_) ] } split("\n", <<"END_OF_MAPPINGS"));
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
gbp £
EUR €
eur €
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
contains ∋
element ∈
member ∈
subset ⊂
superset ⊃
union ∪
intersection ∩
degree °
tm ™
copy ©
END_OF_MAPPINGS

# cope with lazy multi-char mappings like 'GBP £'
foreach my $mapping (@mappings) {
    $mapping = [
        ( map { split(//, $_) } (@{$mapping})[0 .. $#{$mapping} - 1] ),
        $mapping->[-1]
    ]
}

push @mappings, _fractions(), _super_sub_scripts(), _accents(), _greek(), _emoji(),
    [ $compose, $compose ],
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
            push @warnings, "Clash: $this_mapping clashes with $found_mapping; ignoring";
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
    foreach my $sequence (qw(
        alpha beta gamma delta epsilon zeta eta theta iota kappa lambda lamda
        mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega
    )) {
        # Unicode doesn't know how to spell LAMBDA
        my $letter_name = ($sequence eq 'lambda') ? 'lamda' : $sequence;
        push @mappings, [
            split(//, uc("gr$sequence")),
            charnames::string_vianame('GREEK CAPITAL LETTER '.uc($letter_name))
        ], [
            split(//, "gr$sequence"),
            charnames::string_vianame('GREEK SMALL LETTER '.uc($letter_name))
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
            [ 'heart',   'BLACK HEART SUIT'     ],
        )
    );
}

sub _accents {
    my @mappings = ();
    foreach my $letter ( ( 'a' .. 'z' ), ( 'A' .. 'Z' ) ) {
        my %accent_table = (
            # maps:
            #   ^ -> \\\\\\U005E
            #   ~ -> \\\\\\U007E
            #   " -> \\\\\\U0022
            ACUTE          => "'",           GRAVE     => '`', CIRCUMFLEX => '\\\\\\U005E',
            TILDE          => '\\\\\\U007E', DIAERESIS => ':', CEDILLA    => ',',
            STROKE         => '/',           MACRON    => '_', CARON      => 'v',
            'RING ABOVE'   => 'o',
            'DOUBLE ACUTE' => '\\\\\\U0022',
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
    foreach my $character (qw(+ -), 0 .. 9) {
        push @mappings, [
            $character, '\\\\\\U005E', # 0, hat
            charnames::string_vianame('SUPERSCRIPT '._character_name($character))
        ], [
            $character, 'v', # 0, v
            charnames::string_vianame('SUBSCRIPT '._character_name($character))
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
                _character_name($numerator).' '.
                _denominator_name($denominator).
                ($numerator == 1 ? '' : 'S')
            )) {
                push @mappings, [ $numerator, split(//, $denominator), $char ];
            }
        }
    }
    return @mappings;
}
sub _character_name ($n) {
    my $counter = 0;
    {
        '+' => 'PLUS SIGN',
        '-' => 'MINUS',
        map { $counter++ => $_ } qw(ZERO ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE)
    }->{$n};
}
sub _denominator_name ($n) {
    [ '', '', qw(HALF THIRD QUARTER FIFTH SIXTH SEVENTH EIGHTH NINTH TENTH) ]->[$n]
}
