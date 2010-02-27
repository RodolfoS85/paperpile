/* Copyright 2009, 2010 Paperpile

   This file is part of Paperpile

   Paperpile is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   Paperpile is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.  You should have received a
   copy of the GNU General Public License along with Paperpile.  If
   not, see http://www.gnu.org/licenses. */


Paperpile.PluginPanelDuplicates = Ext.extend(Paperpile.PluginPanel, {

  initComponent: function() {
    Ext.apply(this, {
      title: this.title,
      iconCls: 'pp-icon-duplicates'
    });
    Paperpile.PluginPanelDuplicates.superclass.initComponent.call(this);
  },

  createGrid: function(gridParams) {
    return new Paperpile.PluginGridDuplicates(gridParams);
  }

});

Paperpile.PluginGridDuplicates = Ext.extend(Paperpile.PluginGridDB, {
  plugin_iconCls: 'pp-icon-duplicates',
  plugin_name: 'Duplicates',
  limit: 25,
  plugin_base_query: '',

  emptyMsg: [
    '<div class="pp-box pp-box-side-panel pp-box-style1 pp-box-welcome"',
    '<h2>Duplicate Search</h2>',
    '<p>Your library was searched and no duplicate references were found.<p>',
    '</div>'],

  initComponent: function() {
    // Need to set these store handlers before calling the superclass.initcomponent,
    // otherwise the store will have already started loading when these are added.
    this.getStore().on('beforeload',
      function() {
        Paperpile.status.showBusy('Searching duplicates');
      },
      this);
    this.getStore().on('load',
      function() {
        Paperpile.status.clearMsg();
        if (this.store.getCount() == 0) {
          this.getPluginPanel().onEmpty(this.emptyMsg);
        }
      },
      this);

    Paperpile.PluginGridDuplicates.superclass.initComponent.call(this);

    this.on('render', this.myOnRender, this);
  },

  createToolbarMenu: function() {
    Paperpile.PluginGridDuplicates.superclass.createToolbarMenu.call(this);

    this.actions['CLEAN_ALL_DUPLICATES'] = new Ext.Action({
      text: 'Clean all duplicates',
      handler: this.cleanDuplicates,
      scope: this,
      iconCls: 'pp-icon-clean',
      itemId: 'remove_duplicates',
      tooltip: 'Automatically clean all duplicates'
    });

    var tbar = this.getTopToolbar();

    // Hide the add button.
    this.getToolbarByItemId(this.actions['NEW'].itemId).setVisible(false);

    var filterFieldIndex = this.getButtonIndex(this.actions['SEARCH_TB_FILL'].itemId);
    // We might eventually have this working, but for now it's unimplemented
    // in the backend so leave it out of the toolbar.
    //tbar.insertButton(filterFieldIndex + 1, this.actions['CLEAN_ALL_DUPLICATES']);
    tbar.insertButton(filterFieldIndex + 1, this.actions['DELETE']);
  },

  updateToolbarItem: function(item) {
    Paperpile.PluginGridDuplicates.superclass.updateToolbarItem.call(this, item);

    if (item.itemId == this.actions['DELETE'].itemId) {
      item.setIconClass('pp-icon-trash');
      item.setText('Move to Trash');
      var selected = this.getSelection().length;
      (selected > 0 ? item.enable() : item.disable());
    }
  },

  myOnRender: function() {
    this.store.load({
      params: {
        start: 0,
        limit: this.limit,
        // Cause the duplicate cache to be cleared each time the grid is reloaded.
        // This is very slow, and will need backend optimization in Duplicates.pm.
        plugin_clear_duplicate_cache: true
      }
    });

    this.store.on('load', function() {
      this.getSelectionModel().selectFirstRow();
    },
    this, {
      single: true
    });
  },

  cleanDuplicates: function() {
    Ext.Ajax.request({
      url: Paperpile.Url('/ajax/misc/clean_duplicates'),
      params: {
        grid_id: this.id
      },
      method: 'GET',
      success: function(response) {
        var json = Ext.util.JSON.decode(response.responseText);
      },
      failure: Paperpile.main.onError,
      scope: this
    });
  }
});