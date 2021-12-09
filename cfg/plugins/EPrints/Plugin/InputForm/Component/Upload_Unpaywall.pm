######################################################################
#
#  Unpaywall Lookup Component
#
#  Part of https://idbugs.uzh.ch/browse/ZORA-780
#  
######################################################################
#
#  Copyright 2020- University of Zurich. All Rights Reserved.
#
#  Martin Brändle
#  Zentrale Informatik
#  Universität Zürich
#  Stampfenbachstr. 73
#  CH-8006 Zürich
#
#  The plug-ins are free software; you can redistribute them and/or modify
#  them under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The plug-ins are distributed in the hope that they will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with EPrints 3; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
######################################################################


package EPrints::Plugin::InputForm::Component::Upload_Unpaywall;

use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use EPrints::Plugin::InputForm::Component;

use base 'EPrints::Plugin::InputForm::Component';

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );
	
	$self->{name} = "Upload_Unpaywall";
	$self->{visible} = "all";
	$self->{surround} = "Unpaywall";

	return $self;
}

sub has_help
{
	my( $self, $surround ) = @_;
	return $self->{session}->get_lang->has_phrase( $self->html_phrase_id( "help" ) );
}



sub render_title
{
	my( $self, $surround ) = @_;
	
	my $response = $self->{unpaywall_response};
	
	if (defined $response->{error})
	{
		return $self->html_phrase( "title_doierror" );
	}
	
	if (200 != $response->code && 404 != $response->code)
	{
		 return $self->html_phrase( "title_unpaywall_unavailable" );
	}
	else
	{
		my $content = $response->content;
		my $json_vars = JSON::decode_json($content);
		
		if (defined $json_vars->{error} && $json_vars->{error} eq "true" )
		{
			return $self->html_phrase( "title_error" );
		}
		else
		{
			my $best_oa_location = $json_vars->{best_oa_location};
			if (defined $best_oa_location)
			{
				my $article_version = $best_oa_location->{version};
				my $version_phrase = $self->html_phrase( $article_version );
				return $self->html_phrase( "version_title", version => $version_phrase);
			}
			else
			{
				return $self->html_phrase( "not_oa_title" );
			}
		}
	}
	
	return $self->html_phrase( "default_title" );
}


sub get_fields_handled
{
	my( $self ) = @_;
	return ( );
}

sub render_content
{
	my( $self, $surround ) = @_;
	
	my $session = $self->{session};
	
	my $html = $session->make_doc_fragment;
	
	my $response = $self->{unpaywall_response};
	
	if (defined $response->{error} && $response->{error} eq 'no_doi')
	{
		$html->appendChild( $self->html_phrase( "no_doi" ) );
		return $html;
	}

	if (defined $response->{error} && $response->{error} eq 'invalid_doi')
	{
		$html->appendChild( $self->html_phrase( "invalid_doi", 
			doi => $session->make_text( $response->{invalid_doi} ) 
		) );
		return $html;
	}

	if (200 != $response->code && 404 != $response->code)
	{
		$html->appendChild( $self->html_phrase( "unable_to_reach_unpaywall" ) );
	}
	else
	{
		my $content = $response->content;
		my $json_vars = JSON::decode_json($content);
		my $best_oa_location = $json_vars->{best_oa_location};
		my $oa_status = $json_vars->{oa_status};
		
		if (defined $json_vars->{error} && $json_vars->{error} eq "true" )
		{
			$html->appendChild( $self->html_phrase( "unpaywall_error",
			  message => $session->make_text( $json_vars->{message} ) 
			) );
		}
		else
		{
			if (defined $best_oa_location)
			{
				my $article_version = $best_oa_location->{version};
				my $license = $best_oa_location->{license};
				my $url = $best_oa_location->{url};
				
				my $host_type = $best_oa_location->{host_type};
				
				my $version_phrase = $self->html_phrase( $article_version );
				my $host_type_phrase = $self->html_phrase( $host_type );
				
				my $url_link = $session->make_element( "a", 
					href => $url,
				);
				$url_link->appendChild( $session->make_text( $url ) );
				
				if ($host_type eq 'publisher')
				{
					# bronze OA (free instead of OA version) requires special phrasing
					if ($oa_status eq 'bronze')
					{
						$html->appendChild( $self->html_phrase( "oa_publisher_bronze",
							url => $url_link,
							version => $version_phrase,
						) );
					}
					else
					{
						$html->appendChild( $self->html_phrase( "oa_publisher",
							url => $url_link,
							version => $version_phrase,
						) );
					}
				}
				else
				{
					$html->appendChild( $self->html_phrase( "oa_repository",
						url => $url_link,
						version => $version_phrase,
						host_type => $host_type_phrase, 
					) );
				}
				
				if ($article_version eq 'submittedVersion')
				{
					$html->appendChild( $session->make_text( " " ) );
					$html->appendChild( $self->html_phrase( "no_submitted_version" ) );
				}
				
				if (defined $license && $license ne '')
				{
					$html->appendChild( $session->make_text( " " ) );
					if ( $session->get_lang->has_phrase( 
						$self->html_phrase_id( "license_" . $license  ) 
					) )
					{
						$html->appendChild( $self->html_phrase( "oa_license",
							license => $self->html_phrase( "license_" . $license ),
						) );
					}
					else
					{
						$html->appendChild( $self->html_phrase( "oa_license",
							license => $self->html_phrase( "license_publisher" ),
						) );
					}
				}
				
				my $download_button_div = $session->make_element( "div",
					style => "text-align:right;",
				);
				my $download_a;
				
				if (defined $best_oa_location->{url_for_pdf})
				{
					$download_a =  $session->make_element( "a", 
						href => $best_oa_location->{url_for_pdf},
						class => "ep_container_button btn btn-uzh-prime",
					);
					$download_a->appendChild( $self->html_phrase( "download") );
				}
				else
				{
					$download_a =  $session->make_element( "a", 
						href => $url,
						class => "ep_container_button btn btn-uzh-prime",
						target => "_blank",
					);
					$download_a->appendChild( $self->html_phrase( "get_pdf" ) );
				}
				
				$download_button_div->appendChild( $download_a );
				$html->appendChild( $download_button_div );
			}
			else
			{
				$html->appendChild( $self->html_phrase( "not_oa" ) );
			}
		}
	}
	return $html;
}


sub get_unpaywall_response
{
	my ($self) = @_;
	
	my $response = {};
	my $session = $self->{session};
	my $item = $self->{workflow}->{item};
	
	my $doi_field = $session->get_repository->get_conf( "unpaywallapi", "doifield" );
	$doi_field = "id_number" unless defined ( $doi_field );
	
	my $doi = $item->get_value( $doi_field );
	
	if (!defined $doi)
	{
		$response->{error} = 'no_doi';
		$self->{unpaywall_response} = $response;
		return $response;
	}
	
	if (defined $doi && $doi !~ /^10\./ )
	{
		$response->{error} = 'invalid_doi';
		$response->{invalid_doi} = $doi;
		$self->{unpaywall_response} = $response;
		return $response;
	}
	
	my $unpaywall_api_url = $session->get_repository->get_conf( "unpaywallapi", "uri" );
	my $unpaywall_api_email = $session->get_repository->get_conf( "unpaywallapi", "email" );
	my $proxy = $self->{session}->get_repository->config( "unpaywallapi", "proxy" );
	$unpaywall_api_url .= "/" . $doi . "?email=" . $unpaywall_api_email;
	
	my $req = HTTP::Request->new( "GET", $unpaywall_api_url );
	$req->header( "accept" => "application/json" );

	my $ua = LWP::UserAgent->new( 
		ssl_opts => { verify_hostname => 1 }, 
		protocols_allowed => ['http', 'https'],
	);
	
	if ( defined $proxy )
	{
		$ua->proxy( [ 'http' ], $proxy );
	}
	else
	{
		$ua->env_proxy;
	}
		
	$response = $ua->request($req);
	$self->{unpaywall_response} = $response;
	
	return $response;
}


sub parse_config
{
	my( $self, $config_dom ) = @_;
	
	return 0;
}

1;

=head1 AUTHOR

Martin Brändle, Zentrale Informatik, University of Zurich

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2020- University of Zurich.

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of ZORA based on EPrints L<http://www.eprints.org/>.

EPrints is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

EPrints is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints.  If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END
