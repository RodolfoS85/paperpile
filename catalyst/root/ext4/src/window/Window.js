/**
 * @class Ext.window.Window
 * @extends Ext.panel.Panel
 * <p>A specialized panel intended for use as an application window.  Windows are floated, {@link #resizable}, and
 * {@link #draggable} by default.  Windows can be {@link #maximizable maximized} to fill the viewport,
 * restored to their prior size, and can be {@link #minimize}d.</p>
 * <p>Windows can also be linked to a {@link Ext.ZIndexManager} or managed by the {@link Ext.WindowMgr} to provide
 * grouping, activation, to front, to back and other application-specific behavior.</p>
 * <p>By default, Windows will be rendered to document.body. To {@link #constrain} a Window to another element
 * specify {@link Ext.Component#renderTo renderTo}.</p>
 * @constructor
 * @param {Object} config The config object
 * @xtype window
 */
Ext.define('Ext.window.Window', {
    extend: 'Ext.panel.Panel',

    alternateClassName: 'Ext.Window',

    requires: ['Ext.util.ComponentDragger', 'Ext.util.Region', 'Ext.EventManager'],

    alias: 'widget.window',

    /**
     * @cfg {Number} x
     * The X position of the left edge of the window on initial showing. Defaults to centering the Window within
     * the width of the Window's container {@link Ext.core.Element Element) (The Element that the Window is rendered to).
     */
    /**
     * @cfg {Number} y
     * The Y position of the top edge of the window on initial showing. Defaults to centering the Window within
     * the height of the Window's container {@link Ext.core.Element Element) (The Element that the Window is rendered to).
     */
    /**
     * @cfg {Boolean} modal
     * True to make the window modal and mask everything behind it when displayed, false to display it without
     * restricting access to other UI elements (defaults to false).
     */
    /**
     * @cfg {String/Element} animateTarget
     * Id or element from which the window should animate while opening (defaults to null with no animation).
     */
    /**
     * @cfg {String/Number/Component} defaultFocus
     * <p>Specifies a Component to receive focus when this Window is focused.</p>
     * <p>This may be one of:</p><div class="mdetail-params"><ul>
     * <li>The index of a footer Button.</li>
     * <li>The id or {@link Ext.AbstractComponent#itemId} of a descendant Component.</li>
     * <li>A Component.</li>
     * </ul></div>
     */
    /**
     * @cfg {Function} onEsc
     * Allows override of the built-in processing for the escape key. Default action
     * is to close the Window (performing whatever action is specified in {@link #closeAction}.
     * To prevent the Window closing when the escape key is pressed, specify this as
     * Ext.emptyFn (See {@link Ext#emptyFn Ext.emptyFn}).
     */
    /**
     * @cfg {Boolean} collapsed
     * True to render the window collapsed, false to render it expanded (defaults to false). Note that if
     * {@link #expandOnShow} is true (the default) it will override the <code>collapsed</code> config and the window
     * will always be expanded when shown.
     */
    /**
     * @cfg {Boolean} maximized
     * True to initially display the window in a maximized state. (Defaults to false).
     */

    /**
    * @cfg {String} baseCls
    * The base CSS class to apply to this panel's element (defaults to 'x-window').
    */
    baseCls: Ext.baseCSSPrefix + 'window',

    /**
     * @cfg {Mixed} resizable
     * <p>Specify as <code>true</code> to allow user resizing at each edge and corner of the window, false to disable resizing (defaults to true).</p>
     * <p>This may also be specified as a config object to </p>
     */
    resizable: true,

    /**
     * @cfg {Boolean} draggable
     * <p>True to allow the window to be dragged by the header bar, false to disable dragging (defaults to true).  Note
     * that by default the window will be centered in the viewport, so if dragging is disabled the window may need
     * to be positioned programmatically after render (e.g., myWindow.setPosition(100, 100);).<p>
     */
    draggable: true,

    /**
     * @cfg {Boolean} constrain
     * True to constrain the window within its containing element, false to allow it to fall outside of its
     * containing element. By default the window will be rendered to document.body.  To render and constrain the
     * window within another element specify {@link #renderTo}.
     * (defaults to false).  Optionally the header only can be constrained using {@link #constrainHeader}.
     */
    constrain: false,

    /**
     * @cfg {Boolean} constrainHeader
     * True to constrain the window header within its containing element (allowing the window body to fall outside
     * of its containing element) or false to allow the header to fall outside its containing element (defaults to
     * false). Optionally the entire window can be constrained using {@link #constrain}.
     */
    constrainHeader: false,

    /**
     * @cfg {Boolean} plain
     * True to render the window body with a transparent background so that it will blend into the framing
     * elements, false to add a lighter background color to visually highlight the body element and separate it
     * more distinctly from the surrounding frame (defaults to false).
     */
    plain: false,

    /**
     * @cfg {Boolean} minimizable
     * True to display the 'minimize' tool button and allow the user to minimize the window, false to hide the button
     * and disallow minimizing the window (defaults to false).  Note that this button provides no implementation --
     * the behavior of minimizing a window is implementation-specific, so the minimize event must be handled and a
     * custom minimize behavior implemented for this option to be useful.
     */
    minimizable: false,

    /**
     * @cfg {Boolean} maximizable
     * True to display the 'maximize' tool button and allow the user to maximize the window, false to hide the button
     * and disallow maximizing the window (defaults to false).  Note that when a window is maximized, the tool button
     * will automatically change to a 'restore' button with the appropriate behavior already built-in that will
     * restore the window to its previous size.
     */
    maximizable: false,

    /**
     * @cfg {Number} minHeight
     * The minimum height in pixels allowed for this window (defaults to 100).  Only applies when {@link #resizable}
     * is set.
     */
    minHeight: 100,

    /**
     * @cfg {Number} minWidth
     * The minimum width in pixels allowed for this window (defaults to 200).  Only applies when {@link #resizable}
     * is set.
     */
    minWidth: 200,

    /**
     * @cfg {Boolean} expandOnShow
     * True to always expand the window when it is displayed, false to keep it in its current state (which may be
     * {@link #collapsed}) when displayed (defaults to true).
     */
    expandOnShow: true,

    // inherited docs, same default
    collapsible: false,

    /**
     * @cfg {Boolean} closable
     * <p>True to display the 'close' tool button and allow the user to close the window, false to
     * hide the button and disallow closing the window (defaults to <code>true</code>).</p>
     * <p>By default, when close is requested by either clicking the close button in the header
     * or pressing ESC when the Window has focus, the {@link #close} method will be called. This
     * will <i>{@link Ext.Component#destroy destroy}</i> the Window and its content meaning that
     * it may not be reused.</p>
     * <p>To make closing a Window <i>hide</i> the Window so that it may be reused, set
     * {@link #closeAction} to 'hide'.</p>
     */
    closable: true,

    /**
     * @cfg {Boolean} hidden
     * Render this Window hidden (default is <code>true</code>). If <code>true</code>, the
     * {@link #hide} method will be called internally.
     */
    hidden: true,

    // Inherit docs from Component. Windows render to the body on first show.
    autoRender: true,

    // Inherit docs from Component. Windows hide using visibility.
    hideMode: 'visibility',

    /** @cfg {Boolean} floating @hide Windows are always floating*/
    floating: true,

    ariaRole: 'alertdialog',

    overlapHeader: true,
    
    // private
    initComponent: function() {
        var me = this;
        me.callParent();
        me.addEvents(
            /**
             * @event activate
             * Fires after the window has been visually activated via {@link #setActive}.
             * @param {Ext.window.Window} this
             */
            /**
             * @event deactivate
             * Fires after the window has been visually deactivated via {@link #setActive}.
             * @param {Ext.window.Window} this
             */
            /**
             * @event resize
             * Fires after the window has been resized.
             * @param {Ext.window.Window} this
             * @param {Number} width The window's new width
             * @param {Number} height The window's new height
             */
            'resize',
            /**
             * @event maximize
             * Fires after the window has been maximized.
             * @param {Ext.window.Window} this
             */
            'maximize',
            /**
             * @event minimize
             * Fires after the window has been minimized.
             * @param {Ext.window.Window} this
             */
            'minimize',
            /**
             * @event restore
             * Fires after the window has been restored to its original size after being maximized.
             * @param {Ext.window.Window} this
             */
            'restore'
        );

        // Initialize as visible.
        if (me.hidden === false) {
            me.hidden = true;
            me.show();
        }
        
        if (me.modal) {
            me.ariaRole = 'dialog';
        }
    },

    // State Management
    // private
    getState: function() {
        var state = this.callParent() || {};
        return Ext.apply(state, this.getBox(true));
    },

    // private
    onRender: function(ct, position) {
        var me = this;
        
        Ext.applyIf(me.renderData, {
            plain: me.plain ? me.baseCls + '-plain' : undefined
        });

        me.callParent(arguments);

        me.focusEl = me.el;

        // Double clicking a header will toggleMaximize
        if (me.maximizable) {
            me.mon(me.header, 'domdblclick', me.toggleMaximize, me);
        }
    },

    // private
    afterRender: function() {
        var me = this,
            keyMap;
            
        // Component's afterRender sizes and positions the Component
        me.callParent();

        // Create the proxy after the size has been applied in Component.afterRender
        me.proxy = me.getProxy();

        // clickToRaise
        me.mon(me.el, 'mousedown', me.toFront, me);

        // Initialize maximized
        if (me.maximized) {
            me.maximized = false;
            me.maximize();
        }

        if (me.closable) {
            keyMap = me.getKeyMap();
            keyMap.on(27, me.onEsc, me);
            keyMap.disable();
        }
    },

    /**
     * @private
     * @override
     * Override Component.initDraggable.
     * Window uses the header element as the delegate.
     */
    initDraggable: function() {
        var me = this,
            ddConfig;
            
        if (!me.header) {
            me.updateHeader(true);
        }
            
        ddConfig = Ext.applyIf({
            el: me.el,
            delegate: '#' + me.header.id
        }, me.draggable);

        // Add extra configs if Window is specified to be constrained
        if (me.constrain || me.constrainHeader) {
            ddConfig.constrain = me.constrain;
            ddConfig.constrainDelegate = me.constrainHeader;
            ddConfig.constrainTo = me.constrainTo || me.container;
        }

        /**
         * <p>If this Window is configured {@link #draggable}, this property will contain
         * an instance of {@link Ext.util.ComponentDragger} (A subclass of {@link Ext.dd.DragTracker DragTracker})
         * which handles dragging the Window's DOM Element, and constraining according to the {@link #constrain}
         * and {@link #constrainHeader} .</p>
         * <p>This has implementations of <code>onBeforeStart</code>, <code>onDrag</code> and <code>onEnd</code>
         * which perform the dragging action. If extra logic is needed at these points, use
         * {@link Ext.Function#createInterceptor createInterceptor} or {@link Ext.Function#createSequence createSequence} to
         * augment the existing implementations.</p>
         * @type Ext.util.ComponentDragger
         * @property dd
         */
        this.dd = new Ext.util.ComponentDragger(this, ddConfig);
    },

    // private
    onEsc: function(k, e) {
        e.stopEvent();
        this[this.closeAction]();
    },

    // private
    beforeDestroy: function() {
        var me = this;
        
        if (me.rendered) {
            me.hide();
            Ext.destroy(
                me.focusEl
            );
        }
        me.callParent();
    },

    /**
     * @private
     * @override
     * Contribute class-specific tools to the header.
     * Called by Panel's initTools.
     */
    addTools: function() {
        var me = this;
        
        // Call Panel's initTools
        me.callParent();

        if (me.minimizable) {
            me.addTool({
                type: 'minimize',
                handler: Ext.Function.bind(me.minimize, me, [])
            });
        }
        if (me.maximizable) {
            me.addTool({
                type: 'maximize',
                handler: Ext.Function.bind(me.maximize, me, [])
            });
            me.addTool({
                type: 'restore',
                handler: Ext.Function.bind(me.restore, me, []),
                hidden: true
            });
        }
    },

    /**
     * Gets the configured default focus item.  If a defaultComponent is set, it will receive focus, otherwise the
     * Container itself will receive focus.
     */
    getFocusEl: function() {
        var me = this,
            f = me.focusEl,
            defaultComp = me.defaultButton || me.defaultFocus,
            t = typeof db,
            el,
            ct;

        if (Ext.isDefined(defaultComp)) {
            if (Ext.isNumber(defaultComp)) {
                f = me.query('button')[defaultComp];
            } else if (Ext.isString(defaultComp)) {
                f = me.down('#' + defaultComp);
            } else {
                f = defaultComp;
            }
        }
        return f || me.focusEl;
    },

    // private
    beforeShow: function() {
        this.callParent();

        if (this.expandOnShow) {
            this.expand(false);
        }
    },

    // private
    afterShow: function(isAnim) {
        var me = this,
            size;
        
        if (me.isDestroyed) {
            return false;
        }
        me.proxy.hide();

        if (me.maximized) {
            me.fitContainer();
        }

        if (me.monitorResize || me.constrain || me.constrainHeader) {
            Ext.EventManager.onWindowResize(me.onWindowResize, me);
        }
        me.doConstrain();
        if (me.keyMap) {
            me.keyMap.enable();
        }

        // BrowserBug. Explain the browser bug in the comment.
        if (isAnim && (Ext.isIE || Ext.isWebKit)) {
            size = me.getSize();
            me.onResize(size.width, size.height);
        }

        // Call superclass's afterShow
        me.callParent();
    },

    // private
    doClose: function() {
        var me = this;
        
        // immediate close
        if (me.hidden) {
            me.fireEvent('close', me);
            me[me.closeAction]();
        } else {
            // close after hiding
            me.hide(me.animTarget, me.doClose, me);
        }
    },

    /**
     * Hides the window, setting it to invisible and applying negative offsets.
     * @param {String/Element} animateTarget (optional) The target element or id to which the window should
     * animate while hiding (defaults to null with no animation)
     * @param {Function} callback (optional) A callback function to call after the window is hidden
     * @param {Object} scope (optional) The scope (<code>this</code> reference) in which the callback is executed. Defaults to this Window.
     * @return {Ext.window.Window} this
     */
    hide: function(animateTarget, cb, scope) {
        var me = this;
        
        if (me.hidden || me.fireEvent('beforehide', me) === false) {
            return me;
        }
        if (cb) {
            me.on('hide', cb, scope, {
                single: true
            });
        }
        me.hidden = true;
        if (me.animateTarget) {
            me.animHide();
        } else {
            me.el.hide();
            me.afterHide();
        }
        return me;
    },

    // private
    afterHide: function() {
        var me = this;
        
        me.proxy.hide();

        // No longer subscribe to resizing now that we're hidden
        if (me.monitorResize || me.constrain || me.constrainHeader) {
            Ext.EventManager.removeResizeListener(me.onWindowResize, me);
        }

        // Turn off keyboard handling once window is hidden
        if (me.keyMap) {
            me.keyMap.disable();
        }

        me.onHide();
        me.fireEvent('hide', me);
    },

    // private
    onWindowResize: function() {
        if (this.maximized) {
            this.fitContainer();
        }
        this.doConstrain();
    },

    /**
     * Placeholder method for minimizing the window.  By default, this method simply fires the {@link #minimize} event
     * since the behavior of minimizing a window is application-specific.  To implement custom minimize behavior,
     * either the minimize event can be handled or this method can be overridden.
     * @return {Ext.window.Window} this
     */
    minimize: function() {
        this.fireEvent('minimize', this);
        return this;
    },

    afterCollapse: function() {
        var me = this;
        
        if (me.maximizable) {
            me.tools.maximize.hide();
            me.tools.restore.hide();
        }
        if (me.resizer) {
            me.resizer.disable();
        }
        me.callParent(arguments);
    },

    afterExpand: function() {
        var me = this;

        if (me.maximized) {
            me.tools.restore.show();
        } else if (me.maximizable) {
            me.tools.maximize.show();
        }
        if (me.resizer) {
            me.resizer.enable();
        }
        me.callParent(arguments);
    },

    /**
     * Fits the window within its current container and automatically replaces
     * the {@link #maximizable 'maximize' tool button} with the 'restore' tool button.
     * Also see {@link #toggleMaximize}.
     * @return {Ext.window.Window} this
     */
    maximize: function() {
        var me = this;
        
        if (!me.maximized) {
            me.expand(false);
            me.restoreSize = me.getSize();
            me.restorePos = me.getPosition(true);
            if (me.maximizable) {
                me.tools.maximize.hide();
                me.tools.restore.show();
            }
            me.maximized = true;
            me.el.disableShadow();

            if (me.dd) {
                me.dd.disable();
            }
            if (me.collapseTool) {
                me.collapseTool.hide();
            }
            me.el.addCls(Ext.baseCSSPrefix + 'window-maximized');
            me.container.addCls(Ext.baseCSSPrefix + 'window-maximized-ct');

            me.setPosition(0, 0);
            me.fitContainer();
            me.fireEvent('maximize', me);
        }
        return me;
    },

    /**
     * Restores a {@link #maximizable maximized}  window back to its original
     * size and position prior to being maximized and also replaces
     * the 'restore' tool button with the 'maximize' tool button.
     * Also see {@link #toggleMaximize}.
     * @return {Ext.window.Window} this
     */
    restore: function() {
        var me = this,
            tools = me.tools;
            
        if (me.maximized) {
            me.removeCls(Ext.baseCSSPrefix + 'window-maximized');

            // Toggle tool visibility
            if (tools.restore) {
                tools.restore.hide();
            }
            if (tools.maximize) {
                tools.maximize.show();
            }
            if (me.collapseTool) {
                me.collapseTool.show();
            }

            // Restore the position/sizing
            me.setPosition(me.restorePos);
            me.setSize(me.restoreSize);

            // Unset old position/sizing
            delete me.restorePos;
            delete me.restoreSize;

            me.maximized = false;

            me.el.enableShadow(true);

            // Allow users to drag and drop again
            if (me.dd) {
                me.dd.enable();
            }

            me.container.removeCls(Ext.baseCSSPrefix + 'window-maximized-ct');

            me.doConstrain();
            me.fireEvent('restore', me);
        }
        return me;
    },

    /**
     * A shortcut method for toggling between {@link #maximize} and {@link #restore} based on the current maximized
     * state of the window.
     * @return {Ext.window.Window} this
     */
    toggleMaximize: function() {
        return this[this.maximized ? 'restore': 'maximize']();
    }

    /**
     * @cfg {Boolean} autoWidth @hide
     * Absolute positioned element and therefore cannot support autoWidth.
     * A width is a required configuration.
     **/
});
