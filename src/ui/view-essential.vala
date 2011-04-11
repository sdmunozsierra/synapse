/*
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
 * Copyright (C) 2010 Alberto Aldegheri <albyrock87+dev@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by Alberto Aldegheri <albyrock87+dev@gmail.com>
 *
 */

using Gee;
using Gtk;
using Cairo;

namespace Synapse.Gui
{
  public class ViewEssential : Synapse.Gui.View
  {
    construct {
      
    }
    
    static construct
    {
      var width = new GLib.ParamSpecInt ("ui-width",
                                         "Width",
                                         "The width of the content for Essential theme",
                                         0, 1024, 500,
                                         GLib.ParamFlags.READABLE);
      
      install_style_property (width);
    }
    
    public override void style_set (Gtk.Style? old)
    {
      base.style_set (old);

      int width;
      this.style.get (typeof(Synapse.Gui.ViewEssential), "ui-width", out width);
      
      container.set_size_request (width, -1);
      spacer.set_size_request (1, SHADOW_SIZE + BORDER_RADIUS);
    }
    
    private NamedIcon source_icon;
    private NamedIcon action_icon;
    private NamedIcon target_icon;
    
    private SmartLabel focus_label;
    private SmartLabel description_label;
    
    private SchemaContainer icon_container;
    
    private Label spacer;
    
    private VBox container;
    
    private SelectionContainer results_container;
    
    private ResultBox results_sources;
    private ResultBox results_actions;
    private ResultBox results_targets;
    
    protected override void build_ui ()
    {
      container = new VBox (false, 0);
      /* Icons */
      source_icon = new NamedIcon ();
      action_icon = new NamedIcon ();
      target_icon = new NamedIcon ();
      source_icon.set_icon_name ("search", IconSize.DND);
      
      icon_container = new SchemaContainer (80, 80);
      icon_container.add (source_icon);
      icon_container.add (action_icon);
      icon_container.add (target_icon);
      var schema = new SchemaContainer.Schema ();
      schema.add_allocation ({ 0, 0, 100, 100 });
      schema.add_allocation ({ 60, 60, 40, 40 });
      icon_container.add_schema (schema);
      schema = new SchemaContainer.Schema ();
      schema.add_allocation ({ 0, 0, 40, 40 });
      schema.add_allocation ({ 20, 20, 80, 80 });
      icon_container.add_schema (schema);
      
      icon_container.show ();
      /* Labels */
      focus_label = new SmartLabel ();
      focus_label.set_ellipsize (Pango.EllipsizeMode.END);
      focus_label.size = SmartLabel.Size.LARGE;
      focus_label.min_size = SmartLabel.Size.MEDIUM;
      description_label = new SmartLabel ();
      description_label.size = SmartLabel.Size.SMALL;
      description_label.set_animation_enabled (true);
      
      /* Categories - Throbber and menu */ //#0C71D6
      var categories_hbox = new HBox (false, 0);

      var menuthrobber = new MenuThrobber ();
      menu = (MenuButton) menuthrobber;
      menuthrobber.set_size_request (14, 14);
      menuthrobber.button_scale = 0.75;

      spacer = new Label ("");
      spacer.set_size_request (14, 1);
      categories_hbox.pack_start (spacer, false);
      categories_hbox.pack_start (flag_selector);
      categories_hbox.pack_start (menuthrobber, false);

      var vb = new VBox (false, 0);
      vb.pack_end (description_label, false);
      vb.pack_end (focus_label, false);
      vb.pack_end (new Gtk.HSeparator (), false, true, 3);
      vb.pack_end (categories_hbox, false);

      flag_selector.selected_markup = "<span size=\"small\"><b>%s</b></span>";
      flag_selector.unselected_markup = "<span size=\"x-small\">%s</span>";
      
      /* Top Container */
      var hb = new HBox (false, 5);
      hb.pack_start (icon_container, false);
      hb.pack_start (vb, true);
      
      container.pack_start (hb, false);
      spacer = new Label (null);
      spacer.set_size_request (1, SHADOW_SIZE + BORDER_RADIUS);
      container.pack_start (spacer, false);
      
      /* list */
      results_container = new SelectionContainer ();
      container.pack_start (results_container, false);

      results_sources = new ResultBox (100);
      results_actions = new ResultBox (100);
      results_sources.get_match_list_view ().selected_index_changed.connect (controller.selected_index_changed_event);
      results_actions.get_match_list_view ().selected_index_changed.connect (controller.selected_index_changed_event);
      results_sources.get_match_list_view ().fire_item.connect (controller.fire_focus);
      results_actions.get_match_list_view ().fire_item.connect (controller.fire_focus);
      results_container.add (results_sources);
      results_container.add (results_actions);
      
      container.show_all ();
      results_container.hide ();

      container.set_size_request (500, -1);
      this.add (container);
    }
    
    public override bool is_list_visible ()
    {
      return results_container.visible;
    }
    
    public override void set_list_visible (bool visible)
    {
      results_container.visible = visible;
    }
    
    public override void update_searching_for ()
    {
      switch (model.searching_for)
      {
        case SearchingFor.SOURCES:
          icon_container.select_schema (0);
          icon_container.set_render_order ({0, 1});
          break;
        case SearchingFor.ACTIONS:
          icon_container.select_schema (1);
          icon_container.set_render_order ({1, 0});
          break;
      }
      update_labels ();
      results_container.select_child (model.searching_for);
    }
    
    public override void update_selected_category ()
    {
      flag_selector.selected = model.selected_category;
    }
    
    protected override void paint_background (Cairo.Context ctx)
    {
      bool comp = this.is_composited ();
      if (is_list_visible () || (!comp))
      {
        ctx.set_operator (Operator.SOURCE);
        ch.set_source_rgba (ctx, 1.0, ch.StyleType.BASE, Gtk.StateType.NORMAL);
        ctx.rectangle (spacer.allocation.x, spacer.allocation.y + BORDER_RADIUS, spacer.allocation.width, SHADOW_SIZE);
        ctx.fill ();
      }

      double r = 0, b = 0, g = 0;
      int width = this.allocation.width;
      int height = spacer.allocation.y + BORDER_RADIUS + SHADOW_SIZE;

      int delta = flag_selector.allocation.y - BORDER_RADIUS;
      if (!comp) delta = 0;
      
      ctx.save ();
      ctx.translate (SHADOW_SIZE, delta);
      width -= SHADOW_SIZE * 2;
      height -= SHADOW_SIZE + delta;
      // shadow
      ctx.translate (0.5, 0.5);
      ctx.set_operator (Operator.OVER);
      Utils.cairo_make_shadow_for_rect (ctx, 0, 0, width - 1, height - 1, BORDER_RADIUS, r, g, b, SHADOW_SIZE);
      ctx.translate (-0.5, -0.5);
      
      ctx.save ();
      // pattern
      Pattern pat = new Pattern.linear(0, 0, 0, height);
      r = g = b = 0.5;
      ch.get_color_colorized (ref r, ref g, ref b, ch.StyleType.BG, StateType.SELECTED);
      pat.add_color_stop_rgba (0.0, r, g, b, 0.95);
      r = g = b = 0.15;
      ch.get_color_colorized (ref r, ref g, ref b, ch.StyleType.BG, StateType.SELECTED);
      pat.add_color_stop_rgba (1.0, r, g, b, 1.0);
      Utils.cairo_rounded_rect (ctx, 0, 0, width, height, BORDER_RADIUS);
      ctx.set_source (pat);
      ctx.set_operator (Operator.SOURCE);
      ctx.clip ();
      ctx.paint ();
      ctx.restore ();

      ctx.restore ();
    }
    
    private void update_labels ()
    {
      var focus = model.get_actual_focus ();
      if (focus.value == null)
      {
        if (controller.is_in_initial_state ())
        {
          focus_label.set_text (controller.TYPE_TO_SEARCH);
          description_label.set_text (controller.DOWN_TO_SEE_RECENT);
        }
        else if (controller.is_searching_for_recent ())
        {
          focus_label.set_text ("");
          description_label.set_text (controller.NO_RECENT_ACTIVITIES);
        }
        else
        {
          focus_label.set_text (this.model.query[model.searching_for]);
          description_label.set_text (controller.NO_RESULTS);
        }
      }
      else
      {
        description_label.set_text (Utils.get_printable_description (focus.value));
        focus_label.set_markup (Utils.markup_string_with_search (focus.value.title, this.model.query[model.searching_for], ""));
      }
    }
    
    public override void update_focused_source (Entry<int, Match> m)
    {
      if (controller.is_in_initial_state ()) source_icon.set_icon_name ("search");
      else if (m.value == null) source_icon.set_icon_name ("");
      else
      {
        source_icon.set_icon_name (m.value.icon_name);
        results_sources.move_selection_to_index (m.key);
      }
      if (model.searching_for == SearchingFor.SOURCES) update_labels ();
    }
    
    public override void update_focused_action (Entry<int, Match> m)
    {
      if (controller.is_in_initial_state ()) action_icon.clear ();
      else if (m.value == null) action_icon.set_icon_name ("");
      else
      {
        action_icon.set_icon_name (m.value.icon_name);
        results_actions.move_selection_to_index (m.key);
      }
      if (model.searching_for == SearchingFor.ACTIONS) update_labels ();
    }
    
    public override void update_focused_target (Entry<int, Match> m)
    {
      // TODO: not implemented
    }
    
    public override void update_sources (Gee.List<Match>? list = null)
    {
      results_sources.update_matches (list);
    }
    public override void update_actions (Gee.List<Match>? list = null)
    {
      results_actions.update_matches (list);
    }
    public override void update_targets (Gee.List<Match>? list = null)
    {
    
    }
  }
}
