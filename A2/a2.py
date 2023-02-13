"""
Part2 of csc343 A2: Code that could be part of a ride-sharing application.
csc343, Fall 2022
University of Toronto

--------------------------------------------------------------------------------
This file is Copyright (c) 2022 Diane Horton and Marina Tawfik.
All forms of distribution, whether as given or with any changes, are
expressly prohibited.
--------------------------------------------------------------------------------
"""
import psycopg2 as pg
import psycopg2.extensions as pg_ext
from typing import Optional, List, Any
from datetime import datetime
import re


class GeoLoc:
    """A geographic location.

    === Instance Attributes ===
    longitude: the angular distance of this GeoLoc, east or west of the prime
        meridian.
    latitude: the angular distance of this GeoLoc, north or south of the
        Earth's equator.

    === Representation Invariants ===
    - longitude is in the closed interval [-180.0, 180.0]
    - latitude is in the closed interval [-90.0, 90.0]

    >>> where = GeoLoc(-25.0, 50.0)
    >>> where.longitude
    -25.0
    >>> where.latitude
    50.0
    """
    longitude: float
    latitude: float

    def __init__(self, longitude: float, latitude: float) -> None:
        """Initialize this geographic location with longitude <longitude> and
        latitude <latitude>.
        """
        self.longitude = longitude
        self.latitude = latitude

        assert -180.0 <= longitude <= 180.0, \
            f"Invalid value for longitude: {longitude}"
        assert -90.0 <= latitude <= 90.0, \
            f"Invalid value for latitude: {latitude}"


class Assignment2:
    """A class that can work with data conforming to the schema in schema.ddl.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of ride-sharing information.

    Representation invariants:
    - The database to which connection is established conforms to the schema
      in schema.ddl.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this Assignment2 instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path to
        uber, public.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-dianeh", "dianeh", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("nonsense", "silly", "junk")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=uber,public"
            )
            # This allows psycopg2 to learn about our custom type geo_loc.
            self._register_geo_loc()
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close the database connection.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection failed.

        >>> a2 = Assignment2()
        >>> # This example will work for you if you change the arguments as
        >>> # appropriate for your account.
        >>> a2.connect("csc343h-dianeh", "dianeh", "")
        True
        >>> a2.disconnect()
        True
        >>> a2.disconnect()
        False
        """
        try:
            if not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    # ======================= Driver-related methods ======================= #

    def clock_in(self, driver_id: int, when: datetime, geo_loc: GeoLoc) -> bool:
        """Record the fact that the driver with id <driver_id> has declared that
        they are available to start their shift at date time <when> and with
        starting location <geo_loc>. Do so by inserting a row in both the
        ClockedIn and the Location tables.

        If there are no rows are in the ClockedIn table, the id of the shift
        is 1. Otherwise, it is the maximum current shift id + 1.

        A driver can NOT start a new shift if they have an ongoing shift.

        Return True if clocking in was successful, False otherwise. I.e., do NOT
        throw an error if clocking in fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cursor = self.connection.cursor()
        shift_id_placer = 1
        try:
            check = 0
            # find if this driver with driver_id in in table DRIVER
            cursor.execute("select driver_id from Driver where driver_id = %s;", [driver_id])
            for each in cursor:
                check = 1
                print("This driver exists in the database")
            if check == 0:
                print("THIS DRIVER DOES NOT EXISTS IN THE DATABSE")
                return False

            # find all shift_id where driver clocked in, but never clocked out
            cursor.execute("(SELECT shift_id from clockedin where driver_id = %s ) except (select shift_id from clockedout);", [driver_id])
            for each in cursor:
                print("This driver did not clock out!")
                return False
            
            # now find shift_id_placer
            cursor.execute("select distinct max(shift_id) from clockedin;")
            for each in cursor:
                if each[0]:
                    shift_id_placer = each[0] + 1

            cursor.execute("insert into clockedin values (%s, %s, %s);", [shift_id_placer, driver_id, when])
            cursor.execute("insert into location values (%s, %s, %s);", [shift_id_placer, when, geo_loc])
            self.connection.commit()

            return True

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            #return False
            self.connection.rollback()
            return False

        return False


    def pick_up(self, driver_id: int, client_id: int, when: datetime) -> bool:
        """Record the fact that the driver with driver id <driver_id> has
        picked up the client with client id <client_id> at date time <when>.

        If (a) the driver is currently on an ongoing shift, and
           (b) they have been dispatched to pick up the client, and
           (c) the corresponding pick-up has not been recorded
        record it by adding a row to the Pickup table, and return True.
        Otherwise, return False.

        You may not assume that the dispatch actually occurred, but you may
        assume there is no more than one outstanding dispatch entry for this
        driver and this client.

        Return True if the operation was successful, False otherwise. I.e.,
        do NOT throw an error if this pick up fails.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        cursor = self.connection.cursor()
        try:
            request_id = None
            shift_id = None
            time = None
            # check if this driver is on an ongoing shift
            cursor.execute("""
                select shift_id from clockedin where driver_id = %s
                and shift_id not IN
                (select shift_id from clockedout);
            """, [driver_id])
            for each in cursor:
                shift_id = each[0]
            if shift_id is None:
                # this case this driver never had a shift
                return False
            print("driver on shift now")


            # check if this driver actually was assigned to this dispatch
            cursor.execute("select request.request_id from dispatch, request where dispatch.request_id = request.request_id and dispatch.shift_id = %s and client_id = %s;", [shift_id, client_id])
            for each in cursor:
                if request_id:
                    # found multiple dispatch entries.
                    return False
                print(each[0])
                request_id = each[0]
            if not request_id:
                # driver is not assigned to request_id
                return False
            

            # check inside pickup table to see if this client was picked up
            cursor.execute("select * from pickup where request_id = %s;", [request_id])
            for each in cursor:
                # this means the request_id already been picked up
                return False
            
            # now enter it in the database
            print("this is request_id")
            print(request_id)
            cursor.execute("insert into pickup values (%s, %s);", [request_id, when])
            print("inserted")
            self.connection.commit()
            return True
            
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            self.connection.rollback()
            return False

    # ===================== Dispatcher-related methods ===================== #

    def dispatch(self, nw: GeoLoc, se: GeoLoc, when: datetime) -> None:
        """Dispatch drivers to the clients who have requested rides in the area
        bounded by <nw> and <se>, such that:
            - <nw> is the longitude and latitude in the northwest corner of this
            area
            - <se> is the longitude and latitude in the southeast corner of this
            area
        and record the dispatch time as <when>.

        Area boundaries are inclusive. For example, the point (4.0, 10.0)
        is considered within the area defined by
                    NW = (1.0, 10.0) and SE = (25.0, 2.0)
        even though it is right at the upper boundary of the area.

        NOTE: + longitude values decrease as we move further west, and
                latitude values decrease as we move further south.
              + You may find the PostgreSQL operators @> and <@> helpful.

        For all clients who have requested rides in this area (i.e., whose
        request has a source location in this area) and a driver has not
        been dispatched to them yet, dispatch drivers to them one at a time,
        from the client with the highest total billings down to the client
        with the lowest total billings, or until there are no more drivers
        available.

        Only drivers who meet all of these conditions are dispatched:
            (a) They are currently on an ongoing shift.
            (b) They are available and are NOT currently dispatched or on
            an ongoing ride.
            (c) Their most recent recorded location is in the area bounded by
            <nw> and <se>.
        When choosing a driver for a particular client, if there are several
        drivers to choose from, choose the one closest to the client's source
        location. In the case of a tie, any one of the tied drivers may be
        dispatched.

        Dispatching a driver is accomplished by adding a row to the Dispatch
        table. The dispatch car location is the driver's most recent recorded
        location. All dispatching that results from a call to this method is
        recorded to have happened at the same time, which is passed through
        parameter <when>.

        If an exception occurs during dispatch, rollback ALL changes.

        Precondition:
            - <when> is after all dates currently recorded in the database.
        """
        # helper function to find if location is inside the boundry
        def check_area(nw: GeoLoc, se: GeoLoc, location: GeoLoc):
            if nw.latitude >= location.latitude and location.latitude >= se.latitude:
                if nw.longitude <= location.longitude and location.longitude <= se.longitude:
                    return True
            return False


        def find_driver(request_id, blackpink_in_your_area):
            # driver_id, shift_id, location inside each for blackpink
            # use psql to find a list of all the drivers cloest to this request_id
            cursor.execute("select driver_id from request, last_seen where request.request_id = %s order by source <@> location;", [request_id])
            for each in cursor:
                for driver in blackpink_in_your_area:
                    if driver[0] and driver[0] == each[0]:
                        # we can return
                        output = []
                        output.append(driver[1])
                        output.append(driver[2])
                        driver[0] = None
                        return output
            # this case, no driver can be assigned
            return None

        cursor = self.connection.cursor()
        try:
            # find all clients_id and the request_id, and location where no dispatch has gone to them yet
            # and filter out all the ones that are NOT in the area
            cursor.execute("select client_id, request_id, source from request where request_id not in (select request_id from dispatch);")
            unmatched = []
            list_of_clients = []
            for each in cursor:
                print(each[0])
                if check_area(nw, se, each[2]):
                    unmatched.append( (each[0], each[1], each[2]) )
                    list_of_clients.append(each[0])
            
            # sort client_id from most billed to least billed, be careful of clients with 0 billed
            sorted_client = []
            cursor.execute("select client_id from billed, request where billed.request_id = request.request_id group by client_id order by sum(amount) desc;")
            for cli in cursor:
                if cli[0] in list_of_clients:
                    index = list_of_clients.index(cli[0])
                    sorted_client.append(unmatched[index])
                    # delete that index from list_of_clients and unmatched
                    list_of_clients.pop(index)
                    unmatched.pop(index)
            # now add in the clients that were billed 0
            # this list contains cliend_id, request_id, source, destination
            sorted_client.extend(unmatched)


            # find all drivers that meet the req
            # find all drivers on a shift now
            cursor.execute("create temporary view latest_location as select shift_id, max(datetime) as max from location group by shift_id;")
            cursor.execute("create temporary view on_shift as (select shift_id from clockedin) except (select shift_id from clockedout);")
            cursor.execute("""create temporary view last_seen as 
                                select clockedin.driver_id, on_shift.shift_id, location 
                                from on_shift, latest_location, location, clockedin 
                                where on_shift.shift_id = latest_location.shift_id and 
                                location.shift_id = latest_location.shift_id and 
                                clockedin.shift_id = latest_location.shift_id and location.datetime = max ;""")
            # view last_seen only contains drivers who are on shift, and their location last seen
            # now we eliminate those that are on dispatch now
            cursor.execute("create temporary view dispatched_drivers as select shift_id from dispatch where request_id not in (select request_id from dropoff);")
            cursor.execute("select driver_id, last_seen.shift_id, location from last_seen where last_seen.shift_id not in (select shift_id from dispatched_drivers);")
            blackpink_in_your_area = []
            for each in cursor:
                if check_area(nw, se, each[2]):
                    blackpink_in_your_area.append( [each[0], each[1], each[2]] )
            
            for client in sorted_client:
                # pass in function request_id, and then whole driver list
                select_driver = find_driver(client[1], blackpink_in_your_area)
                # the selected driver will have shift_id, location
                # however, function find_driver will change the driver_id to NONE once it matched
                if not select_driver:
                    break
                # now we can insert into dispatch

                cursor.execute("insert into dispatch values (%s, %s, %s, %s);", [client[1], select_driver[0], select_driver[1], when])
            self.connection.commit()

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            self.connection.rollback()
            return

    # =======================     Helper methods     ======================= #

    # You do not need to understand this code. See the doctest example in
    # class GeoLoc (look for ">>>") for how to use class GeoLoc.

    def _register_geo_loc(self) -> None:
        """Register the GeoLoc type and create the GeoLoc type adapter.

        This method
            (1) informs psycopg2 that the Python class GeoLoc corresponds
                to geo_loc in PostgreSQL.
            (2) defines the logic for quoting GeoLoc objects so that you
                can use GeoLoc objects in calls to execute.
            (3) defines the logic of reading GeoLoc objects from PostgreSQL.

        DO NOT make any modifications to this method.
        """

        def adapt_geo_loc(loc: GeoLoc) -> pg_ext.AsIs:
            """Convert the given geographical location <loc> to a quoted
            SQL string.
            """
            longitude = pg_ext.adapt(loc.longitude)
            latitude = pg_ext.adapt(loc.latitude)
            return pg_ext.AsIs(f"'({longitude}, {latitude})'::geo_loc")

        def cast_geo_loc(value: Optional[str], *args: List[Any]) \
                -> Optional[GeoLoc]:
            """Convert the given value <value> to a GeoLoc object.

            Throw an InterfaceError if the given value can't be converted to
            a GeoLoc object.
            """
            if value is None:
                return None
            m = re.match(r"\(([^)]+),([^)]+)\)", value)

            if m:
                return GeoLoc(float(m.group(1)), float(m.group(2)))
            else:
                raise pg.InterfaceError(f"bad geo_loc representation: {value}")

        with self.connection, self.connection.cursor() as cursor:
            cursor.execute("SELECT NULL::geo_loc")
            geo_loc_oid = cursor.description[0][1]

            geo_loc_type = pg_ext.new_type(
                (geo_loc_oid,), "GeoLoc", cast_geo_loc
            )
            pg_ext.register_type(geo_loc_type)
            pg_ext.register_adapter(GeoLoc, adapt_geo_loc)


def sample_test_function() -> None:
    """A sample test function."""
    a2 = Assignment2()
    try:
        # TODO: Change this to connect to your own database:
        connected = a2.connect("csc343h-xushidon", "xushidon", "")
        print(f"[Connected] Expected True | Got {connected}.")

        # TODO: Test one or more methods here, or better yet, make more testing
        #   functions, with each testing a different aspect of the code.

        # ------------------- Testing Clocked In -----------------------------#

        # These tests assume that you have already loaded the sample data we
        # provided into your database.

        # This driver doesn't exist in db
        '''

        clocked_in = a2.clock_in(
            989898, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected False | Got {clocked_in}.")

        # This drive does exist in the db
        clocked_in = a2.clock_in(
            1, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected True | Got {clocked_in}.")

        # Same driver clocks in again
        clocked_in = a2.clock_in(
            1, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected False | Got {clocked_in}.")

        # shoulf be shift id 2
        clocked_in = a2.clock_in(
            2, datetime.now(), GeoLoc(-79.233, 43.712)
        )
        print(f"[ClockIn] Expected True | Got {clocked_in}.")

        '''

        


        # dummy test dispatch
        # a2.pick_up(12345, 99, datetime.now())
        a2.dispatch(GeoLoc(-10, 10), GeoLoc(10, -10), datetime.now())

    finally:
        a2.disconnect()


if __name__ == "__main__":
    # Un comment-out the next two lines if you would like all the doctest
    # examples (see ">>>" in the method and class docstrings) to be run
    # and checked.
    # import doctest
    # doctest.testmod()

    # TODO: Put your testing code here, or call testing functions such as
    #   this one:
    sample_test_function()
