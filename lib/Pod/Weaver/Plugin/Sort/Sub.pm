package Pod::Weaver::Plugin::Sort::Sub;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Data::Sah qw(normalize_schema);
#use Data::Sah::Util::Type qw(get_type);

sub weave_section {
    no strict 'refs';

    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;

        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";

        if ($package =~ /^Sort::Sub::([a-z_0-9][^:]*)/) {
            my $routine = $1;

            my $meta = {};
            {
                local @INC = ("lib", @INC);
                require $package_pm;
                eval { $meta = $package->meta };
            }

            # add POD section: SYNOPSIS
            {
                my @pod;

                push @pod, (
                    "Generate sorter (accessed as variable) via L<Sort::Sub> import:\n\n",

                    " use Sort::Sub '\$$routine'; # use '\$$routine<i>' for case-insensitive sorting, '\$$routine<r>' for reverse sorting\n",
                    " my \@sorted = sort \$$routine ('item', ...);\n\n",

                    "Generate sorter (accessed as subroutine):\n\n",

                    " use Sort::Sub '$routine<ir>';\n",
                    " my \@sorted = sort {$routine} ('item', ...);\n\n",

                    "Generate directly without Sort::Sub:\n\n",

                    " use $package;\n",
                    " my \$sorter = $package\::gen_sorter(\n",
                    "     ci => 1,      # default 0, set 1 to sort case-insensitively\n",
                    "     reverse => 1, # default 0, set 1 to sort in reverse order\n",
                    " );\n",
                    " my \@sorted = sort \$sorter ('item', ...);\n\n",

                    "Use in shell/CLI with L<sortsub> (from L<App::sortsub>):\n\n",

                    " % some-cmd | sortsub $routine\n",
                    " % some-cmd | sortsub $routine --ignore-case -r\n\n",

                );
                $self->add_text_to_section(
                    $document, join("", @pod), "SYNOPSIS",
                    {ignore => 1},
                );
            }

            # add text to Description
            {
                my @pod;

                push @pod, (
                    "This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.\n\n",
                );
                $self->add_text_to_section(
                    $document, join("", @pod), "DESCRIPTION",
                    {ignore => 1},
                );
            }

            # create POD section: SORT ARGUMENTS
            {
                last unless $meta->{args};
                my @pod;

                push @pod, "C<*> marks required arguments.\n\n";

                for my $argname (sort keys %{ $meta->{args} }) {
                    my $argspec = $meta->{args}{$argname};

                    die "Argument '$argname' does not have schema" unless defined $argspec->{schema};
                    my $sch = normalize_schema($argspec->{schema});

                    push @pod, "=head2 $argname", ($argspec->{req} ? "*":""), "\n\n";

                    push @pod, "$sch->[0].\n\n";

                    push @pod, $argspec->{summary}, ".\n\n" if defined $argspec->{summary};

                    if ($argspec->{description}) {
                        require Markdown::To::POD;
                        my $pod = Markdown::To::POD::markdown_to_pod($argspec->{description});
                        # make sure we add a couple of blank lines in the end
                        $pod =~ s/\s+\z//s;
                        $pod .= "\n\n\n";
                        push @pod, $pod;
                    }
                }

                $self->add_text_to_section(
                    $document, join("", @pod), "SORT ARGUMENTS",
                    {ignore => 1},
                );
            }

            # add modules to See Also
            {
                my @pod;

                push @pod, (
                    "L<Sort::Sub>\n\n",
                );
                $self->add_text_to_section(
                    $document, join("", @pod), "SEE ALSO",
                    {ignore => 1},
                );
            }

            $self->log(["Generated POD for '%s'", $filename]);

        } # Sah::Schema::*
    }
}

1;
# ABSTRACT: Plugin to use when building Sort::Sub::* modules

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Sort::Sub]


=head1 DESCRIPTION

This plugin is used when building distribution that contains C<Sort::Sub::*>
routines (see L<Sort::Sub::naturally> for an example of such module; see also
L<Sort::Sub>). It currently does the following to F<lib/Sort/Sub/*> .pm
files:

=over

=item * Add Synopsis section if not already exists

=item * Add description about the module to Description section

=item * Add Sort Arguments section containing list of sort arguments, from metadata

=item * Mention some modules in See Also section

e.g. L<Sort::Sub>.

=back


=head1 SEE ALSO

L<Sort::Sub>

L<Dist::Zilla::Plugin::Sort::Sub>
