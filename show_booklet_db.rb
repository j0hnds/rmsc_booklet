require 'rubygems'
require 'postgres'
require 'show_booklet_config'

#
# This class defines the SQL statements we will be using to retrieve the data
# for the show booklet
#
class RMSCDB
  
  #
  # Constructs a new RMSCDB. Be aware that when the constructor is run, the
  # connection to the data base to be opened.
  #
  def initialize
    @conn = PGconn.open 'host' => Configuration.instance.get_value('/db/db_host'),
                        'dbname' => Configuration.instance.get_value('/db/db_name'),
                        'user' => Configuration.instance.get_value('/db/db_user'),
                        'password' => Configuration.instance.get_value('/db/db_pass')
  end

  #
  # Returns a result set containing the shows available in the system ordered
  # by create date (descending).
  #
  def get_shows
    @conn.exec("SELECT SHOW_ID, DESCRIPTION FROM SHOW ORDER BY CREATE_DATE DESC")
  end
  
  #
  # Returns the data base record for the information on the specified show
  #
  def get_show_info(show_id)
    res = @conn.exec("SELECT * FROM SHOW WHERE SHOW_ID = #{ show_id }")
    res[0]
  end
  
  #
  # Returns the exhibitor card information
  #
  def get_exhibitor_cards(show_id)
    return @conn.exec("SELECT
        e.FIRST_NAME || ' ' || e.LAST_NAME AS FULL_NAME,
        ea.ROOM_ASSIGNMENT,
        e.ADDRESS_1,
        e.CITY,
        e.STATE,
        e.POSTAL_CODE,
        e.PHONE,
        e.FAX,
        e.CELL,
        e.EMAIL,
        attendee_lines('E', e.EXHIBITOR_ID)
      FROM
        EXHIBITOR_ATTENDANCE ea,
        EXHIBITOR e
      WHERE
        e.EXHIBITOR_ID = ea.EXHIBITOR_ID
        AND ea.SHOW_ID = #{ show_id }
      ORDER BY
        e.LAST_NAME,
        e.FIRST_NAME")
  end
  
  #
  # Returns the exhibitor line/room information
  #
  def get_exhibitor_line_room(show_id)
    return @conn.exec("SELECT LINE, ROOM_ASSIGNMENT, FIRST_NAME || ' ' || LAST_NAME AS FULL_NAME FROM LINE_ROOM_EXHIBITOR WHERE SHOW_ID = #{ show_id } ORDER BY LINE, LAST_NAME, FIRST_NAME")
  end
  
  #
  # Closes the connection to the data base
  #
  def close
    @conn.close
  end
end

