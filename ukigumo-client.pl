#!/usr/local/bin/perl

use strict;
use warnings;
use utf8;
use 5.008001;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), '..', 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), '..', 'lib');

package main;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

use Ukigumo::Client;
use Ukigumo::Client::Executor::Auto;
use Ukigumo::Client::Executor::Command;
use Ukigumo::Client::Notify::Debug;
use Ukigumo::Client::Notify::Callback;

$ENV{AUTOMATED_TESTING} = 1;
$ENV{CI} = 1;

GetOptions(
    'branch=s'           => \my $branch,
    'workdir=s'          => \my $workdir,
    'repo=s'             => \my $repo,
    'server_url|s=s'     => \my $server_url,
    'project=s'          => \my $project,
    'vc=s'               => \my $vc,
    'command=s'          => \my $command,
    'skip_if_unmodified' => \my $skip_if_unmodified,
);

$repo       or do { warn "Missing mandatory option: --repo\n\n"; pod2usage() };
$server_url or do { warn "Missing mandatory option: --server_url\n\n"; pod2usage() };
warn "--comand option was deprecated. I'll remove in future version" if $command;

$vc = 'Git' unless $vc;
my $vc_module = "Ukigumo::Client::VC::$vc";
eval "require $vc_module; 1" or die $@;

$branch = $vc_module->default_branch unless $branch;
die "Bad branch name: $branch" unless $branch =~ m{^[A-Za-z0-9./_-]+$}; # guard from web
$server_url =~ s!/$!! if defined $server_url;

my $app = Ukigumo::Client->new(
    (defined($workdir) ? (workdir => $workdir) : ()),
    vc => $vc_module->new(
        branch     => $branch,
        repository => $repo,
        ($skip_if_unmodified ? (skip_if_unmodified => $skip_if_unmodified) : ()),
    ),
    executor   => ($command ?
        Ukigumo::Client::Executor::Command->new(command => $command) :
        Ukigumo::Client::Executor::Perl->new()
    ),
    server_url => $server_url,
    ($project ? (project => $project) : ()),
);

$app->push_notifier( 
    Ukigumo::Client::Notify::Callback->new(
        send_cb => sub {
            my ( $c, $status, $last_status, $report_url ) = @_;

            # Uncomment this section if you want to send test report email
            #my $to = '';
            #my $from = '';
            #my $subject = 'Ukigumo Test Result';
            #my $rev = $c->current_revision;
            #my $message = "Revision: $rev \nStatus: $status \nReport: $report_url";
            #open ( MAIL, "|/usr/sbin/sendmail -t");
            #print MAIL "To: $to\n"; 
            #print MAIL "From: $from\n";
            #print MAIL "Subject: $subject\n\n";
            #print MAIL $message;
            #close ( MAIL );
        },
    )
);

$app->run();
exit 0;

__END__

=head1 NAME

ukigumo-client.pl - ukigumo client script

=head1 SYNOPSIS

    % ukigumo-client.pl --repo=git://... --server_url=http://...
    % ukigumo-client.pl --repo=git://... --server_url=http://... --branch foo

        --repo=s             URL for repository
        --project=s          project name(optional)
        --vc                 version controll system('Git' by default)
        --workdir=s          workdir directory for working(optional)
        --branch=s           branch name(VC::{vc}->default_branch by default)
        --server_url|s=s     Ukigumo server url(using app.psgi)
        --skip_if_unmodified skip testing if repository is unmodified

=head1 DESCRIPTION

This is a yet another continuous testing tools.

=head1 EXAMPLE

    perl bin/ukigumo-client.pl --server_url=http://localhost:9044/ --repo=git://github.com/tokuhirom/Acme-Failing.git --branch=master

=cut
