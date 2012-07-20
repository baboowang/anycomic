package AnyComic::Locale;
use Encode ();

our $ENCODING_LOCALE;
our $ENCODING_LOCALE_FS;
our $ENCODING_CONSOLE_IN;
our $ENCODING_CONSOLE_OUT;

sub DEBUG () { 0 }

sub _init {
    if ($^O eq "MSWin32") {
    unless ($ENCODING_LOCALE) {
        # Try to obtain what the Windows ANSI code page is
        eval {
        unless (defined &GetACP) {
            require Win32::API;
            Win32::API->Import('kernel32', 'int GetACP()');
        };
        if (defined &GetACP) {
            my $cp = GetACP();
            $ENCODING_LOCALE = "cp$cp" if $cp;
        }
        };
    }

    unless ($ENCODING_CONSOLE_IN) {
        # If we have the Win32::Console module installed we can ask
        # it for the code set to use
        eval {
        require Win32::Console;
        my $cp = Win32::Console::InputCP();
        $ENCODING_CONSOLE_IN = "cp$cp" if $cp;
        $cp = Win32::Console::OutputCP();
        $ENCODING_CONSOLE_OUT = "cp$cp" if $cp;
        };
        # Invoking the 'chcp' program might also work
        if (!$ENCODING_CONSOLE_IN && (qx(chcp) || '') =~ /^Active code page: (\d+)/) {
        $ENCODING_CONSOLE_IN = "cp$1";
        }
    }
    }

    unless ($ENCODING_LOCALE) {
    eval {
        require I18N::Langinfo;
        $ENCODING_LOCALE = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());

        # Workaround of Encode < v2.25.  The "646" encoding  alias was
        # introduced in Encode-2.25, but we don't want to require that version
        # quite yet.  Should avoid the CPAN testers failure reported from
        # openbsd-4.7/perl-5.10.0 combo.
        $ENCODING_LOCALE = "ascii" if $ENCODING_LOCALE eq "646";

        # https://rt.cpan.org/Ticket/Display.html?id=66373
        $ENCODING_LOCALE = "hp-roman8" if $^O eq "hpux" && $ENCODING_LOCALE eq "roman8";
    };
    $ENCODING_LOCALE ||= $ENCODING_CONSOLE_IN;
    }

    if ($^O eq "darwin") {
    $ENCODING_LOCALE_FS ||= "UTF-8";
    }

    # final fallback
    $ENCODING_LOCALE ||= $^O eq "MSWin32" ? "cp1252" : "UTF-8";
    $ENCODING_LOCALE_FS ||= $ENCODING_LOCALE;
    $ENCODING_CONSOLE_IN ||= $ENCODING_LOCALE;
    $ENCODING_CONSOLE_OUT ||= $ENCODING_CONSOLE_IN;

    unless (Encode::find_encoding($ENCODING_LOCALE)) {
    my $foundit;
    if (lc($ENCODING_LOCALE) eq "gb18030") {
        eval {
        require Encode::HanExtra;
        };
        if ($@) {
        die "Need Encode::HanExtra to be installed to support locale codeset ($ENCODING_LOCALE), stopped";
        }
        $foundit++ if Encode::find_encoding($ENCODING_LOCALE);
    }
    die "The locale codeset ($ENCODING_LOCALE) isn't one that perl can decode, stopped"
        unless $foundit;

    }

    # use Data::Dump; ddx $ENCODING_LOCALE, $ENCODING_LOCALE_FS, $ENCODING_CONSOLE_IN, $ENCODING_CONSOLE_OUT;
}

_init();
1;
