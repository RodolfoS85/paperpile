package Paperpile::Controller::Ajax::Tree::Private;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Paperpile::Library::Publication;
use Data::Dumper;
use 5.010;

sub get_default_tree : Private {

  my ( $self, $c ) = @_;

  #### Root

  my $root = Tree::Simple->new( {
      text => 'Root',
      hidden => 0,
    },
    Tree::Simple->ROOT
  );

  $root->setUID('ROOT');

  #### / Local Library

  my $local_lib = Tree::Simple->new( {
      text    => 'Local library',
      type    => 'DB',
      query   => '',
      cls     => 'pp-tree-heading',
      iconCls => 'pp-icon-empty',
      hidden  => 0,
    },
    $root
  );

  $local_lib->setUID('LOCAL_ROOT');

  #### / Local Library / Tags

  my $tags = Tree::Simple->new( {
      text => 'Tags',
      type => "TAGS",
      iconCls => 'pp-icon-empty',
      hidden  => 0,
    },
    $local_lib
  );
  $tags->setUID('TAGS_ROOT');

  # Initialize
  $self->_get_tags( $c, $tags );

  #### / Local Library / Folders

  my $folders = Tree::Simple->new( {
      text    => 'Folders',
      type    => "FOLDER",
      path    => '/',
      iconCls => 'pp-icon-empty',
      hidden  => 0,
    },
    $local_lib
  );

  $folders->setUID('FOLDER_ROOT');

  #### / Active Folders

  my $active = Tree::Simple->new( {
      text => 'Active Folders',
      type => "ACTIVE",
      path => '/',
      iconCls => 'pp-icon-empty',
      cls     => 'pp-tree-heading',
      hidden  => 0,
    }
  );
  $active->setUID('ACTIVE_ROOT');

  $root->addChild($active);

  $active->addChild(
    Tree::Simple->new( {
        type         => 'ACTIVE',
        text         => 'My papers',
        plugin_title => 'My papers',
        plugin_name  => 'DB',
        plugin_mode  => 'FULLTEXT',
        plugin_query => 'washietl',
        iconCls      => 'pp-icon-folder',
        hidden       => 0,
      }
    )
  );

  ##### / Plugins

  my $plugins = Tree::Simple->new( {
      text    => 'Online Databases',
      type    => 'IMPORT_PLUGIN',
      cls     => 'pp-tree-heading',
      iconCls => 'pp-icon-empty',
      hidden  => 0,
    },
    $root
  );

  $plugins->setUID('IMPORT_PLUGIN_ROOT');

  $plugins->addChild(
    Tree::Simple->new( {
        type         => 'IMPORT_PLUGIN',
        plugin_name  => 'PubMed',
        text         => 'PubMed',
        plugin_query => '',
        iconCls      => 'pp-icon-pubmed',
        hidden       => 0,
      }
    )
  );

  $plugins->addChild(
    Tree::Simple->new( {
        type         => 'IMPORT_PLUGIN',
        plugin_name  => 'GoogleScholar',
        text         => 'Google Scholar',
        plugin_query => '',
        iconCls      => 'pp-icon-google',
        hidden       => 0,
      }
    )
  );

  ##### / Settings

  my $admin = Tree::Simple->new( {
      text    => 'Debug',
      cls     => 'pp-tree-heading',
      iconCls => 'pp-icon-empty',
      hidden  => 0,
    },
    $root
  );

  $admin->addChild(
    Tree::Simple->new( {
        text    => 'Reset Database',
        type    => 'RESET_DB',
        iconCls => 'pp-icon-tools',
        hidden  => 0,
      }
    )
  );

  $admin->addChild(
    Tree::Simple->new( {
        text    => 'Settings',
        type    => 'SETTINGS',
        iconCls => 'pp-icon-tools',
        hidden  => 0,
      }
    )
  );

  return $root;
}


sub get_js_object : Private {

  my ( $self, $c, $node, $checked ) = @_;

  my @output = ();

  foreach my $child ( $node->getAllChildren ) {

    # make deep copy to avoid touching the tree structure which gave
    # unexpected results...
    my $h = { %{ $child->getNodeValue() } };

    # we store node ids explicitely as "UID"s in backend and as
    # "node.id" in frontend
    $h->{id} = $child->getUID;

    # draw a checkbox for configuration mode
    if ($checked) {
      if ( $h->{hidden} ) {
        $h->{checked} = \0;
        $h->{hidden}  = 0;    # During configuration we have to show all nodes
      } else {
        $h->{checked} = \1;
      }
    }

    if ( $h->{hidden} ) {
      $h->{hidden} = \1;
    } else {
      $h->{hidden} = \0;
    }

    if ( $child->isLeaf() ) {
      $h->{expanded} = \1;
      $h->{children}=[];
    }

    push @output, $h;
  }

  return [@output];

}

sub get_subtree : Private {

  my ( $self, $c, $tree, $UID ) = @_;

  my $subtree = undef;

  # return the whole tree if it has the given UID
  # (only in case of 'root')
  if ( $tree->getUID eq $UID ) {
    return $tree;
  }
  # Search the tree recursively otherwise
  else {
    $tree->traverse(
      sub {
        my ($_tree) = @_;
        $subtree = $_tree if $_tree->getUID eq $UID;
      }
    )
  }

  if ($subtree->getUID eq 'tags'){
    $self->_get_tags($c,$subtree);
  }

  if ($subtree->getUID eq 'folders'){
    $self->_get_folders($c,$subtree);
  }

  return $subtree;

}

sub _get_tags {

  my ( $self, $c, $tree ) = @_;

  my @tags = @{ $c->model('User')->get_tags };

  # Remove all children (old tags) first

  foreach my $child ( $tree->getAllChildren ) {
    $tree->removeChild($child);
  }

  if ( not @tags ) {
    push @tags, 'No tags';
  }

  # Add tags
  foreach my $tag (@tags) {
    $tree->addChild(
      Tree::Simple->new( {
          text              => $tag,
          type              => 'TAG',
          hidden            => 0,
          iconCls           => 'pp-icon-tag',
          plugin_name       => 'DB',
          plugin_mode       => 'FULLTEXT',
          plugin_query      => "tags: $tag",
          plugin_base_query => "tags: $tag",
          plugin_title      => $tag,
          plugin_iconCls    => 'pp-icon-tag',
        }
      )
    );
  }
}




1;
