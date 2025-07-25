/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

namespace Reminduck {
    public class MainWindow : Gtk.ApplicationWindow {
        Gtk.Stack stack;
        Gtk.HeaderBar headerbar;
        Gtk.Button back_button;

        private GLib.Settings settings;
        public Gtk.Settings gtk_settings;
        public Granite.Settings granite_settings;

        Reminduck.Views.WelcomeView welcome_view;
        Reminduck.Views.ReminderEditor reminder_editor;
        Reminduck.Views.RemindersView reminders_view;
        Reminduck.Views.SettingsView settings_view;

        public MainWindow () {
            settings = new GLib.Settings ("io.github.ellie_commons.reminduck.state");
            Intl.setlocale ();

            set_default_size (
                this.settings.get_int ("window-width"),
                this.settings.get_int ("window-height")
            );

            // Use reminduck styling
            var app_provider = new Gtk.CssProvider ();
            app_provider.load_from_resource ("/io/github/ellie_commons/reminduck/Application.css");

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                app_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
            );

            stack = new Gtk.Stack () {
                transition_duration = 500,
                hexpand = vexpand = true,
                halign = Gtk.Align.FILL,
                valign = Gtk.Align.FILL,
            };


            title = _("Reminduck");
            Gtk.Label title_widget = new Gtk.Label (_("Reminduck"));
            title_widget.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

            this.headerbar = new Gtk.HeaderBar ();
            this.headerbar.title_widget = title_widget;
            this.headerbar.add_css_class ("default-decoration");

            set_titlebar (this.headerbar);

            granite_settings = Granite.Settings.get_default ();
                if (granite_settings.prefers_color_scheme == DARK) {
                    this.headerbar.add_css_class ("reminduck-headerbar-dark");
                } else {
                    this.headerbar.remove_css_class ("reminduck-headerbar-dark");
                }

            granite_settings.notify["prefers-color-scheme"].connect (() => {
                if (granite_settings.prefers_color_scheme == DARK) {
                    this.headerbar.add_css_class ("reminduck-headerbar-dark");
                } else {
                    this.headerbar.remove_css_class ("reminduck-headerbar-dark");
                }
            });

            this.back_button = new Gtk.Button.with_label (_("Back")) {
                valign = Gtk.Align.CENTER,
                tooltip_text = _("Click to return to main view")
            };
            this.back_button.add_css_class ("back-button");
            this.headerbar.pack_start (this.back_button);

            this.back_button.clicked.connect (() => {
                this.show_welcome_view ();
            });


            welcome_view = new Reminduck.Views.WelcomeView ();
            stack.add_named (welcome_view, "welcome");

            this.build_reminder_editor ();
            this.build_reminders_view ();
            this.build_settings_view ();

            stack.halign = stack.valign = Gtk.Align.FILL;
            stack.hexpand = stack.vexpand = true;

            var handle = new Gtk.WindowHandle () {
                child = stack
            };

            child = handle;

            this.show_welcome_view (Gtk.StackTransitionType.NONE);

            welcome_view.reminder_editor_button.clicked.connect (() => {
                show_reminder_editor ();
            });

            welcome_view.reminders_view_button.clicked.connect (() => {
                show_reminders_view (Gtk.StackTransitionType.SLIDE_LEFT);
            });

            welcome_view.settings_view_button.clicked.connect (() => {
                show_settings_view (Gtk.StackTransitionType.SLIDE_LEFT);
            });

            this.close_request.connect (e => {
                return before_destroy ();
            });
        }

        private void build_reminder_editor () {
            this.reminder_editor = new Reminduck.Views.ReminderEditor ();

            this.reminder_editor.reminder_created.connect ((new_reminder) => {
                ReminduckApp.reload_reminders ();
                show_reminders_view ();
            });

            this.reminder_editor.reminder_edited.connect ((edited_file) => {
                ReminduckApp.reload_reminders ();
                show_reminders_view ();
            });

            stack.add_named (this.reminder_editor, "reminder_editor");
        }

        private void build_reminders_view () {
            this.reminders_view = new Reminduck.Views.RemindersView ();

            this.reminders_view.add_request.connect (() => {
                show_reminder_editor ();
            });

            this.reminders_view.edit_request.connect ((reminder) => {
                show_reminder_editor (reminder);
            });

            this.reminders_view.reminder_deleted.connect (() => {
                ReminduckApp.reload_reminders ();
                if (ReminduckApp.reminders.size == 0) {
                    show_welcome_view ();
                } else {
                    this.reminders_view.build_reminders_list ();
                }
            });

            stack.add_named (this.reminders_view, "reminders_view");
        }

        private void build_settings_view () {
            this.settings_view = new Reminduck.Views.SettingsView ();
            stack.add_named (this.settings_view, "settings_view");
        }

        public void show_reminder_editor (Reminder? reminder = null) {
            stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT);
            stack.set_visible_child_name ("reminder_editor");
            this.back_button.show ();
            this.reminder_editor.edit_reminder (reminder);
        }

        private void show_reminders_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
            stack.set_transition_type (slide);
            stack.set_visible_child_name ("reminders_view");
            this.reminders_view.build_reminders_list ();
            this.back_button.show ();
            this.reminder_editor.reset_fields ();
        }

        public void show_welcome_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
            ReminduckApp.reload_reminders ();

            if (ReminduckApp.reminders.size > 0) {
                welcome_view.reminders_view_button.show ();
            } else {
                welcome_view.reminders_view_button.hide ();
            }

            stack.set_transition_type (slide);
            stack.set_visible_child_name ("welcome");
            this.back_button.hide ();
            this.reminder_editor.reset_fields ();
        }

        private void show_settings_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
            stack.set_transition_type (slide);
            stack.set_visible_child_name ("settings_view");
            this.back_button.show ();
        }

        private bool before_destroy () {
           int width, height;

            get_default_size (out width, out height);

            this.settings.set_int ("window-width", width);
            this.settings.set_int ("window-height", height);

            hide ();
            return true;
        }
    }
}
