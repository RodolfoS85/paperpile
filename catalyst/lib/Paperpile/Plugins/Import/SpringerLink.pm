package Paperpile::Plugins::Import::SpringerLink;

use Carp;
use Data::Dumper;
use Moose;
use Moose::Util::TypeConstraints;
use XML::Simple;
use HTML::TreeBuilder::XPath;
use 5.010;

use Paperpile::Library::Publication;
use Paperpile::Library::Author;
use Paperpile::Library::Journal;
use Paperpile::Utils;

extends 'Paperpile::Plugins::Import';

# The search query to be send to SpringerLink Portal
has 'query' => ( is => 'rw' );


my $searchUrl = 'http://springerlink.com/content/?hl=u&k=';


sub BUILD {
  my $self = shift;
  $self->plugin_name('SpringerLink');
}

sub connect {
  my $self = shift;

  
  my $browser = Paperpile::Utils->get_browser;

  # Get the results
  (my $tmp_query = $self->query) =~ s/\s+/+/g;
  my $response = $browser->get( $searchUrl . $tmp_query );
  
  my $content  = $response->content;

  # save first page in cache to speed up call to first page afterwards
  $self->_page_cache( {} );
  $self->_page_cache->{0}->{ $self->limit } = $content;

  # Nothing found
  if ( $content =~ /No results returned for your criteria./ ) {
    $self->total_entries(0);
    return 0;
  }

  # Try to find the number of hits
  # Maybe that could be done faster with XPath, one has to rethink
  if ( $content =~ m/<td>([1234567890,]+)\sResults<\/td>/ ) {
    my $number = $1;
    $number =~ s/,//;
    $self->total_entries($number);
  } else {
    die('Something is wrong with the results page.');
  }

  # Return the number of hits
  return $self->total_entries;
}

sub page {
  ( my $self, my $offset, my $limit ) = @_;

  # Get the content of the page, either via cache for the first page
  # which has been retrieved in the connect function or send new query
  my $content = '';
  if ( $self->_page_cache->{$offset}->{$limit} ) {
      $content = $self->_page_cache->{$offset}->{$limit};
  } else {
      my $browser = Paperpile::Utils->get_browser;
      my $nr = $offset+1;
      (my $tmp_query = $self->query) =~ s/\s+/+/g;
      my $response = $browser->get( $searchUrl . $tmp_query . '&start=' . $nr );
      $content = $response->content;
  }
  
  # now we parse the HTML for entries
  my $tree = HTML::TreeBuilder::XPath->new;
  $tree->utf8_mode(1);
  $tree->parse_content($content);

  my %data = (
    authors   => [],
    titles    => [],
    citations => [],
    urls      => [],
    bibtex    => [],
    pdf       => []  
  );

  # Each entry is part of an unorder list 
  my @nodes = $tree->findnodes('/html/body/*/*/*/*/*/*/*/*/*/*/*/*/*/div[@class="primitiveControl"]');
  
  foreach my $node (@nodes) {
      
      # Title 
      my ( $title, $author, $citation, $pdf, $url );
      $title = $node->findvalue('./div[@class="listItemName"]/a');

      # authors
      my @author_nodes = $node->findnodes('./div[@class="listAuthors"]');
      $author = $author_nodes[0]->as_text();

      # citation
      my @citation_nodes = $node->findnodes('./div[@class="listParents"]');
      $citation = $citation_nodes[0]->as_text();

      # PDF link
      $pdf = $node->findvalue('./table/tr/td/a/@href');
      $pdf = 'http://springerlink.com' . $pdf;
      $pdf =~ s/pdf\/content.*html$/pdf/;

      # URL linkout
      $url = $node->findvalue('./div[@class="listItemName"]/a/@href');
      $url = 'http://springerlink.com' . $url;

      push @{ $data{titles} }, $title;
      push @{ $data{authors} }, $author;
      push @{ $data{citations} }, $citation;
      push @{ $data{pdf} }, $pdf;
      push @{ $data{urls} }, $url;
  }


  # Write output list of Publication records with preliminary
  # information. We save to the helper fields _authors_display and
  # _citation_display which will be displayed in the front end.
  my $page = [];

  foreach my $i ( 0 .. @{ $data{titles} } - 1 ) {
    my $pub = Paperpile::Library::Publication->new();
    $pub->title( $data{titles}->[$i] );
    $pub->_authors_display( $data{authors}->[$i] );
    $pub->_citation_display( $data{citations}->[$i] );
    $pub->linkout( $data{urls}->[$i] );
    $pub->pdf_url( $data{pdf}->[$i] );
    $pub->_details_link( $data{urls}->[$i] );
    $pub->refresh_fields;
    push @$page, $pub;
  }

  # we should always call this function to make the results available
  # afterwards via find_sha1
  $self->_save_page_to_hash($page);

  return $page;

}

# We parse ACM Portal in a two step process. First we scrape off what
# we see and display it unchanged in the front end via
# _authors_display and _citation_display. If the user clicks on an
# entry the missing information is completed from the details page
# where we find the abstract and a BibTeX link. This ensures fast
# search results and avoids too many requests to ACM which is
# potentially harmful.

sub complete_details {

  ( my $self, my $pub ) = @_;

  my $browser = Paperpile::Utils->get_browser;
  
  # Get the HTML page. I have tried to use the RIS export, but that
  # did not work. There seems to be a protection, can only be
  # used in the borwser.
  my $response = $browser->get( $pub->_details_link );
  my $content = $response->content;

  # now we parse the HTML for entries
  my $tree = HTML::TreeBuilder::XPath->new;
  $tree->utf8_mode(1);
  $tree->parse_content($content);

  # let's find the abstract first
  my $abstract = $tree->findvalue('/*/*/*/*/*/*/*/*/*/*/*/*/*/div[@class="Abstract"]');

  # Now we complete the other details
  my @ids = $tree->findnodes('/*/*/*/*/*/*/*/*/*/div[@class="primitiveControl"]/table/tr/td/table/tr/td[@class="labelName"');
  my @values = $tree->findnodes('/*/*/*/*/*/*/*/*/*/div[@class="primitiveControl"]/table/tr/td/table/tr/td[@class="labelValue"');

  # We first build a nice hash, than we can see what stuff we have got
  my %details = ( );
  foreach my $i (0 .. $#ids) {
      # It might happen that there is the same identifier more than once
      if (defined $details{ $ids[$i]->as_text() }) {
	  $details{ $ids[$i]->as_text() } .= "%%BREAK%%".$values[$i]->as_text();
      } else {
	  $details{ $ids[$i]->as_text() } = $values[$i]->as_text();
      }
  }

  (my $journal, my $doi, my $volume, my $issue, my $pages, my $year);
  
  $pages = $details{'Pages'} if ($details{'Pages'});
  
  # let's see if there is a journal entry, otherwise it will be
  # a book chapter
  if ($details{'Journal'}) {
      $journal = $details{'Journal'};
  }


 
  # Create a new Publication object
  my $full_pub = Paperpile::Library::Publication->new();

  # Add new values 
  $pub->pages($pages)       if ($pages);
  $pub->journal($journal)   if ($journal);

  # Add values from the old object
  $full_pub->title( $pub->title );
  $full_pub->authors( $pub->_authors_display );
  $full_pub->abstract( $abstract );
  $full_pub->linkout( $pub->linkout );
  $full_pub->pdf_url( $pub->pdf_url );

  # Note that if we change title, authors, and citation also the sha1
  # will change. We have to take care of this.
  my $old_sha1 = $pub->sha1;
  my $new_sha1 = $full_pub->sha1;
  delete( $self->_hash->{$old_sha1} );
  $self->_hash->{$new_sha1} = $full_pub;

  return $full_pub;

}

1;
