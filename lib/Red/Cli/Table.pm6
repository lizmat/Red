use Red::Utils;
use Red::Cli::Column;
use Red::Cli::Relationship;
unit class Red::Cli::Table;

has Str $.name is required;
has Str $.model-name = snake-to-camel-case $!name;
has @.columns;
has @.relationships;

submethod TWEAK(:@columns) {
    for @columns -> $col {
        $col.table = self;
        with $col.references {
            @!relationships.push: Red::Cli::Relationship.new: :id($col)
        }
    }
}

multi method model-definition($ where so *)  { "unit model { $!model-name };\n" }
multi method model-definition($ where not *) { "model { $!model-name } \{" }
multi method model-end($ where so *)  { "" }
multi method model-end($ where not *) { "\}" }

method to-code(Str :$schema-class, Bool :$no-relationships) {
    my $unit = not $schema-class.defined;
    qq:to/END/;
    { self.model-definition: $unit }
    { do for @!columns -> $col {
        $col.to-code: :$schema-class
    }.join("\n").indent: $unit ?? 0 !! 4 }
    { "\n" ~ do for @!relationships -> $rel {
        $rel.to-code: :$schema-class
    }.join("\n").indent: $unit ?? 0 !! 4 unless $no-relationships}
    { self.model-end: $unit }
    END
}

method diff(::?CLASS $b) {
    my @diffs;
    @diffs.push: (:name{"-" => $!name, "+" => $b.name}) if $!name ne $b.name;
    @diffs.push: (:n-of-cols{"-" => @!columns.elems, "+" => $b.columns.elems}) if @!columns != $b.columns;
    my @a = @!columns.sort:  *.name;
    my @b = $b.columns.sort: *.name;

    while @a > 0 and @b > 0 {
        if @a.head.name eq @b.head.name {
            @diffs.append: ( :col-attr(@a.head.name => @a.shift.diff: @b.shift) );
            next
        }
        if @b.head lt @a.head {
            @diffs.push: (:col{"+" => @b.shift});
            next
        }
        if @a.head lt @b.head {
            @diffs.push: (:col{"-" => @a.shift});
            next
        }
    }
    @diffs.push: (:col{"+" => $_}) for @b;
    @diffs.push: (:col{"-" => $_}) for @a;
    @diffs
}
