package Dancer::Template::Xslate;

# ABSTRACT: Text::Xslate wrapper for Dancer

use strict;
use warnings;

use Text::Xslate;
use Dancer::App;
use File::Spec;

use base 'Dancer::Template::Abstract';

my $_engine;

sub default_tmpl_ext { "tx" }

sub init {
    my $self = shift;

    my %args = (
        %{$self->config},
    );

    ## set default path for header/footer etc.
    $args{path} ||= [];
    my $view_dir = Dancer::App->current->setting('views');
    push @{$args{path}}, $view_dir unless grep { $_ eq $view_dir } @{$args{path}};
    
    ## for those people read Text::Xslate instead of Dancer::Template::Abstract
    $self->config->{extension} = $args{suffix} if exists $args{suffix};
    # avoid 'Text::Xslate: Unknown option(s): extension'
    $args{suffix} = delete $args{extension}    if exists $args{extension};
    
    $_engine = Text::Xslate->new(%args);
}

sub render {
    my ($self, $template, $tokens) = @_;
    
    # absolute filename will never work under Windows even we hard set path as ['/']
    my $view_dir = Dancer::App->current->setting('views');
    if ( $view_dir ) {
        $view_dir = File::Spec->catdir( File::Spec->splitdir($view_dir) ) if $^O eq 'MSWin32'; # dirty Win32 fixes for / \
        $template =~ s/^\Q$view_dir\E//;
    }

    my $content = eval {
        $_engine->render($template, $tokens)
    };

    if (my $err = $@) {
        my $error = qq/Couldn't render template "$err"/;
        die $error;
    }

    return $content;
}

1;

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Text::Xslate> module.

In order to use this engine, use the template setting:

    template: xslate

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

You can configure L<Text::Xslate> :

    template: xslate
    engines:
      xslate:
        cache_dir  => "/www/../xslate_cache",
        cache      => 1,
        module =>
          - Text::Xslate::Bridge::TT2 # to keep partial compatibility


=head1 SEE ALSO

L<Dancer>, L<Text::Xslate>, L<http://xslate.org/>
