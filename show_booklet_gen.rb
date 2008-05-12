#!/usr/bin/env ruby
#
# This file is gererated by ruby-glade-create-template 1.1.4.
#
require 'libglade2'
require 'show_booklet_pdf'
require 'show_booklet_db'
require 'show_booklet_log'

#
# The main application window for the Show Booklet Generation. The definition
# of the user interface is defined using Glade.
#
class ShowBookletGenGlade
  include GetText

  attr :glade
  
  #
  # Constructs a new ShowBookletGenGlade object
  #
  # +path_or_data+: the path to the Glade definition of the UI
  # +root+: Not sure what this is...think it is the parent window
  # +domain+: The Domain for the application
  # +localedir+: The directory containing locale information
  # +flag+: Flag determining the type of Glade data being provided
  #
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
    bindtextdomain(domain, localedir, nil, "UTF-8")
    @glade = GladeXML.new(path_or_data, root, domain, localedir, flag) {|handler| method(handler)}
    @db = RMSCDB.new
    @selected_show_id = nil
    @cbShow = @glade.get_widget("cbShows")
    @txtFile = @glade.get_widget("txtSelectedFile")
    @progress = @glade.get_widget("ctlProgress")
    @btnOK = @glade.get_widget("btnOK")
    @btnCancel = @glade.get_widget("btnCancel")
    @chkShowPDF = @glade.get_widget("chkShowPDF")
    @log = Log.instance.log
    load_shows
    @mainWindow = @glade.get_widget("mainWindow")
    @mainWindow.show
    @log.info "Started #{$0} at #{Time.now}"
  end

  #
  # Loads the set of shows found in the DB into the show combo box.
  #
  def load_shows
    res = @db.get_shows
    @list_store = Gtk::ListStore.new(String, String)
    cell_rend = Gtk::CellRendererText.new()
    @cbShow.pack_start(cell_rend, true)
    @cbShow.add_attribute(cell_rend, 'text', 1)
    @cbShow.set_model(@list_store)
    res.each do |row|
      iter = @list_store.append
      iter[0] = row[0]
      iter[1] = row[1]
    end
  end
  
  #
  # Checks the specified file path to determine if the directory containing the
  # file actually exists. If the path does not exist, a message dialog is 
  # displayed.
  #
  # Returns true if path is valid, false otherwise.
  #
  def valid_path?(path_name)
    is_valid_dir = true
    if path_name.nil? or path_name.empty?
      dlg = Gtk::MessageDialog.new(@mainWindow, 
                                   Gtk::Dialog::DESTROY_WITH_PARENT, 
                                   Gtk::MessageDialog::WARNING, 
                                   Gtk::MessageDialog::BUTTONS_CLOSE, 
                                   "Must specify a file name for the generated PDF file")
      dlg.run
      dlg.destroy
      is_valid_dir = false
    end
    dir_name = File.dirname path_name
    unless File.directory? dir_name
      dlg = Gtk::MessageDialog.new(@mainWindow, 
                                   Gtk::Dialog::DESTROY_WITH_PARENT, 
                                   Gtk::MessageDialog::WARNING, 
                                   Gtk::MessageDialog::BUTTONS_CLOSE, 
                                   "Not a valid directory: #{ dir_name }; cannot continue")
      dlg.run
      dlg.destroy
      is_valid_dir = false
    end
    if File.exist? path_name
      dlg = Gtk::MessageDialog.new(@mainWindow, 
                                   Gtk::Dialog::DESTROY_WITH_PARENT, 
                                   Gtk::MessageDialog::WARNING, 
                                   Gtk::MessageDialog::BUTTONS_YES_NO, 
                                   "File (#{path_name}) already exists, overwrite it")
      response = dlg.run
      dlg.destroy
      is_valid_dir = response == Gtk::Dialog::RESPONSE_YES
    end
    is_valid_dir
  end
  
  #
  # Verify that the show control has a selected show
  #
  # Returns false if the show setting is not valid.
  #
  def valid_show?
    is_valid_show = true
    if @selected_show_id.nil? or @selected_show_id.empty?
      dlg = Gtk::MessageDialog.new(@mainWindow, 
                                   Gtk::Dialog::DESTROY_WITH_PARENT, 
                                   Gtk::MessageDialog::QUESTION, 
                                   Gtk::MessageDialog::BUTTONS_YES_NO, 
                                   "Must specify a show to create the booklet for")
      dlg.run
      dlg.destroy
      is_valid_show = false
    end
    
    is_valid_show
  end
  
  #
  # Handler for the click on the OK button.
  #
  # +widget+: the button that was clicked.
  #
  def on_btnOK_clicked(widget)
    pdf_path = @txtFile.text
    generate_pdf pdf_path, @selected_show_id if valid_path? pdf_path and valid_show?
  end
  
  #
  # This method is responsible for generating the PDF file from the information
  # selected in the user interface.
  #
  # +pdf_path+: the path to the PDF file to be created
  # +show_id+: the ID of the show for which to create the booklet
  #
  # NOTES:
  #
  # 1) The PDF generation is run in a thread to keep the UI responsive; after
  #    all, it takes a while to generate the booklet.
  # 2) The OK/Cancel buttons are disabled during processing to keep the user
  #    from being a total idiot and mashing buttons while we are working
  #
  def generate_pdf(pdf_path, show_id)
    @progress.fraction = 0.0
    @progress.visible = true
    @btnOK.sensitive = false
    @btnCancel.sensitive = false
    
    thd = Thread.new(pdf_path, @progress, @db, show_id) do |path, progress, db, show|
      @log.info "Creating booklet for show (#{show_id}) in #{pdf_path}"
    
      pdf = ShowBookletPDF.new
      pdf.render_booklet db, show do |pct|
        progress.set_fraction(pct)
      end
      File.open(path, "wb") do |f|
        f.write pdf.render
      end
      
      progress.fraction = 1.0
      @log.info "Done creating booklet for show (#{show_id}) in #{pdf_path}"
      dlg = Gtk::MessageDialog.new(@mainWindow, 
                                   Gtk::Dialog::DESTROY_WITH_PARENT, 
                                   Gtk::MessageDialog::INFO, 
                                   Gtk::MessageDialog::BUTTONS_CLOSE, 
                                   "Your PDF file has been created...")
      dlg.run
      dlg.destroy
      progress.visible = false
      @btnOK.sensitive = true
      @btnCancel.sensitive = true
      
      # Now, we want to actually display the pdf
      system("evince #{pdf_path}") if @chkShowPDF.active?
    end
    
  end

  #
  # Handler for selection events on the shows combo box. Puts the new value
  # of the show into an instance member variable
  #
  # +widget+: the control that fired the event
  #
  def on_cbShows_changed(widget)
    active_row = widget.active
    if active_row >= 0
      @selected_show_id = widget.active_iter[0]
    end
  end

  #
  # Handler for when the user clicks the path browse button. Puts the 
  # selected file into the text box.
  #
  # +widget+: the control that was clicked
  #
  def on_btnChooseFile_clicked(widget)
    dlg = Gtk::FileChooserDialog.new("PDF File",
                                     @mainWindow,
                                     Gtk::FileChooser::ACTION_SAVE,
                                     nil,
                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                     [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
    current_file = @txtFile.text
    unless current_file.nil?
      dir = File.dirname current_file
      if File.directory? dir
        dlg.current_folder = dir
      end
    end
    
    if dlg.run == Gtk::Dialog::RESPONSE_ACCEPT
      @txtFile.text = dlg.filename
    end
    dlg.destroy
  end
  
  #
  # Handler for the cancel button. Exits the application.
  #
  # +widget+: the control that was clicked
  #
  def on_btn_Cancel_clicked(widget)
    @db.close
    Gtk.main_quit
  end
  
  #
  # Handler for the close button on the window manager. Exits the application.
  #
  # +widget+: the window
  # +arg0+: no idea what this is
  #
  def on_mainWindow_delete_event(widget, arg0)
    @db.close
    Gtk.main_quit
  end
  
end

# Main program
if __FILE__ == $0
  # Set values as your own application. 
  PROG_PATH = "show_booklet_gen.glade"
  PROG_NAME = "YOUR_APPLICATION_NAME"
  ShowBookletGenGlade.new(PROG_PATH, nil, PROG_NAME)
  Gtk.main
end
