from tkinter import *


class customButton:

    def __init__(self,master,text, clickedFunction, rownum, columnnum, colspan, rowspan,
                 label_width=20, font=("Helvetica", 10), justify='center', color_bg='lightblue', color_fg='black'
                 ):
        self.label_width = label_width
        self.font = font
        self.text = text
        self.clickedFunction = clickedFunction
        self.rownum = rownum
        self.columnnum = columnnum
        self.colspan = colspan
        self.rowspan = rowspan
        self.justify = justify
        self.bg = color_bg
        self.fg = color_fg

        self.Button = Button(master, width=self.label_width, height=1, text=self.text,
                             command=clickedFunction, font=self.font,bg=self.bg, justify=self.justify)
        self.Button.grid(row=self.rownum, column=self.columnnum, columnspan=self.colspan,
                         rowspan = self.rowspan, sticky='nesw')

class customLabel:

    def __init__(self,master,text, rownum, columnnum, colspan, rowspan ,label_width =20,
                 font = ("Arial", 12, 'bold'), justify = 'center', color_bg='lightblue', color_fg = 'black' ):
        self.label_width = label_width
        self.justify = justify
        self.font = font
        self.border_width = 2
        self.label_relief = "ridge"
        self.text = text
        self.rownum = rownum
        self.columnnum = columnnum
        self.colspan = colspan
        self.rowspan = rowspan
        self.bg = color_bg
        self.fg = color_fg

        self.Label = Label(master, fg=self.fg, width=self.label_width, height=1, text=self.text,
                           borderwidth=self.border_width, relief=self.label_relief, font=self.font,
                           bg=self.bg, justify=self.justify)

        self.Label.grid(row=self.rownum, column=self.columnnum, columnspan=self.colspan,
                        rowspan = self.rowspan, sticky='nesw')

class customEntry:

    def __init__(self,master,textVar, rownum, columnnum, colspan, rowspan, label_width =20):
        self.label_width = label_width
        self.border_width = 2
        self.label_height = 1
        self.label_relief = "ridge"
        self.textVar = textVar
        self.rownum = rownum
        self.columnnum = columnnum
        self.colspan = colspan
        self.rowspan = rowspan

        self.Entry = Entry(master, fg='blue', width=self.label_width, textvariable=self.textVar,
                           borderwidth=self.border_width, relief=self.label_relief, font=("Arial", 12, 'bold'),)

        self.Entry.grid(row=self.rownum, column=self.columnnum, columnspan=self.colspan,
                        rowspan = self.rowspan, sticky='nesw')


class customOptionMenu:

    def __init__(self,master,variable, variableList, rownum, columnnum, colspan, rowspan):
        self.label_width = 20
        self.label_height = 1
        self.border_width = 2
        self.label_relief = "ridge"
        self.variable = variable
        self.variableList = variableList
        self.rownum = rownum
        self.columnnum = columnnum
        self.colspan = colspan
        self.rowspan = rowspan

        self.OptionMenu = OptionMenu(master, self.variable, *self.variableList)
        self.OptionMenu.config(width=self.label_width, height=self.label_height, font=("Helvetica", 10,),
                               bg="lightblue")
        self.OptionMenu.grid(row=self.rownum, column=self.columnnum, columnspan=self.colspan,
                             rowspan = self.rowspan, sticky='nesw')

