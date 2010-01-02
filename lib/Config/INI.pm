# vim:ft=perl6

grammar Config::INI::Grammar {
    token TOP {
        <root_section>?
        <section>+
    }
    token root_section {
        [ <property> | <ignore> ]*
    }
    regex section {
        ^^ '[' <.ws> $<name>=<-[\n\]]>*? <.ws> ']' \h* \n
        [ <property> | <ignore> ]*
    }
    regex property {
        ^^ <.ws> $<name>=[<.print>+?] <.ws> '=' <.ws> $<value>=[\N*?] \h* \n
    }
    token ignore {
        | ^^ <.ws> [';'|'#'] [\N*] \n
        | ^^ \h* \n
    }
}

class Config::INI {
    has %.sections is rw;
    has $.file     is rw;

    method read (Str $file) {
        $.file = $file;
        self.read_string(slurp($file));
    }

    # tried to do a multi to avoid the //= but couldn't multi on void sigs
    method properties (Str $name? is rw) {
        $name //= '';    
        if not %.sections.exists($name) {
            die "No properties found for ($name)";
        }
        return %.sections{$name};
    }
    method add_properties(:%properties!, Str :$name = '') {
        %.sections{$name} = %properties;
    }

    method read_string(Str $text) {
        %.sections = ();
        my $config = Config::INI::Grammar.parse($text);

        if not $config {
            my $file = $.file;
            die $file 
                ?? "Could not parse ($file): not a valid INI file"
                !! "Could not parse string: not valid INI format";
        }

        # there can only be one
        if my $root = $config<root_section>[0]<property> {
            # XXX Why do I have to stringify the value?
            %.sections{''} = %( $root.map: { ( '' ~ $_<name> => '' ~ $_<value> ) } );
        }

        for $config<section> -> $section {
            my $name = $section<name>;
            my %properties = $section<property>.map: { ( '' ~ $_<name> => '' ~ $_<value>) };
            %.sections{$name} = %properties;
        }
        return 1;
    }

    method write (Str $file) {
        my $fh = open $file, :w;
        if my $prop = self.properties {
            for $prop.kv -> $name, $value {
                $fh.say: "$name=$value";
            }
        }
        for %.sections.kv -> $section, $properties {
            next if '' eq $section; # written above
            $fh.say: "\n[ $section ]"; # blank line before each section
            for $properties.kv -> $name, $value {
                $fh.say: "$name=$value";
            }
        }
        $fh.close;
    }
}

=begin pod

=head1 NAME

Config::INI - Read INI files

=head1 SYNOPSIS

 my Config::INI $config .= new;
 $config.read($file);

 for $config.properties.kv -> $k, $v {
     say "$ky = $v";
 }
 for $config.properties($section_name).kv -> $k, $v {
     say "$ky = $v";
 }

=head1 DESCRIPTION

This module reads INI files.  Unfortunately, different authors have, over the
years, implemented their idea of what INI files should be, so we try to be a
bit tolerant.  Each line in an INI file should match the general form of:

 $key '=' $value

For each key and value, we trim the leading and trailing whitespace (but leave
embedded whitespace alone).  Lines beginning with a semi-colon (;), a hash
mark (#) or containing only whitespace are ignored.

Optionally, a "section" may be defined by prepending sets of k/v pairs with a
name in square brackets.  The following will place subsequent k/v pairs under
the 'admin user' section (note the leading and trailing whitespace are
trimmed).

 [ admin user ]
    ; virtually omnipotent
    alias = root
    hair  = fabulous

=head1 METHODS

=head2 Class Methods

=head3 C<new>

 my Config::INI $config .= new;

Takes no arguments. Returns a C<Config::INI> object.

=head2 Instance Methods

=head3 C<read>

 my Config::INI .= new;
 $config.read($filename);

Attempts to read an INI file.  Will die if the filename does not exist or if
the format does not appear to be an INI file.

=head3 C<properties>

 my %root_properties = $config.properties;
 my %admin           = $config.properties('admin');

Returns a hash of the k/v pairs. If no name is given, returns the root
properties (properties defined before any section marker).  Otherwise,
attempts to return a hash of the properties for a given section.

Dies if we attempt to fetch properties for a section not in the INI file.

=head3 C<add_properties>

 # add root properties
 $config.add_properties(properties => %hash);

 # or the standard:
 $config.add_properties(:%properties);

 # add section properties
 $config.add_properties( 
   name       => 'admin',
   properties => %admin,
 );
 # or:
 $config.add_properties(:$name, :%properties);

This method will add properties to a config object, overwriting any existing
properties with the given C<$name>.  Note that if a name is not specified,
these will be the I<root> properties returned by C<$config.properties>.

=head3 C<write>

 $config.write($filename);

Attempts to write out an INI file to the appropriate C<$filename>.

=end pod
