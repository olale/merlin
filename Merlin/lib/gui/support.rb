
class Shoes
  class App   
    def icon filename=nil
      filename.nil? ? win.icon : win.icon = filename
      Gtk::Window.set_default_icon(win.icon)
    end
  end
end

# Only call Gtk.main_quit once to avoid warnings or errors related to
# "no Gtk main loop running"
class << Gtk; attr_accessor :running; end

class Object

  # Make sure Green Shoes does not crash on exit when exit is called with status
  def exit(status=true)
    if Gtk.running
      Gtk.main_quit
      File.delete Shoes::TMP_PNG_FILE if File.exist? Shoes::TMP_PNG_FILE
      Gtk.running=false
    end
  end
  
  # Override Green Shoes "confirm" method to provide dialog with a custom title
  def confirm title, msg
    $dde = true
    dialog = Gtk::Dialog.new(
      title, 
      get_win,
      Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
      [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT]
    )
    dialog.vbox.add Gtk::Label.new msg
    dialog.set_size_request 500, 100
    dialog.show_all
    ret = dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
    dialog.destroy
    ret
  end

end
