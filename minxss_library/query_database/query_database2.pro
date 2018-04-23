;docformat = 'rst'
;+
; :Author:
;   Randy Reukauf, Bill Barrett
;
;-

;+
; The common_query_database_block procedure simply defines the
; common block of query_database.
;-
PRO common_query_database_block
  common query_database,$
    server,$
    database,$
    user,$
    password,$
    dbDriver,$
    dbUrl,$
    jdbcStatement,$
    dbConnectFlag
END
;docformat = 'rst'
;+
; :Author: Randy Reukauf (modified print_exception procedure by Chris Pankratz)
;    
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;-

;+
; Prints the Java exception encountered in the IDL-Java bridge.  If
; no exception is found, nothing is done.
;
; :Examples:
; - (from shell)::
; 
;   IDL> fjava_print_exception
;-
PRO fjava_print_exception

   jSession = OBJ_NEW('IDLJavaObject$IDLJAVABRIDGESESSION')
   javaException = jSession->GetException()
   if (OBJ_VALID(javaException)) then javaException->PrintStackTrace

RETURN
END
;docformat = 'rst'
;+
; :Author: Randy Reukauf
;
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.   
;-

;+
; Reads a login file to retrieve the information necessary to establish a JDBC 
; database connection.
; Supplied arguments take precedence over values in the login file.
; 
; :Returns:  values are returned in the keywords
; 
; :Keywords:
;   user: out, optional, type=String
;      the login name
;   password: out, optional, type=String
;      the login password
;   server: out, optional, type=String
;      the database server
;   database: out, optional, type=String
;      the database or instance
;   dbUrl: out, optional, type=String
;      the URL of the database
;   dbDriver: out, optional, type=String
;      the JDBC driver to use
;   dbloginfile: out, optional, type=String
;      the text file holding login information (recommend full path)
;   separator: out, optional, type=String
;      the separator to use in the text file
;   dbResourceId: out, optional, type=String
;      the id for a group of resources in a multi-user login file
;      
; :Examples:
; Get user, password, server, and database information from the dblogin loginfile::
; 
;   IDL> fjava_read_loginfile, user=user, password=password, server=server, &
;                              database=database, dbloginfile="/usr/home/kepler/dblogin"
;  
; Get user, password, and dbUrl for the TCTE_READER dbResourceId::
; 
;   IDL> fjava_read_loginfile, user=user, password=password, dbUrl=dbUrl, dbResourceId='TCTE_READER'
;-
PRO fjava_read_loginfile, $
 user = in_user, $
 password = in_password, $
 server = in_server, $
 database = in_database, $
 dbUrl = in_url, $
 dbDriver = in_driver, $
 dbloginfile = in_dbloginfile, $
 separator = in_separator, $
 dbResourceId = in_dbResourceId

ON_ERROR, 2

if (~KEYWORD_SET(separator)) THEN separator = ''
if (~KEYWORD_SET(in_dbloginfile)) THEN in_dbloginfile = ''

; make the default property values compatible with the IDL/Java bridge:
IF N_ELEMENTS(in_user) EQ 0 then userArg = '' else userArg = in_user[0]
IF N_ELEMENTS(in_password) EQ 0 THEN passwordArg = '' else passwordArg = in_password[0]
IF N_ELEMENTS(in_server) EQ 0 THEN serverArg = '' else serverArg = in_server[0]
IF N_ELEMENTS(in_database) EQ 0 THEN dbArg = '' else dbArg = in_database[0]
IF N_ELEMENTS(in_url) EQ 0 THEN urlArg = '' else urlArg = in_url[0]
IF N_ELEMENTS(in_driver) EQ 0 THEN driverArg = '' else driverArg = in_driver[0]
IF N_ELEMENTS(in_dbResourceID) EQ 0 then rsrcIDArg = '' else rsrcIDArg = in_dbResourceID[0]

;initialize a reader for reading resource properties:
reader = OBJ_NEW( $
    'IDLjavaObject$Static$site_connector.PropertyReader', $
    'site_connector.PropertyReader')

dbLoginProperties=reader->getProperties(in_dbloginfile, separator, rsrcIDArg, $
   userArg, passwordArg, dbArg, serverArg, urlArg, driverArg)

; If the user and password are not present in the properties file,
;   then there are serious problems. So they are not checked here.
in_user = dbLoginProperties->getProperty('user')
in_password = dbLoginProperties->getProperty('password')
; The remainder of the items are checked to avoid null values
temp = dbLoginProperties->getProperty('server')
IF N_ELEMENTS(temp) EQ 1 THEN in_server = temp ELSE in_server = ''
temp = dbLoginProperties->getProperty('database')
IF N_ELEMENTS(temp) EQ 1 THEN in_database = temp ELSE in_database = ''
temp = dbLoginProperties->getProperty('url')
IF N_ELEMENTS(temp) EQ 1 THEN in_url = temp ELSE in_url = ''
temp = dbLoginProperties->getProperty('driver')
IF N_ELEMENTS(temp) EQ 1 THEN in_driver = temp ELSE in_driver = ''

OBJ_DESTROY, reader
OBJ_DESTROY, dbLoginProperties

END
;docformat = 'rst'
;+
; :Author: Randy Reukauf, Dave Judd, wbarrett
;
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;-

;+
; This procedure is used to convert a JDBC result set into an array of structs.
; The tags of the struct correspond to the table column names.  If the result set
; is such that there are repeated column names then the name will have the column
; index (starting at 0) appended as a suffix.  The values in each struct will
; be the value stored in the database, or if that value is null the value will be
; either the JDBC default null value for the column type, or a value specified in
; the nullValues list.
; 
; :Params:
;    jResultSet: in, required, type=FJava JDBC Statement
;       the Java JDBC ResultSet holding the data to be retrieved
;    maxRows: in, required, type=int
;       the number of rows to be retrieved (-1 or unspecified retrieves
;       all rows).  If set, additional rows can be retrieved by recalling
;       this function as long as the resultSet is not modified.
;    result: out, required, type=array of structs
;       An array of structures holding the data returned from a query.  Each
;       struct contains a row of data from the specified result set.
;
; :Keywords:
;    nullValues: in, optional, type=Array of strings
;       an array of strings.  These strings represent a sequence of
;       ordered pairs where the first element is an SQL type code and the second
;       is a value used for null values of that type.  If this keyword is not 
;       specified, the Java JDBC default values for the type_codes will be used, or
;       null where no such default exists.
;
; :Examples:
; - jResultSet is the input JDBC statement, table is the returned array of structs::
; 
;   IDL> fjava_result_set_to_array, jResultSet, table
;-
pro fjava_result_set_to_array, $
 jResultSet, $
 result, $         
 maxRows, $
 nullValues = nullValues 
 
  ; Set the parameters needed for the ResultSetConverter to default values
  ;   if none are provided by the user
  maximumRows = KEYWORD_SET(maxRows) ? maxRows : -1
  if (n_elements(nullValues) EQ 0) then nullValues = strarr(1)
  
  ; Take the java.sql.ResultSet and convert it into something that
  ;   IDL can understand
  result_set_converter = OBJ_NEW( $
    'IDLjavaObject$lasp.mods.dbexchange.ResultSetConverter', $
    'lasp.mods.dbexchange.ResultSetConverter', $
    jResultSet, maximumRows, nullValues)

  ; How many columns of data were returned?
  column_count=result_set_converter->getColumnCount()
  ; If there were no columns returned then return a junk object
  if (column_count LE 0) then begin 
     if n_elements( result) gt 0 then junk = temporary( result)
     return
  endif

  ; Create an array of structures in which the first element is the
  ;  column name and the second element a suitable data structure
  ;  for the data returned by the column.
  column_names = result_set_converter->getColumnNames()
  type_codes = result_set_converter->getTypeCodes()
  ; Return the type codes if requested by the user
  FOR i = 0, column_count-1 DO BEGIN
    ;get the column and its typecode:
    column = result_set_converter->getColumn(i)
    column_size = result_set_converter->getColumnSize(i)
    if column_size LE 0 then column_size = 1
    ; Note that the only non-scalar data types that this code can deal
    ;   with are strings, arrays of doubles, and byte arrays
    case type_codes[i] of
       ; 12 is a type code indicating an array of strings: java.sql.Types.VARCHAR
       ; value is a place holder for a string
       12:    value = ' ' 
       ; 2003 is a type code indicating a column of numeric values: java.sql.Types.ARRAY
       ; value is a placeholder for an array of doubles
       2003:  value = dblarr(column_size)
       ;-2 is a type code indicating a column of byte arrays: java.sql.Types.BINARY
       -2  :  value = bytarr(column_size)
       ; For everything else just take the type of the first element of the column,
       ;   presumed to be a scalar
       else : value = column[0]
    endcase
    if n_elements( arrStruct) gt 0 then begin
      arrStruct = create_struct( arrStruct, column_names[i], value)
    endif else begin
      arrStruct = create_struct( column_names[i], value)
    endelse
  ENDFOR

 ; Now populate the structures with the received data
  FOR i = 0, column_count-1 DO BEGIN
    column = result_set_converter->getColumn(i)
    ; Get the array dimensions from the first row returned
    ; For java.sql.Types.BINARY (-2) the number of elements is the
    ;   number of array dimensions; for everything else is it the
    ;   size of the outer array
    if (i EQ 0) then begin
      element_size = type_codes[i] EQ -2 ? $
       (size(column, /dimensions))[0] : (size(column))[1]
      table = replicate(arrStruct, element_size)
    endif
    
    for j = 0, N_ELEMENTS(table)-1 do begin
      case type_codes[i] of
         ; 12 is java.sql.Types.VARCHAR -> IDL string
         12 :table[j].(i) = column[j]->toString()
         ; 2003 is java.sql.Types.ARRAY -> IDL double array
         2003 : table[j].(i) = column[j,*]
         ; -2 is java.sql.Types.BINARY -> IDL byte array
         -2 : table[j].(i) = column[j,*]
         ; otherwise the data is scalar
         else : table[j].(i) = column[j]
      endcase  
    endfor
  ENDFOR

  OBJ_DESTROY, result_set_converter
  result = table

END
;docformat = 'rst'
;+
; :Author: Randy Reukauf
;
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;-

;+
; Print (to standard output) java.lang.System and java.lang.Runtime
; properties of the Java virtual machine used by IDL.
;
; :Examples:
;   IDL> pjava_printprops
;-
PRO pjava_printprops
  ON_ERROR, 2

  ; Get properties of Java virtual machind (via IDL and the Java bridge)
  ; and print them.

  ; System is a static class, so create an IDLJavaObject STATIC object
  oSystem = OBJ_NEW("IDLJavaObject$STATIC$JAVA_LANG_SYSTEM", "java.lang.System")
  IF (OBJ_CLASS(oSystem) NE "IDLJAVAOBJECT$STATIC$JAVA_LANG_SYSTEM") THEN BEGIN
    PRINT, '(ERR) creating java.lang.System.  oSystem =', oSystem
  ENDIF

  oRt = OBJ_NEW("IDLJavaObject$STATIC$JAVA_LANG_RUNTIME", "java.lang.Runtime")
  IF (OBJ_CLASS(oRt) NE "IDLJAVAOBJECT$STATIC$JAVA_LANG_RUNTIME") THEN BEGIN
    PRINT, '(ERR) creating java.lang.Runtime.  oRt =', oRt
  ENDIF
  oRuntime = oRt->getRuntime()

  ; Print some of java.lang.System's properties (java)
  print, "java.version: ", oSystem->getProperty("java.version")
  print, "java.vendor: ", oSystem->getProperty("java.vendor")
  print, "java.class.path: ", oSystem->getProperty("java.class.path")
  print, "java home: ", oSystem->getProperty("java.home")
  print, "java.vm.name: ", oSystem->getProperty("java.vm.name")
  print, "java.vm.version: ", oSystem->getProperty("java.vm.version")
  print, "java.vm.vendor: ", oSystem->getProperty("java.vm.vendor")
  rs = oSystem->getProperty("java.net.preferIPv4Stack")
  if rs EQ '' then begin
     print, "java.net.preferIPv4Stack: not set (uses default)"
  endif else begin
     print, "java.net.preferIPv4Stack: " + rs
  endelse

  ; Print some of java.lang.System's properties (user)
  print, "user home: ", oSystem->getProperty("user.home")
  print, "user dir: ", oSystem->getProperty("user.dir")

  print, "Free Memory:  ", oRuntime->freeMemory()
  print, "Max Memory:   ", oRuntime->maxMemory()
  print, "Total Memory: ", oRuntime->totalMemory()

  ; delete the object
  OBJ_DESTROY, oSystem
  OBJ_DESTROY, oRt
  OBJ_DESTROY, oRuntime

END
;docformat = 'rst rst'
;+
; The close_query_database procedure closes Java JDBC objects.  If the
; all keyword is set, then common IDL variables are cleared.
;
;  Dependencies::
;
;    - idldb.jar: contains the Java JDBC code to interface with
;       database servers (e.g., /<full_path>/idldb.jar)
;    - <JDBC driver class>: a JDBC driver to connect to a database server (e.g.,/<full_path>/jconn3.jar)
;    - <Java Virtual Machine>: JVMs are usually part of a Java installation. Also, the environmental variables or
;        configuration files need to be set properly. (See the IDL documentation on the IDL-Java Bridge.)
;
; :Author:
;   Randy Reukauf, Bill Barrett
;-
;+
;
; :Keywords:
;    all: in, optional, type=boolean
;      clears common IDL variables
;-
PRO close_query_database, $
  all=close_all

  common query_database
  err_level = 0
  Catch, errorCode
  IF (errorCode NE 0) THEN BEGIN
    Catch, /CANCEL
  ENDIF

  IF OBJ_VALID(jdbcStatement) THEN BEGIN
    jdbcStatement->close
    OBJ_DESTROY, jdbcStatement
    dummy_var = TEMPORARY(jdbcStatement)
  ENDIF

  IF KEYWORD_SET(close_all) THEN BEGIN
    IF N_ELEMENTS(user) GT 0 THEN dummy_var = TEMPORARY(user)
    IF N_ELEMENTS(password) GT 0 THEN dummy_var = TEMPORARY(password)
    IF N_ELEMENTS(server) GT 0 THEN dummy_var = TEMPORARY(server)
    IF N_ELEMENTS(database) GT 0 THEN dummy_var = TEMPORARY(database)
    IF N_ELEMENTS(dbConnectFlag) GT 0 THEN $
      dummy_var = TEMPORARY(dbConnectFlag)
    IF N_ELEMENTS(dbDriver) GT 0 THEN dummy_var = TEMPORARY(dbDriver)
    IF N_ELEMENTS(dbUrl) GT 0 THEN dummy_var = TEMPORARY(dbUrl)
  ENDIF

  HEAP_GC

END
;docformat = 'rst'
;+
;   The purpose of this procedure is to execute an SQL query
;     and to return the number of rows affected and the
;     the result set
;
;  Dependencies::
;
;    - idldb.jar: contains the Java JDBC code to interface with
;       database servers (e.g., /<full_path>/idldb.jar)
;    - <JDBC driver class>: a JDBC driver to connect to a database server (e.g.,/<full_path>/jconn3.jar)
;    - <Java Virtual Machine>: JVMs are usually part of a Java installation. Also, the environmental variables or
;        configuration files need to be set properly. (See the IDL documentation on the IDL-Java Bridge.)
;
; :Author:
;   Bill Barrett
;
;-
;+
; :Params:
;   sqlString: in, required, type=String
;     a scalar string containing the SQL query statement that should be used 
;     to retrieve data from the database.
;   data: out, type=array
;      The array of structures that contain the return data from "select"
;          queries.  If no data are returned, either because no rows matched
;          the SQL query or because an "insert", "update", or "delete"
;          operation rather than a "select" was performed, the content of
;          this variable is not specified.  For "select" queries, always
;          check the value of nrows to be sure that this variable is not
;          undefined.
;
;   nrows: out, type=int
;      the number of rows of data returned by the query.
;           For "select" queries this will equal the number of
;             elements of data in the data variable.
;           For "insert", "update", or "delete" this is the number
;             of rows affected. 
;
; :Keywords:
;   dbConnect: in, optional, type=Boolean
;      indicates that a connection should be held open until the
;      dbClose keyword is set.  In standard operation (dbConnect is not set),
;      a connection is closed after each SQL command.  Setting this keyword
;      keeps the connection open, which reduces connection overhead and
;      is useful when using one database.  Note that if dbConnect is set,
;      subsequent login information is ignored until the RESET_LOGIN or
;      dbClose keywords are used. Note that dbConnect is NOT compatible
;      with using a resource id for multi database connections.
;   rowlimit: in, optional, type=int
;      limits the number of rows of data returned by a query.  The
;      number of rows returned will less than or equal to this number.

;-

PRO GET_DATA_FROM_ORACLE_SP, $
  sqlString, $
  data, $
  nrows, $
  jdbcConnection, $
  dbConnect=dbConnect, $
  debug = DEBUG

  ; Return if there is no query or valid database connection
  IF ~OBJ_VALID(jdbcConnection) || ~KEYWORD_SET(sqlString) THEN BEGIN
    data = 0L
    dummy_var = TEMPORARY(data)
    nrows = 0
    IF N_ELEMENTS(dbConnect) EQ 0 THEN BEGIN
      close_query_database
    ENDIF
    return
  ENDIF

  IF KEYWORD_SET(DEBUG) THEN print, sqlString

  ; Create the Java object that handles the stored procedure
  handler = OBJ_NEW( $
    'IDLjavaObject$storedProcedure.StoredProcedureHandler', $
    'storedProcedure.StoredProcedureHandler', sqlString)
  IF KEYWORD_SET(DEBUG) THEN BEGIN
    print, 'stored procedure name = ', handler->getStoredProcedureName()
    arguments = handler->getProcedureArguments()
    FOR j = 0, N_ELEMENTS(arguments)-1 DO BEGIN
      print, j, '  ', arguments[j]
    ENDFOR
  ENDIF
  
  ; Execute the stored procedure and try to process the results
  spResults = handler->execute(jdbcConnection);
  nResults = spResults->getObjectCount()
  ; If nothing came back our results are empty
  IF (nResults LE 0) THEN BEGIN
    nrows = 0
    data = 0L
    dummy_var = TEMPORARY(data)
  
  ENDIF ELSE BEGIN ; Process the results that have arrived
    nrows = 1
    FOR i = 0, nResults-1 DO BEGIN
      typeCode = spResults->getIdlDataType(i)
      result = spResults->getResult(i)
      CASE typeCode OF
        1: value = result->byteValue()    ; IDL byte
        2: value = result->shortValue()   ; IDL int
        3: value = result->intValue()     ; IDL long
        4: value = result->floatValue()   ; IDL float
        5: value = result->doubleValue()  ; IDL double
        7: value = result->toString()     ; IDL string
        14: value = result->longValue()   ; IDL long_64
        ELSE: value = result              ; ???
      ENDCASE
      name = spResults->getName(i)
      IF N_ELEMENTS(arrStruct) eq 0 THEN BEGIN
        arrStruct = create_struct( name, value)
      ENDIF ELSE BEGIN
        arrStruct = create_struct(TEMPORARY(arrStruct), name, value)
      ENDELSE
      data = replicate(arrStruct, nResults)
    ENDFOR
   ENDELSE
   OBJ_DESTROY, spResults
   OBJ_DESTROY, handler
   
END
;docformat = 'rst'
;+
;   The purpose of this procedure is to execute an SQL query
;     and to return the number of rows affected and the
;     the result set
;
;  Dependencies::
;
;    - idldb.jar: contains the Java JDBC code to interface with
;       database servers (e.g., /<full_path>/idldb.jar)
;    - <JDBC driver class>: a JDBC driver to connect to a database server (e.g.,/<full_path>/jconn3.jar)
;    - <Java Virtual Machine>: JVMs are usually part of a Java installation. Also, the environmental variables or
;        configuration files need to be set properly. (See the IDL documentation on the IDL-Java Bridge.)
;
; :Author:
;   Randy Reukauf, Bill Barrett
;
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;-
;+
; :Params:
;   sqlString: in, required, type=String
;     a scalar string containing the SQL query statement that should be used 
;     to retrieve data from the database.
;   data: out, type=array
;      The array of structures that contain the return data from "select"
;          queries.  If no data are returned, either because no rows matched
;          the SQL query or because an "insert", "update", or "delete"
;          operation rather than a "select" was performed, the content of
;          this variable is not specified.  For "select" queries, always
;          check the value of nrows to be sure that this variable is not
;          undefined.
;   nrows: out, type=int
;      the number of rows of data returned by the query.
;           For "select" queries this will equal the number of
;             elements of data in the data variable.
;           For "insert", "update", or "delete" this is the number
;             of rows affected.
;   dbConnectFlag: in, type=Boolean
;      True if we have valid database connection; false otherwise
;   jdbcStatement: in, type=object
;      This is the workhorse object that executes the queries and get the
;      return data.
;
; :Keywords:
;   dbConnect: in, optional, type=Boolean
;      indicates that a connection should be held open until the
;      dbClose keyword is set.  In standard operation (dbConnect is not set),
;      a connection is closed after each SQL command.  Setting this keyword
;      keeps the connection open, which reduces connection overhead and
;      is useful when using one database.  Note that if dbConnect is set,
;      subsequent login information is ignored until the RESET_LOGIN or
;      dbClose keywords are used. Note that dbConnect is NOT compatible
;      with using a resource id for multi database connections.
;   rowlimit: in, optional, type=int
;      limits the number of rows of data returned by a query.  The
;      number of rows returned will less than or equal to this number.
;   DEBUG: in, optional, type=Boolean
;      if true then addional debugging information is printed
;-

PRO GET_DATA_FROM_STATEMENT, $
  sqlString, $
  data, $
  nrows, $
  dbConnectFlag, $
  jdbcStatement, $
  dbConnect=dbConnect, $
  rowlimit = rowlimit, $
  debug = DEBUG

  IF N_ELEMENTS(dbConnectFlag) EQ 0 and KEYWORD_SET(dbConnect) THEN BEGIN
    IF OBJ_VALID(jdbcStatement) THEN dbConnectFlag = dbConnect $
    ELSE message, 'A connection could not be set because of an ' $
      + ' invalid jdbcStatement object.'
  ENDIF

  ; Return if there is no query or valid database connection
  IF NOT OBJ_VALID(jdbcStatement) or N_ELEMENTS(sqlString) EQ 0 THEN BEGIN
    data = 0L
    dummy_var = TEMPORARY(data)
    nrows = 0
    IF N_ELEMENTS(dbConnect) EQ 0 THEN BEGIN
      close_query_database
    ENDIF
    return
  ENDIF

  IF KEYWORD_SET(DEBUG) THEN print, sqlString

  ; Execute the SQL query and try to get the Java ResultSet
  isResult = jdbcStatement->execute(sqlString)
  ; isResult = true means a java.sql.ResultSet was returned,
  ;   false means none was. Typically a select returns a ResultSet
  ;   while insert, update, and delete return a count of the
  ;   number of rows updated without a ResultSet.
  WHILE NOT (isResult) DO BEGIN
    ; Was this an insert, update, or delete and do we have
    ;  a row count?
    updateCount = jdbcStatement->getUpdateCount()
    ; 'updateCount EQ -1' means that either there are no more results
    ;   or the query returned a java.sql.ResultSet
    IF (updateCount EQ -1 and NOT (isResult)) THEN break
    nrows = updateCount GE 0 ? updateCount : 0
    ; Is there a ResultSet following the update count?
    isResult = jdbcStatement->getMoreResults()
  ENDWHILE

  ; The data return is initialized to something invalid. If the
  ;   query does produce meaningful results, it will override this.
  data = 0L
  dummy_var = TEMPORARY(data)

  ; Process the Java result set if it is available
  IF (isResult) THEN BEGIN
    nrows = 0
    jdbcResultSet = jdbcStatement->getResultSet()
    ; Check if any rows were retrieved
    IF OBJ_VALID(jdbcResultSet) THEN BEGIN
      fjava_result_set_to_array, jdbcResultSet, result, rowlimit
      OBJ_DESTROY, jdbcResultSet
      IF N_ELEMENTS(result) GT 0 THEN BEGIN
        data = result
        nrows = SIZE(data, /N_ELEMENTS)
      ENDIF
    ENDIF
  ENDIF
  
END
;docformat = 'rst'
;+
;   The purpose of this function is to extract a database from a URL,
;     if possible.
;
; :Author:
;   Bill Barrett
;
;-
;+
; :Params:
;   dbURL: in, required, type=String
;     this should be a valid url
;
; :Returns:
;   a string with the database name if it can extracted from the url and
;     an empty string otherwise
;-
;
FUNCTION GET_DATABASE_FROM_URL, dbURL

  result = ''
  if keyword_set(dbURL) then begin
    ; a valid url should end with a colon followed by the IP port number
    ;  ( :[[:digit:]]+ as a regular expression) followed by either ':' or '/'
    ;  ( [/:] as a regular expression) and ending with a valid string
    ;  ( ([[:print:]]+)$ as a regular expression)
    ; The database should be the last group from the regular expresson match.
    regex_result = stregex(dbURL, ':[[:digit:]]+[/:]([[:print:]]+)$', /extract, /subexpr)
    if strlen(regex_result[1]) gt 0 then result =  regex_result[1]
  endif
  
  return, result
  
end



 

;docformat = 'rst'
;+
;   The purpose of this function is to create a valid JDBC connection.
;   Note that to do this one of the following three conditions must
;     be met.
;   1) there must be a valid resource id; OR 
;   2) there must a valid combination of user, password, server, and database; OR
;   3) there must a valid combination of user, password, and url
;
;  Dependencies::
;
;    - idldb.jar: contains the Java JDBC code to interface with
;       database servers (e.g., /<full_path>/idldb.jar)
;    - <JDBC driver class>: a JDBC driver to connect to a database server (e.g.,/<full_path>/jconn3.jar)
;    - <Java Virtual Machine>: JVMs are usually part of a Java installation. Also, the environmental variables or
;        configuration files need to be set properly. (See the IDL documentation on the IDL-Java Bridge.)
;
; :Author:
;   Randy Reukauf, Bill Barrett
;
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;-
;+
; :Params:
;   dbconnector: in, required, type=Object
;     an object that allows IDL through the IDL / Java bridge to
;     connect to the DbConnector class
;     
; :Keywords:
;   dbResourceId: in, optional, type=String
;      this specifies a group of items in a multi-database resource file.
;   user: in, optional, type=String
;      specifies the database user.
;   password: in, optional, type=String
;      specifies the user's password.
;   server: in, optional, type=String
;      specifies the database server to use.
;   database: in, optional, type=String
;      specifies the database or instance to use.
;   dbUrl: in, optional, type=String
;      specifies the database URL that the JDBC API uses to connect
;      to a database.
;   dbDriver: in, optional, type=String
;      specifies the JDBC driver to use.
;
;-
;
FUNCTION GET_DB_CONNECTION, dbconnector, $
  dbResourceId = dbResourceId, $
  user = user, $
  password = password, $
  server = server, $
  database = database, $
  dbUrl = dbUrl, $
  dbDriver = dbDriver

;   Note that the variable jdbcConnection will be undefined causing subsequent
;     software to fail unless:
;   1) there is be a valid resource id; OR 
;   2) there is a valid combination of user, password, server, and database; OR
;   3) there is a valid combination of user, password, and url

  ; If a resource id has been specified, try to use it
  IF KEYWORD_SET(dbResourceId) GT 0 THEN BEGIN
    jdbcConnection = dbconnector->getConnection(dbResourceId)
  ENDIF ELSE BEGIN
    ;  Are we trying to get the URL from the server?
    IF (KEYWORD_SET(server) GT 0 && $
      ~KEYWORD_SET(dbUrl)) THEN BEGIN
        jdbcConnection = dbconnector->getConnection( $
          user, password, server, database)
    ENDIF ELSE BEGIN
    ; Has a URL been specified for the database?
      IF KEYWORD_SET(dbUrl) THEN BEGIN
        jdbcConnection = dbconnector->getConnection(dbDriver, dbUrl, $
          user, password, server)
      ENDIF
    ENDELSE
  ENDELSE

RETURN, jdbcConnection

END
;docformat = 'rst rst'
;+
; The get_login_information function puts the user, password, server,
; database, dbConnectFlag, dbUrl, and dbDriver into a structure and returns it.
;
; :Author:
;   Randy Reukauf, Bill Barrett
;-
;+
;
; :Returns:
;    a structure containing the user, password, server,database,
;    dbConnectFlag, dbUrl, and dbDriver
;-
FUNCTION get_login_information
  common query_database
  IF N_ELEMENTS(user) GT 0 THEN user1 = user ELSE user1 = ''
  IF N_ELEMENTS(password) GT 0 THEN password1 = password ELSE password1 = ''
  IF N_ELEMENTS(server) GT 0 THEN server1 = server ELSE server1 = ''
  IF N_ELEMENTS(database) GT 0 THEN database1 = database ELSE database1 = ''
  IF N_ELEMENTS(dbDriver) GT 0 THEN dbDriver1 = dbDriver ELSE dbDriver1 = ''
  IF N_ELEMENTS(dbUrl) GT 0 THEN dbUrl1 = dbUrl ELSE dbUrl1 = ''
  IF N_ELEMENTS(dbConnectFlag) GT 0 THEN $
    connect1 = dbConnectFlag ELSE connect1 = 0
  result = {server:server1, database:database1, user:user1,$
    password:password1, dbDriver:dbDriver1, dbUrl:dbUrl1, dbconnect:connect1}
  return, result
END

;docformat = 'rst rst'
;+
; Is there sufficient information to form a JDBC connection?
;
; :Author:
;   Bill Barrett
;-
;+
; :Params:
;   user: in, optional, type=String
;      specifies the database user.
;   password: in, optional, type=String
;      specifies the user's password.
;   database: in, optional, type=String
;      specifies the database or instance to use.
;   server: in, optional, type=String
;      specifies the database server to use.
;   url: in, optional, type=String
;      specifies the database URL that the JDBC API uses to connect
;      to a database.
; :Returns:
;   1 (true) if there is insufficient information to form a JDBC connection;
;   0 (false) if there is enough information to form a JDBC connection.
;-

function insufficient_information_for_connection, user=user, password=password, $
  server=server, database=database, url=url

  ; Need both a user and a password for a valid connection
  if ~keyword_set(user) || ~keyword_set(password) then return, 1

  ; A user, password, and URL are sufficient to make a connection.
  if keyword_set(url) then return, 0

  ; If the URL is not present, it can be formed from the
  ;   server and database.
  return, (keyword_set(server) && keyword_set(database)) ? 0 : 1
end
;docformat = 'rst'
;+
;   The purpose of this procedure is to provide a diagnostic
;     printing capability for the input parameters to the
;     query_database procedure.
;
; :Author:
;   Randy Reukauf, Bill Barrett
;
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;-

; :Params:
;   sqlString: in, required, type=String
;     a scalar string containing the SQL query statement that should be used
;     to retrieve data from the database.
;   user: in, required, type=String
;     the user name from query database commons
;   server: in, required, type=String
;     the server name from query database commons
;   database: in, required, type=String
;     the database name from query database commons
;
; :Keywords:
;   limit_rows: in, optional, type=int
;      limits the number of rows of data returned by a query.  The
;      number of rows returned will less than or equal to this number.
;   in_user: in, optional, type=String
;      specifies the database user seen in the command line.
;   in_server: in, optional, type=String
;      specifies the database server seen in the command line.
;   in_database: in, optional, type=String
;      specifies the database or instance seen in the command line.
;   max_image_length: in, optional, type=int
;      specifies the maximum length that an image or text
;      datatype can be.  (This is mainly used for Sybase ASE servers.)
;   RESET_LOGIN: in, optional, type=Boolean
;      closes any existing connection and reconnects using
;      the current passed parameters.
;   GET_LOGIN: in, optional, type=Boolean
;      puts the current login information into the LOGIN_INFO keyword.
;   LOGIN_INFO: out, optional, type=Struct
;      if the GET_LOGIN keyword is set, returns the current login
;      information in a structure = {server, database, user, password}
;   dbloginfile: in, optional, type=String
;      specifies the login text file to use.  Overrides the
;      default login text file.
;   dbDriver: in, optional, type=String
;      the name of the JDBC driver in use
;   dbUrl: in, optional, type=String
;      the database url
;   dbResourceId: in, optional, type=String
;      this specifies a group of items in a multi-database resource file.
;   dbConnect: in, optional, type=Boolean
;      indicates that a connection should be held open until the
;      dbClose keyword is set.  In standard operation (dbConnect is not set),
;      a connection is closed after each SQL command.  Setting this keyword
;      keeps the connection open, which reduces connection overhead and
;      is useful when using one database.  Note that if dbConnect is set,
;      subsequent login information is ignored until the RESET_LOGIN or
;      dbClose keywords are used. Note that dbConnect is NOT compatible
;      with using a resource id for multi database connections.
;   dbClose: in, optional, type=Boolean
;      closes the connection and unsets the dbConnect status.  This
;      keywords precedes all other keywords, and no SQL commands will be
;      executed when this keyword is set.
;   ORACLE_SP: in, optional, type=Boolean
;      if the ORACLE_SP keyword is set, then the query is assumed to
;      be a call to an Oracle stored procedure
;
pro PRINT_INPUT_PARAMETERS, $
  sqlString, $
  user, $
  server, $
  database, $
  rowlimit = rowlimit, $
  in_user = in_user, $
  in_server = in_server, $
  in_database = in_database, $
  max_image_length = max_image_length, $
  RESET_LOGIN = RESET_LOGIN, $
  GET_LOGIN = GET_LOGIN, $
  LOGIN_INFO = LOGIN_INFO, $
  dbloginfile = dbloginfile, $
  dbDriver = dbDriver, $
  dbUrl = dbUrl, $
  dbResourceId = dbResourceId, $
  dbConnect = dbConnect, $
  dbClose = dbClose, $
  ORACLE_SP = ORACLE_SP

  print, "--------------------------------------------------------"
  IF N_ELEMENTS(sqlString) GT 0 THEN print, "sqlString = ", sqlString
  IF N_ELEMENTS(user) GT 0 THEN print, "user = ", user
  IF N_ELEMENTS(server) GT 0 THEN print, "server = ", server
  IF N_ELEMENTS(database) GT 0 THEN print, "database = ", database
  IF N_ELEMENTS(rowlimit) GT 0 THEN print, "rowlimit = ", rowlimit
  IF N_ELEMENTS(in_user) GT 0 THEN print, "in_user = ", in_user
  IF N_ELEMENTS(in_server) GT 0 THEN print, "in_server = ", in_server
  IF N_ELEMENTS(in_database) GT 0 THEN print, "in_database = ", in_database
  IF N_ELEMENTS(max_image_length) GT 0 THEN print, "max_image_length = ", $
    max_image_length
  IF N_ELEMENTS(RESET_LOGIN) GT 0 THEN print, "RESET_LOGIN = ", RESET_LOGIN
  IF N_ELEMENTS(GET_LOGIN) GT 0 THEN print, "GET_LOGIN = ", GET_LOGIN
  IF N_ELEMENTS(LOGIN_INFO) GT 0 THEN print, "LOGIN_INFO = ", LOGIN_INFO
  IF N_ELEMENTS(dbloginfile) GT 0 THEN print, "dbloginfile = ", dbloginfile
  IF N_ELEMENTS(dbDriver) GT 0 THEN print, "dbDriver = ", dbDriver
  IF N_ELEMENTS(dbUrl) GT 0 THEN print, "dbUrl = ", dbUrl
  IF N_ELEMENTS(dbResourceId) GT 0 THEN print, "dbResourceId = ", dbResourceId
  IF N_ELEMENTS(dbConnect) GT 0 THEN print, "dbConnect = ", dbConnect
  IF N_ELEMENTS(dbClose) GT 0 THEN print, "dbClose = ", dbClose
  IF N_ELEMENTS(ORACLE_SP) GT 0 THEN print, "ORACLE_SP = ", ORACLE_SP
  print, "--------------------------------------------------------"

END
;docformat = 'rst'
;+
;   The purpose of the query_database procedure is to execute an SQL
;      command that either retrieves ("select") data from a database or
;      alters the contents of the database ("insert", "update", and "delete").
;
;   Note that the login process can use one of several standard login,
;   text files (which will be read by the fjava_read_loginfile
;   procedure). The order of precedence for login text files is::
;     1) a file specified by the keyword "dbloginfile" in the query_database call
;     2) a file specified by the environment variable "DB_LOGIN_FILE"
;     3) a file in the current working directory named ".qdbResources"
;     4) a file in the current working directory named "dbLogin"
;     5) a file in the user's home directory named ".qdbResources"
;     6) a file in the user's home directory named "dbLogin"
;   
;   The files named ".qdbResources" are assumed to be multi database
;     resource specifications.
;   The files named ".dbLogin" are assumed to be single resource
;     specifications and are what query_database users
;     have worked with for all releases prior to 2.1
;   The detailed specification for correctly writing these files is
;     outside the scope of this documentation. It is available both
;     on confluence in the query_database specifications and as a
;     PDF file (generated from that web page) that is included
;     as part of the query_database distribution.
;     
;   When LASP used Sybase almost exclusively the standard was to
;     specify a server and database (schema) name because these
;     could be used to generate the URL that was necessary for the
;     actual database connection.
;   While query_database maintains this legacy compatibility, LASP's
;     shift to Oracle has made this more complicated, and it is now
;     preferable to specify a URL rather than a server / database pair. 
;
;   query_database does maintain a set of tables that map servers,
;     database, urls, and drivers. A query_database user going to a known
;     LASP Sybase or Oracle server will NOT need to specify a driver
;     because the software handles this automatically.
;   query_database can be used with other databases and drivers, but the
;     user must explicitly provide the URL and the name of the driver jar,
;     as well as the jar itself using the dbDriver and dbUrl keywords.
;
;   After the initial connection, login information is stored and reused (if
;   the dbConnection keyword is not set) until the RESET_LOGIN keyword is set.
;   This means that if new login information is provided after the first
;   login, the new login information will be ignored.  To use the new login
;   information, use the RESET_LOGIN keyword with the new login information.
;   
;  Dependencies::
;
;    - idldb.jar: contains the Java JDBC code to interface with
;       database servers (e.g., /<full_path>/idldb.jar)
;    - <JDBC driver class>: a JDBC driver to connect to a database server (e.g.,/<full_path>/jconn3.jar)
;    - <Java Virtual Machine>: JVMs are usually part of a Java installation. Also, the environmental variables or 
;        configuration files need to be set properly. (See the IDL documentation on the IDL-Java Bridge.)   
;   
; :Author: 
;   Randy Reukauf, Bill Barrett
;   
;-

;+
; :Params:
;   sqlString: in, required, type=String
;     a scalar string containing the SQL query statement that should be used 
;     to retrieve data from the database.
;   data: out, type=array
;      The array of structures that contain the return data from "select"
;          queries.  If no data are returned, either because no rows matched
;          the SQL query or because an "insert", "update", or "delete"
;          operation rather than a "select" was performed, the content of
;          this variable is not specified.  For "select" queries, always
;          check the value of nrows to be sure that this variable is not
;          undefined.
;
;   nrows: out, type=int
;      the number of rows of data returned by the query.
;           For "select" queries this will equal the number of
;             elements of data in the data variable.
;           For "insert", "update", or "delete" this is the number
;             of rows affected. 
;
;
; :Keywords:
;   limit_rows: in, optional, type=int
;      limits the number of rows of data returned by a query.  The
;      number of rows returned will less than or equal to this number.
;      A value less than or equal to 0 means that all available rows
;      will be returned.
;   debug: in, optional, type=boolean
;      prints debugging information to standard output.
;   database: in, optional, type=String
;      specifies the database or instance to use.  (Overrides any
;      entry in the login text file.)
;   server: in, optional, type=String
;      specifies the database server to use.  (Overrides any
;      entry in the login text file.)
;   user: in, optional, type=String
;      specifies the database user.  (Overrides any
;      entry in the login text file.)
;   password: in, optional, type=String
;      specifies the user's password.  (Overrides any
;      entry in the login text file.)
;   max_image_length: in, optional, type=int
;      specifies the maximum length that an image or text
;      datatype can be.  (This is mainly used for Sybase ASE servers.)
;   RESET_LOGIN: in, optional, type=Boolean
;      closes any existing connection and reconnects using
;      the current passed parameters.
;   GET_LOGIN: in, optional, type=Boolean
;      puts the current login information into the LOGIN_INFO keyword.
;   dbloginfile: in, optional, type=String
;      specifies the login text file to use.  Overrides the
;      default login text file.
;   dbResourceId: in, optional, type=String
;      this specifies a group of items in a multi-database resource file.
;   dbDriver: in, optional, type=String
;      specifies the JDBC driver to use. (Overrides any entry in the
;      login text file.)
;   dbUrl: in, optional, type=String
;      specifies the database URL that the JDBC API uses to connect
;      to a database. (Overrides any entry in the login text file.).
;   dbConnect: in, optional, type=Boolean
;      indicates that a connection should be held open until the
;      dbClose keyword is set.  In standard operation (dbConnect is not set),
;      a connection is closed after each SQL command.  Setting this keyword
;      keeps the connection open, which reduces connection overhead and
;      is useful when using one database.  Note that if dbConnect is set,
;      subsequent login information is ignored until the RESET_LOGIN or
;      dbClose keywords are used. Note that dbConnect is NOT compatible
;      with using a resource id for multi database connections.
;   dbClose: in, optional, type=Boolean
;      closes the connection and unsets the dbConnect status.  This
;      keywords precedes all other keywords, and no SQL commands will be
;      executed when this keyword is set.
;   LOGIN_INFO: out, optional, type=Struct
;      if the GET_LOGIN keyword is set, returns the current login
;      information in a structure = {server, database, user, password}
;   ORACLE_SP: in, optional, type=Boolean
;      if the ORACLE_SP keyword is set, then the query is assumed to
;      be a call to an Oracle stored procedure
;   suppress_stack_trace: in, optional, type=Boolean
;      if the suppress_stack_trace keyword is set, then the stack trace
;      print in the error handler is suppressed
;
; :Examples:
;    - Uses information from the .dbLogin file to supply user, password,and server. Data is returned in the data parameter and nrows is set::
;    
;       IDL> query_database, "select * from TestTable3", data, nrows, database="SORCE_TEST"
;
;    - Resets the connection to a held connection using keyword parameters.  No SQL command is issued::
;    
;       IDL> query_database, /dbConnect, /reset_login, user="rept_user", password="rept_password", $
;                            database="REPT_CT", server="rept-db"
;
;    - Releases the current database connection and resets login information::
;    
;       IDL> query_database, /dbClose
;-
PRO query_database, $
 sqlString, $
 data, $
 nrows, $
 limit_rows = rowlimit, $
 database = in_database, $
 checkUnsigned = checkUnsigned, $
 debug = DEBUG, $
 server = in_server, $
 user = in_user, $
 password = in_password, $
 max_image_length = max_image_length, $
 RESET_LOGIN = RESET_LOGIN, $
 GET_LOGIN = GET_LOGIN, $
 LOGIN_INFO = LOGIN_INFO, $
 dbloginfile = dbloginfile, $
 dbResourceId = dbResourceId, $
 dbDriver = in_dbDriver, $
 dbUrl = in_dbUrl, $
 dbConnect = dbConnect, $
 dbClose = dbClose, $
 ORACLE_SP = ORACLE_SP, $
 suppress_stack_trace = suppress_stack_trace

   common query_database 
   IF N_ELEMENTS(in_dbDriver)  THEN dbDriver = in_dbDriver[0]
   
   ; A new url means that any previously saved server and database
   ;  information are probably incorrect and should be cleared unless
   ;  they are also explicitly specified
   IF KEYWORD_SET(in_dbUrl) THEN BEGIN
     dbUrl = in_dbUrl[0]
     server = ''
     database = ''
   ENDIF
   
   ; Similarly an explicitly specified server means that previously
   ;  stored url information is probably no longer correct
   IF KEYWORD_SET(in_server) THEN BEGIN
     server = in_server[0]
     IF ~KEYWORD_SET(in_dbUrl) THEN dbUrl = ''
   ENDIF
   
   actual_database = GET_DATABASE_FROM_URL(in_dbUrl)
   IF ~KEYWORD_SET(actual_database) THEN BEGIN
     actual_database = KEYWORD_SET(in_database) ? in_database : ''
   ENDIF

   ; Initialize
   data = 0L
   dummy_var = TEMPORARY(data)
   nrows = 0

   Catch, errorCode
   IF (errorCode NE 0) THEN BEGIN
      Catch, /CANCEL
      IF ~KEYWORD_SET(suppress_stack_trace) THEN BEGIN
        LOGIN_INFO = get_login_information()
        IF N_ELEMENTS(sqlString) GT 0 THEN print, sqlString
        IF N_ELEMENTS(user) GT 0 THEN print, "user = ", user
        IF N_ELEMENTS(server) GT 0 THEN print, "server = ", server
        IF N_ELEMENTS(database) GT 0 THEN print, "database = ", database
        IF N_ELEMENTS(dbDriver) GT 0 THEN print, "dbDriver = ", dbDriver
        IF N_ELEMENTS(dbUrl) GT 0 THEN print, "dbUrl = ", dbUrl
        IF N_ELEMENTS(dbResourceId) GT 0 THEN print, "dbResourceId = ", dbResourceId
        fjava_print_exception
      ENDIF
      data = 0L
      dummy_var = TEMPORARY(data)
      nrows = -1
      message, 'Database Error Encountered and Caught.  Returning...', /info
      message, !error_state.msg, /info
      return
   ENDIF
      

   IF KEYWORD_SET(GET_LOGIN) THEN BEGIN
      ; set the current login information for option return to the user
      LOGIN_INFO = get_login_information()
      return
   ENDIF

   ;the location of this debug statement is critical to the correct execution of
   ;IDL unit tests including query_database_get_login_info_test, it should not be moved
   IF KEYWORD_SET(DEBUG) THEN print, systime()

   ;the /dbClose keyword clears the common block, closes connections and returns:
   IF KEYWORD_SET(dbClose) then begin
     close_query_database,   /all
     return  
   endif

   ;the /RESET_LOGIN keyword clears the common block, closes connections and continues:
   if (KEYWORD_SET(RESET_LOGIN)) then close_query_database, /all

   ;if a client wraps the sql string in a list, use the first element (this oddity
   ;is legacy code):
   IF N_ELEMENTS(sqlString) GE 1 THEN sqlString = sqlString[0]

   ;if the connection needs to be established or reset then get the login info:
   IF N_ELEMENTS(dbConnectFlag) EQ 0 THEN BEGIN
      IF NOT OBJ_VALID(jdbcStatement) or KEYWORD_SET(dbConnect) THEN BEGIN
         IF N_ELEMENTS(in_user) GT 0 THEN user = in_user[0] ELSE user = ''
         IF N_ELEMENTS(in_password) GT 0 THEN password = in_password[0] ELSE password = ''
         IF N_ELEMENTS(in_server) GT 0 THEN server = in_server[0] ELSE server = ''
         IF N_ELEMENTS(actual_database) GT 0 THEN database = actual_database[0] ELSE database = ''

         ; Always use the input information to form the connection if it is sufficient.
         ; If not, then try to read the information from a resource file
         IF insufficient_information_for_connection(user=user, password=password, $
           server=server, database=database, url=dbUrl) then begin
           fjava_read_loginfile, user=user, password=password, server=server, $
             database=database, dbUrl=dbUrl, dbDriver=dbDriver, $
             dbloginfile=dbloginfile, dbResourceId=dbResourceId
         ENDIF
      endif
   endif

   ; if the login info has changed and a connection requested, then connect to the db:
   IF N_ELEMENTS(sqlString) GT 0 || KEYWORD_SET(dbConnect) THEN BEGIN
     dbconnector = OBJ_NEW( $
       'IDLjavaObject$Static$site_connector.DbConnector', $
       'site_connector.DbConnector')
     jdbcConnection = GET_DB_CONNECTION(dbconnector, dbResourceId=dbResourceId, user=user, $
       password=password, server=server, database=database, dbUrl=dbUrl, dbDriver=dbDriver)
     IF ~KEYWORD_SET(ORACLE_SP) THEN BEGIN
       jdbcStatement = dbconnector->getStatement(jdbcConnection)
     ENDIF
   ENDIF
    
   IF KEYWORD_SET(DEBUG) THEN BEGIN
     PRINT_INPUT_PARAMETERS, sqlString, user, server, database, rowlimit = rowlimit, in_user = in_user, $
       in_server = in_server, in_database = in_database, max_image_length = max_image_length, $
       RESET_LOGIN = RESET_LOGIN, GET_LOGIN = GET_LOGIN, LOGIN_INFO = LOGIN_INFO, $
       dbloginfile = dbloginfile, dbDriver = dbDriver, dbUrl = dbUrl, dbResourceId = dbResourceId, $
       dbConnect = dbConnect, dbClose = dbClose, ORACLE_SP = ORACLE_SP
   ENDIF

   IF ~KEYWORD_SET(ORACLE_SP) THEN BEGIN
     GET_DATA_FROM_STATEMENT, sqlString, data, nrows, dbConnectFlag, jdbcStatement, dbConnect=dbConnect, $
      rowlimit = rowlimit, debug = DEBUG
   ENDIF ELSE BEGIN
     GET_DATA_FROM_ORACLE_SP, sqlString, data, nrows, jdbcConnection, dbConnect=dbConnect, debug = DEBUG
   ENDELSE
   
   IF OBJ_VALID(dbconnector) THEN OBJ_DESTROY, dbconnector

   IF N_ELEMENTS(dbConnectFlag) EQ 0 THEN BEGIN
      close_query_database
   ENDIF

END
