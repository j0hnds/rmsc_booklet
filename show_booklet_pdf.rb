require 'rubygems'
require 'pdf/writer'
require 'pdf/simpletable'

#
# This class is responsible for rendering the ShowBooklet
# to PDF.
#
class ShowBookletPDF < PDF::Writer
  
  # Array indexes for the values from a show record
  SHOW_START_DATE = 2
  SHOW_END_DATE = 3
  SHOW_LOCATION = 4
  SHOW_COORDINATOR = 9
  SHOW_LOCATION_PHONE = 10
  SHOW_LOCATION_FAX = 11
  SHOW_NEXT_SHOW = 13
  SHOW_COORDINATOR_PHONE = 14
  SHOW_COORDINATOR_EMAIL = 15
  SHOW_LOCATION_ADDRESS = 16
  SHOW_LOCATION_CITY = 17
  SHOW_LOCATION_STATE = 18
  SHOW_LOCATION_POSTAL_CODE = 19
  
  # Labels for months of the year
  MONTH_LABELS = [
    'NONE',
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ]
  
  #
  # Constructs a new ShowBookletPDF object which sets up the paper size to be
  # 'LEGAL', and the font families for Helvetica
  #
  def initialize
    super(:paper => 'LEGAL')
    
    # Set the font-family we will be using throughout
    font_families["Helvetica"] = {
      "b" => "Helvetica-Bold",
      "i" => "Helvetica-Oblique",
      "bi" => "Helvetica-BoldOblique",
      "ib" => "Helvetica-BoldOblique"
    }
    
    select_font "Helvetica"
  end
  
  #
  # Renders the booklet in PDF format for the specified show_id
  #
  # +show_id+: the id of the show for which the booklet is to be generated
  #
  def render_booklet(db, show_id)
    show_info = db.get_show_info show_id
    
    yield 0.10 if block_given?
    
    title_page show_info
    
    yield 0.20 if block_given?
    
    welcome_page show_info
    
    yield 0.30 if block_given?
    
    exhibitor_name_cards db.get_exhibitor_cards(show_id)
    
    yield 0.50 if block_given?
    
    line_room_exhibitor db.get_exhibitor_line_room(show_id)
    
    yield 0.70 if block_given?
    
    thank_you show_info
    
    yield 0.90 if block_given?
  end
  
  private 
  
  #
  # Render the title page of the booklet
  #
  # +show_info+: the information about the show
  #
  def title_page(show_info)
    # Bring in the mountains image
    image '../RMSC/images/mountains.jpeg', :justification => :center, :resize => :width
    
    text "<b>Rocky Mountain</b>", :font_size => 30, :justification => :center
    move_pointer 36
    text "<b>Shoe Show</b>", :justification => :center
    move_pointer 72
    
    text "<b>Denver Market</b>", :font_size => 20, :justification => :center
    move_pointer 144
    
    # Parse out the start date
    if show_info[SHOW_START_DATE] =~ /([0-9]{4})-([0-9]{2})-([0-9]{2})/
      year = $1
      month_i = $2.to_i
      month_s = MONTH_LABELS[month_i]
      start_day = $3
    end
    
    # Parse out the end date
    if show_info[SHOW_END_DATE] =~ /([0-9]{4})-([0-9]{2})-([0-9]{2})/
      year = $1
      month_i = $2.to_i
      month_s = MONTH_LABELS[month_i]
      end_day = $3
    end
    
    text "<b>#{ month_s } #{ start_day }-#{ end_day }, #{ year }</b>", :justification => :center
    text "<b>#{ show_info[SHOW_LOCATION] }</b>", :justification => :center
    text "<b>#{ show_info[SHOW_LOCATION_ADDRESS] }</b>", :justification => :center
    text "<b>#{ show_info[SHOW_LOCATION_CITY] }, #{ show_info[SHOW_LOCATION_STATE] } #{ show_info[SHOW_LOCATION_POSTAL_CODE] }</b>", :justification => :center
    move_pointer 72
    
    # Define the data for the dates table
    table = PDF::SimpleTable.new
    table.data = [
      { "day" => "Saturday", "time" => "9am to 5pm" },
      { "day" => "Sunday", "time" => "9am to 5pm" }
    ]
    table.column_order = [ "day", "time" ]
    table.shade_rows = :none
    table.show_headings = false
    table.show_lines = :none
    table.font_size = 15
    table.render_on self
    
    text "Friday & Monday - by Appointment only", :font_size => 15, :justification => :center
    start_new_page
  end
  
  #
  # Render the welcome page for the booklet.
  #
  # +show_info+: the show information
  #
  def welcome_page(show_info)
    # Parse out the start date
    if show_info[SHOW_START_DATE] =~ /([0-9]{4})-([0-9]{2})-([0-9]{2})/
      year = $1
      month_i = $2.to_i
      month_s = MONTH_LABELS[month_i]
      start_day = $3
    end
    
    text "<c:uline><b>Welcome to the Market</b></c:uline>", :font_size => 20, :justification => :center
    move_pointer 20
    text "Members of the Rocky Mountain Shoe Club welcome you to the #{ month_s }, #{ year } Denver Shoe Market."
    move_pointer 20
    text "We have over 69 Reps, marketing over 204 lines including shoes, socks, slippers and handbags."
    move_pointer 72
    
    text "<c:uline><b>Lunch</b></c:uline>", :justification => :center
    move_pointer 20
    text "Lunch will be served Saturday and Sunday from 11:30am to 1:30pm in the Aspen room and lounge area"
    move_pointer 20
    text "Retailers and exhibitors - We will be having a Saturday night social hour that will start @ 5:00pm in the Aspen room."
    move_pointer 20
    text "Snacks and soft drinks will be provided."
    move_pointer 20
    text "Alcoholic beverages will be provided by the exhibitors."
    move_pointer 72
    
    text "<b>NEXT SHOE MARKET</b>", :font_size => 30, :justification => :center
    text "<b>#{ show_info[SHOW_NEXT_SHOW] }</b>", :justification => :center
    move_pointer 144
    
    text "Show Coordinator: #{ show_info[SHOW_COORDINATOR] }", :font_size => 20, :justification => :center
    text "Phone: #{ show_info[SHOW_COORDINATOR_PHONE] }", :justification => :center
    text "#{ show_info[SHOW_COORDINATOR_EMAIL] }", :justification => :center
    start_new_page
  end
  
  #
  # Renders the exhibitor cards to the booklet
  #
  # +card_info+: collection of exhibitor cards to be rendered.
  #
  def exhibitor_name_cards card_info
    table = PDF::SimpleTable.new
    
    cols = [ 'col1', 'col2' ]
    # Build up an array of hashes for each cell in the table
    idx = 0
    table_data = []
    row_data = {}
    card_info.each do |row|
      # Build up the string
      data = "<b>#{ row[0] }</b>\n<b>Room ##{ row[1] }</b>"
      data << "\n#{ row[2] }\n#{ row[3] }, #{ row[4] } #{ row[5] }"
      phone = row[6]
      data << "\n<b>Phone: </b> #{ phone }" unless phone.nil? or phone.empty?
      fax = row[7]
      data << "\n<b>Fax: </b>#{ fax }" unless fax.nil? or fax.empty?
      cell = row[8]
      data << "\n<b>Cell: </b>#{ cell }" unless cell.nil? or cell.empty?
      email = row[9]
      data << "\n<c:uline>#{ row [9] }</c:uline>" unless email.nil? or email.empty?
      data << "\n<b>Lines: </b>#{ row[10] }"
      row_data[cols[idx % 2]] = data
      if idx % 2 == 1
        table_data << row_data
        row_data = {}
      end
      idx += 1
    end
    
    # Set up the column information
    col1 = PDF::SimpleTable::Column.new("col1")
    col1.width = in2pts(3.25)
    col2 = PDF::SimpleTable::Column.new("col1")
    col2.width = in2pts(3.25)
    
    table.columns = { "col1" => col1, "col2" => col2 }
  
    # p table_data  
    table.data = table_data
    table.column_order = cols
    table.shade_rows = :none
    table.show_headings = false
    table.show_lines = :none
    table.font_size = 15
    table.maximum_width = in2pts(7.5)
    table.row_gap = in2pts(0.2)
    table.render_on self
    start_new_page
  end
  
  #
  # Renders the line/room/exhibitor information
  #
  # +lre+: the line room exhibitor information
  #
  def line_room_exhibitor(lre)
    table = PDF::SimpleTable.new
    
    cols = [ 'line', 'room', 'exhibitor' ]
    
    data = []
    lre.each do |row|
      data << { 'line' => row[0],
                'room' => row[1],
                'exhibitor' => row[2] }
    end
    
    col1 = PDF::SimpleTable::Column.new('line')
    col1.heading = PDF::SimpleTable::Column::Heading.new('LINES')
    col1.heading.justification = :left
    col1.justification = :left
    col2 = PDF::SimpleTable::Column.new('room')
    col2.heading = PDF::SimpleTable::Column::Heading.new('ROOM')
    col2.heading.justification = :right
    col2.justification = :right
    col3 = PDF::SimpleTable::Column.new('exhibitor')
    col3.heading = PDF::SimpleTable::Column::Heading.new('EXHIBITOR')
    col3.heading.justification = :left
    col3.justification = :left
    
    table.data = data
    table.column_order = cols
    table.columns = { 'line' => col1, 'room' => col2, 'exhibitor' => col3 }
    # table.shade_rows = :none
    table.bold_headings = true
    table.font_size = 15
    table.render_on self
    # print "Current Page: #{ pdf.pages.size }"
  end
  
  #
  # Renders the thank-you page for the booklet.
  #
  # +show_info+: the show information
  #
  def thank_you(show_info)
    current_page = pages.size
    remainder = current_page % 4
    notes_pages_to_add = (remainder > 0) ? remainder - 1 : 3;
    (0...notes_pages_to_add).each do |i|
      start_new_page
      text "<c:uline><b>NOTES</b></c:uline>", :justification => :center
    end
    
    start_new_page
    text '<b>THANK YOU</b>', :font_size => 20, :justification => :center
    move_pointer 20
    text 'FOR COMING TO THE SHOW', :justification => :center
    move_pointer in2pts(2.0)
    
    text 'NEXT MARKET', :justification => :center
    text "#{ show_info[SHOW_NEXT_SHOW] }", :justification => :center
    move_pointer in2pts(2.0)
    
    text "#{ show_info[SHOW_LOCATION] }", :justification => :center
    text "#{ show_info[SHOW_LOCATION_ADDRESS] }", :justification => :center
    text "#{ show_info[SHOW_LOCATION_CITY] }, #{ show_info[SHOW_LOCATION_STATE] }  #{ show_info[SHOW_LOCATION_POSTAL_CODE] }", :justification => :center
    text "Phone: #{ show_info[SHOW_LOCATION_PHONE] }", :justification => :center
    text "Fax: #{ show_info[SHOW_LOCATION_FAX] }", :justification => :center
  end
  
end
