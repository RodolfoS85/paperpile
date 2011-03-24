/* Copyright 2009-2011 Paperpile

   This file is part of Paperpile

   Paperpile is free software: you can redistribute it and/or modify it
   under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation, either version 3 of the
   License, or (at your option) any later version.

   Paperpile is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Affero General Public License for more details.  You should have
   received a copy of the GNU Affero General Public License along with
   Paperpile.  If not, see http://www.gnu.org/licenses. */

Ext.define('Paperpile.pub.View', {
  extend: 'Ext.Panel',
  alias: 'widget.pubview',
  initComponent: function() {
    Ext.apply(this, {
      sidebarUpdateDelay: 100,
      layout: 'border',
      items: [this.createCenter(), this.createEast()],
    });
    this.callParent(arguments);

    Ext.getStore('labels').on('load', this.refresh, this);
    Ext.getStore('folders').on('load', this.refresh, this);

  },

  createCenter: function() {
    var params = this.gridParams || {};
    var me = this;
    Ext.apply(params, {
      region: 'center',
      flex: 2,
      listeners: {
        scope: this,
        afterselectionchange: me.onSelect
      }
    });
    this.grid = Ext.create(this.getGridType(), params);

    this.abstract = Ext.createByAlias('widget.pubabstract', {});
    this.south = Ext.create('Ext.panel.Panel', {
      region: 'south',
      flex: 1,
      layout: 'fit',
      split: true,
      border: false,
      items: [this.abstract]
    });

    this.center = Ext.create('Ext.panel.Panel', {
      layout: 'border',
      region: 'center',
      flex: 2,
      split: true,
      border: false,
      items: [this.grid, this.south]
    });
    return this.center;
  },

  getGrid: function() {
    return this.grid;
  },

  createEast: function() {
    this.overview = Ext.createByAlias('widget.puboverview', {});

    this.east = Ext.create('Ext.panel.Panel', {
      region: 'east',
      layout: 'fit',
      flex: 1,
      split: true,
      border: false,
      items: [this.overview]
    });
    return this.east;
  },

  createSouth: function() {
    return this.south;
  },

  getGridType: function() {
    return "Paperpile.pub.Grid";
  },

  onRender: function() {
    this.callParent(arguments);
  },

  handleHideSouth: function() {},

  onSelect: function(sm, selections) {
    if (this.updateSelectionTask === undefined) {
      this.updateSelectionTask = new Ext.util.DelayedTask();
    }
    this.updateSelectionTask.delay(this.sidebarUpdateDelay, this.doUpdateSelection, this, [sm, selections]);
  },

  refresh: function() {
	    if (!this.selection) {
		return;
	    }	    
    this.grid.view.refresh();
    var panels = [this.abstract, this.overview];
    Ext.each(panels, function(panel) {
      panel.setSelection(this.selection);
    },
    this);
  },

  doUpdateSelection: function(sm, selection) {
    var panels = [this.abstract, this.overview];
    var grid_id = this.grid.id;
    Ext.each(panels, function(panel) {
      panel.grid_id = grid_id;
    });

    this.selection = selection;
    Ext.each(panels, function(panel) {
      panel.setSelection(selection);
    });
  },

  updateFromServer: function(data) {
    this.grid.updateFromServer(data);

    var panels = [this.abstract, this.overview];
    Ext.each(panels, function(panel) {
      if (panel['updateFromServer']) {
        panel.updateFromServer(data);
      } else {
        Paperpile.log("Panel " + panel.id + " cannot update from server!");
      }
    });

  }
});