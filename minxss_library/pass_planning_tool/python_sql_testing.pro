; Python stuff
; Simple test script to grab all the data from a test table and print it out

pro python_sql_testing

pydb = Python.Import('mysql.connector')

HELP, pydb
cnx = pydb.connect(user='root', password='minxsscubesat', host='macl68.lasp.colorado.edu', database='minxss_sdcard_db')
HELP, cnx
cursor_array = cnx.cursor()
cursor_tuple = cnx.cursor(named_tuple=True,buffered=True)

query = 'SELECT * FROM minxss_sdcard_db.test'

res = cursor_array.execute(query)
res = cursor_tuple.execute(query)

data = cursor_array.fetchall()
sizeinfo = size(data)
for i=0,sizeinfo[1]-1 do begin
  PRINT, data[i,0], data[i,1]
endfor

PRINT, Python.Run('print("hello world")')

end