#!/usr/bin/python
# -*- coding: UTF-8 -*-

############################################################################
##                                                                        ##
## Nautilus Terminal - A terminal embedded in Nautilus                    ##
##                                                                        ##
## Copyright (C) 2011  Fabien LOISON <flo at flogisoft dot com>           ##
##                                                                        ##
## This program is free software: you can redistribute it and/or modify   ##
## it under the terms of the GNU General Public License as published by   ##
## the Free Software Foundation, either version 3 of the License, or      ##
## (at your option) any later version.                                    ##
##                                                                        ##
## This program is distributed in the hope that it will be useful,        ##
## but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          ##
## GNU General Public License for more details.                           ##
##                                                                        ##
## You should have received a copy of the GNU General Public License      ##
## along with this program.  If not, see <http://www.gnu.org/licenses/>.  ##
##                                                                        ##
##                                                                        ##
## WEB SITE: http://projects.flogisoft.com/nautilus-terminal/             ##
##                                                                        ##
############################################################################


"""A terminal embedded in Nautilus."""

__author__ = "Fabien LOISON <flo at flogisoft dot com>"
__version__ = "1.0"
__appname__ = "nautilus-terminal"
__app_disp_name__ = "Nautilus Terminal"
__website__ = "http://projects.flogisoft.com/nautilus-terminal/"


import os
import sys
from signal import SIGTERM, SIGKILL
#Specific imports for Python 2 and 3
if sys.version_info < (3, 0):
    from urllib import url2pathname
    from ConfigParser import RawConfigParser
else:
    from urllib.request import url2pathname
    from configparser import RawConfigParser

from gi.repository import GObject, Nautilus, Gtk, Gdk, Vte, GLib


DEFAULT_CONF = {
        'general/def_term_height': 5, #lines
        'general/def_visible': True,
        'general/term_on_top': True,
        'terminal/shell': Vte.get_user_shell(),
        }


class Config(object):
    """Handles the configuration of Nautilus Terminal."""

    def __init__(self):
        """The constructor."""
        self._default = DEFAULT_CONF
        self._confp = RawConfigParser()
        self.read()

    def read(self):
        """Read the configuration from a file."""
        #Determine where is stored the configuration
        config_file = os.path.join(os.environ.get("HOME"), ".%s" % __appname__)
        if not os.path.isfile(config_file):
            try:
                from xdg import BaseDirectory
            except ImportError:
                pass
            else:
                config_file = os.path.join(
                    BaseDirectory.save_config_path(__appname__), "config.ini")
        if os.path.isfile(config_file):
            self._confp.read([config_file])

    def get(self, key, cast=str):
        """Get the value of a key.

        Returns the value of the given key in the configuration file or the
        default value.

        A key is composed of a section and an option name and looks like that:

            section/optionname

        Args:
            key -- The key (e.g. foo/bar)
            cast -- The type of the value (string by default)
        """
        if cast == bool:
            cast = lambda b: bool(int(b))
        section, option = key.split("/")
        if self._confp.has_option(section, option):
            return cast(self._confp.get(section, option))
        elif key in self._default:
            return cast(self._default[key])
        else:
            raise KeyError


class NautilusTerminal(object):
    """Nautilus Terminal itself.

    Args:
        uri -- The URI of the folder where the terminal will be created.
        window -- The parent window.
    """

    def __init__(self, uri, window):
        """The constructor."""
        self._window = window
        self._path = self._uri_to_path(uri)
        #Term
        self.shell_pid = -1
        self.term = Vte.Terminal()
        self.shell_pid = self.term.fork_command_full(Vte.PtyFlags.DEFAULT,
                self._path, [CONF.get("terminal/shell")], None,
                GLib.SpawnFlags.SEARCH_PATH, None, None)[1]
        self.term.connect_after("child-exited", self._on_term_child_exited)
        self.term.connect_after("popup-menu", self._on_term_popup_menu)
        self.term.connect("button-release-event", self._on_term_popup_menu)
        #Accelerators
        accel_group = Gtk.AccelGroup()
        self._window.add_accel_group(accel_group)
        self.term.add_accelerator(
                "paste-clipboard",
                accel_group,
                ord("V"),
                Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK,
                Gtk.AccelFlags.VISIBLE)
        self.term.add_accelerator(
                "copy-clipboard",
                accel_group,
                ord("C"),
                Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK,
                Gtk.AccelFlags.VISIBLE)
        #Drag & Drop
        self.term.drag_dest_set(
                Gtk.DestDefaults.MOTION |
                Gtk.DestDefaults.HIGHLIGHT |
                Gtk.DestDefaults.DROP,
                [Gtk.TargetEntry.new("text/uri-list", 0, 80)],
                Gdk.DragAction.COPY,
                )
        self.term.drag_dest_add_uri_targets()
        self.term.connect("drag_data_received", self._on_drag_data_received)
        #Swin
        self.swin = Gtk.ScrolledWindow()
        self.swin.nt = self
        #Popup Menu
        self.menu = Gtk.Menu()
        #MenuItem => copy
        menu_item = Gtk.ImageMenuItem.new_from_stock("gtk-copy", None)
        menu_item.connect_after("activate",
                lambda w: self.term.copy_clipboard())
        self.menu.add(menu_item)
        #MenuItem => paste
        menu_item = Gtk.ImageMenuItem.new_from_stock("gtk-paste", None)
        menu_item.connect_after("activate",
                lambda w: self.term.paste_clipboard())
        self.menu.add(menu_item)
        #MenuItem => separator #TODO: Implement the preferences window
        #menu_item = Gtk.SeparatorMenuItem()
        #self.menu.add(menu_item)
        #MenuItem => preferences
        #menu_item = Gtk.ImageMenuItem.new_from_stock("gtk-preferences", None)
        #self.menu.add(menu_item)
        #MenuItem => separator
        menu_item = Gtk.SeparatorMenuItem()
        self.menu.add(menu_item)
        #MenuItem => About
        menu_item = Gtk.ImageMenuItem.new_from_stock("gtk-about", None)
        menu_item.connect_after("activate",
                lambda w: self.show_about_dialog())
        self.menu.add(menu_item)
        #
        self.menu.show_all()
        #Conf
        self._set_term_height(CONF.get("general/def_term_height", int))
        self._visible = True
        #Lock
        self._respawn_lock = False
        #Register the callback for show/hide
        if hasattr(window, "toggle_hide_cb"):
            window.toggle_hide_cb.append(self.set_visible)

    def change_directory(self, uri):
        """Change the current directory in the shell if it is not busy.

        Args:
            uri -- The URI of the destination directory.
        """
        self._path = self._uri_to_path(uri)
        if not self._shell_is_busy():
            cdcmd = " cd '%s'\n" % self._path.replace("'", r"'\''")
            #self.term.feed("\033[8m", len("\033[8m"))
            self.term.feed_child(cdcmd, len(cdcmd))

    def get_widget(self):
        """Return the top-level widget of Nautilus Terminal."""
        if not self.term.get_parent():
            self.swin.add(self.term)
        if self._visible:
            self.swin.show_all()
        return self.swin

    def set_visible(self, visible):
        """Change the visibility of Nautilus Terminal.

        Args:
            visible -- True for showing Nautilus Terminal, False for hiding.
        """
        self._visible = visible
        if visible:
            self.swin.show_all()
            self._window.set_focus(self.term)
        else:
            self.swin.hide()

    def show_about_dialog(self):
        """Display the about dialog."""
        about_dlg = Gtk.AboutDialog()
        #Set the content of the dialog
        about_dlg.set_program_name(__app_disp_name__)
        about_dlg.set_version(__version__)
        about_dlg.set_comments(__doc__)
        about_dlg.set_website(__website__)
        about_dlg.set_copyright("Copyright (c) 2011  %s" % __author__)
        logo = Gtk.Image.new_from_file(
                "/usr/share/nautilus-terminal/logo_120x120.png")
        about_dlg.set_logo(logo.get_pixbuf())
        #Signal
        about_dlg.connect("response", lambda w, r: w.destroy())
        #Display de dialog
        about_dlg.show()

    def destroy(self):
        """Release widgets and the shell process."""
        #Terminate the shell
        self._respawn_lock = True
        try:
            os.kill(self.shell_pid, SIGTERM)
            os.kill(self.shell_pid, SIGKILL)
        except OSError:
            pass
        #Remove some widgets
        self.term.destroy()
        self.swin.destroy()
        #Remove callback
        if hasattr(self._window, "toggle_hide_cb"):
            self._window.toggle_hide_cb.remove(self.set_visible)

    def _shell_is_busy(self):
        """Check if the shell is waiting for a command or not."""
        wchan_path = "/proc/%i/wchan" % self.shell_pid
        wchan = open(wchan_path, "r").read()
        if wchan == "n_tty_read":
            return False
        elif wchan == "schedule":
            shell_stack_path = "/proc/%i/stack" % self.shell_pid
            try:
                for line in open(shell_stack_path, "r"):
                    if line.split(" ")[-1].startswith("n_tty_read"):
                        return False
                return True
            except IOError:
                #We can't know...
                return False
        else:
            return True

    def _uri_to_path(self, uri):
        """Returns the path corresponding of the given URI.

        Args:
            uri -- The URI to convert."""
        return url2pathname(uri[7:])

    def _set_term_height(self, height):
        """Change the terminal height.

        Args:
            height -- The new height (in lines).
        """
        self.swin.set_size_request(-1,
                height * self.term.get_char_height() + 2)

    def _on_term_popup_menu(self, widget, event=None):
        """Displays the contextual menu on right-click and menu-key."""
        if event: #button-release-event
            if event.type == Gdk.EventType.BUTTON_RELEASE \
            and event.button != 3:
                return
        self.menu.popup(None, None, None, None, 3, 0)

    def _on_term_child_exited(self, term):
        """Called when the shell is terminated.

        Args:
            term -- The VTE terminal (self.term).
        """
        if not self._respawn_lock:
            self.shell_pid = self.term.fork_command_full(Vte.PtyFlags.DEFAULT,
                self._path, [CONF.get("terminal/shell")], None,
                GLib.SpawnFlags.SEARCH_PATH, None, None)[1]

    def _on_drag_data_received(self, widget, drag_context, x, y, data, info, time):
        """Handles drag & drop."""
        for uri in data.get_uris():
            path = "'%s' " % self._uri_to_path(uri).replace("'", r"'\''")
            self.term.feed_child(path, len(path))


class Crowbar(object):
    """Modify the Nautilus' widget tree when the crowbar is inserted in it.

    Args:
        uri -- The URI of the current directory.
        window -- The Nautilus' window.
    """

    def __init__(self, uri, window):
        """The constructor."""
        self._uri = uri
        self._window = window
        #Crowbar
        self._crowbar = Gtk.EventBox()
        self._crowbar.connect_after("parent-set", self._on_crowbar_parent_set)
        #Lock
        self._lock = False

    def get_widget(self):
        """Returns the crowbar."""
        return self._crowbar

    def _on_crowbar_parent_set(self, widget, old_parent):
        """Called when the crowbar is inserted in the Nautilus' widget tree.

        Args:
            widget -- The crowbar (self._crowbar).
            old_parent -- The previous parent of the crowbar (None...).
        """
        #Check if the work has already started
        if self._lock:
            return
        else:
            self._lock = True
        #Get the parents of the crowbar
        crowbar_p = self._crowbar.get_parent()
        crowbar_pp = crowbar_p.get_parent()
        crowbar_ppp = crowbar_pp.get_parent()
        crowbar_pp.connect_after("parent-set", self._on_crowbar_pp_parent_set)
        #Get the childen of crowbar_pp
        crowbar_pp_children = crowbar_pp.get_children()
        #Check if our vpan is already there
        if type(crowbar_ppp) == Gtk.VPaned:
            #Find the Nautilus Terminal
            nterm = None
            for crowbar_ppp_child in crowbar_ppp.get_children():
                if type(crowbar_ppp_child) == Gtk.ScrolledWindow:
                    if hasattr(crowbar_ppp_child, "nt"):
                        nterm = crowbar_ppp_child.nt
                    break
            #Update the temrinal (cd,...)
            if nterm:
                nterm.change_directory(self._uri)
        #New tab/window/split
        else:
            #Create the vpan
            vpan = Gtk.VPaned()
            vpan.show()
            vbox = Gtk.VBox()
            vbox.show()
            if CONF.get("general/term_on_top", bool):
                vpan.add2(vbox)
            else:
                vpan.add1(vbox)
            #Add the vpan in Nautilus, and reparent some widgets
            if len(crowbar_pp_children) == 2:
                for crowbar_pp_child in crowbar_pp_children:
                    crowbar_pp.remove(crowbar_pp_child)
                crowbar_pp.pack_start(vpan, True, True, 0)
                vbox.pack_start(crowbar_pp_children[0], False, False, 0)
                vbox.pack_start(crowbar_pp_children[1], True, True, 0)
            #Create the terminal
            nterm = NautilusTerminal(self._uri, self._window)
            if hasattr(self._window, "term_visible"):
                nterm.set_visible(self._window.term_visible)
            if CONF.get("general/term_on_top", bool):
                vpan.add1(nterm.get_widget())
            else:
                vpan.add2(nterm.get_widget())

    def _on_crowbar_pp_parent_set(self, widget, old_parent):
        """Called when the vpan parent lost his parent.

        Args:
            widget -- The vpan's parent.
            old_parent -- The previous parent.
        """
        if not widget.get_parent():
            vpan = None
            for child in widget.get_children():
                if type(child) == Gtk.VPaned:
                    vpan = child
                    break
            if not vpan:
                print("[%s] W: Can't find the VPaned..." % __app_disp_name__)
                return
            swin = None
            for child in vpan.get_children():
                if type(child) == Gtk.ScrolledWindow:
                    swin = child
            if not swin:
                print("[%s] W: Can't find the ScrolledWindow..."
                        % __app_disp_name__)
                return
            if not hasattr(swin, "nt"):
                print("[%s] W: Can't find the Nautilus Terminal instance..."
                        % __app_disp_name__)
            swin.nt.destroy()


class NautilusTerminalProvider(GObject.GObject, Nautilus.LocationWidgetProvider):
    """Provides Nautilus Terminal in Nautilus."""

    def __init__(self):
        """The constructor."""
        print("[%s] I: Initializing the Nautilus extension"
                % __app_disp_name__)

    def get_widget(self, uri, window):
        """Returns a "crowbar" that will add a terminal in Nautilus.

        Args:
            uri -- The URI of the current directory.
            window -- The Nautilus' window.
        """
        if not hasattr(window, "toggle_hide_cb"):
            window.toggle_hide_cb = []
        if not hasattr(window, "term_visible"):
            window.term_visible = CONF.get("general/def_visible", bool)
        #URI specific stuff
        if uri.startswith("x-nautilus-desktop:///"):
            return
        elif not uri.startswith("file:///"):
            uri = "file://%s" % os.environ["HOME"]
        #Event
        window.connect_after("key-release-event", self._toggle_visible)
        #Return the crowbar
        return Crowbar(uri, window).get_widget()

    def _toggle_visible(self, window, event):
        """Toggle the visibility of Nautilus Terminal.

        This method is called on a "key-release-event" on the Nautilus'
        window.

        Args:
            window -- The Nautilus' window.
            event -- The detail of the event.
        """
        if event.keyval == 65473: #F4
            window.term_visible = not window.term_visible
            for callback in window.toggle_hide_cb:
                callback(window.term_visible)
            return True #Stop the event propagation


CONF = Config()

if __name__ == "__main__":
    #Code for testing Nautilus Terminal outside of Nautilus
    print("%s %s\nBy %s" % (__app_disp_name__, __version__, __author__))
    win = Gtk.Window()
    win.set_title("%s %s" % (__app_disp_name__, __version__))
    nterm = NautilusTerminal("file://%s" % os.environ["HOME"], win)
    nterm._respawn_lock = True
    nterm.term.connect("child-exited", Gtk.main_quit)
    nterm.get_widget().set_size_request(nterm.term.get_char_width() * 80 + 2,
            nterm.term.get_char_height() * 24 + 2)
    win.connect_after("destroy", Gtk.main_quit)
    win.add(nterm.get_widget())
    win.show_all()
    Gtk.main()
