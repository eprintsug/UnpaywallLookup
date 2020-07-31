###############################################################################
#
#  Unpaywall API Configuration. See https://unpaywall.org/api/v2
#
###############################################################################
$c->{unpaywallapi} = {};

#
# The base URL of the unpaywall API 
#
$c->{unpaywallapi}->{uri} = URI->new( 'https://api.unpaywall.org/v2' );
#
# The e-mail address of the requester
#
$c->{unpaywallapi}->{email} = '{insert a e-mail-address here}';
#
# Proxy for getting out to Unpaywall
#
# $c->{unpaywallapi}->{proxy} = '(insert a proxy server here, if needed}';
#
# DOI field to be used
#
$c->{unpaywallapi}->{doifield} = 'id_number';
