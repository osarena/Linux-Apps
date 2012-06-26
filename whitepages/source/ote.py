# -*- coding: utf-8 -*-
#--------------------------------------------------------#
#Ote whitepages v0.1
#Author:Panos M for OSArena
#Last Update:June 2012
#licence GPL v3.0 http://www.gnu.org/copyleft/gpl.html
#--------------------------------------------------------#

from mechanize import Browser
import sys,signal
whitepages = Browser()

name_string =('<span id="reslist_ctl01_surname">','<br></span></b>')
city_string=('<div align="left">','<br>')
address_string=('<span id="reslist_ctl01_straddr" class="text-black">','</span>')

def send_data(number):
	whitepages.open("http://www.whitepages.gr/gr/")
	whitepages.select_form(name="frm")
	whitepages["x_tel"] = number
	print "Αποστολή Δεδομένων..."
	res=whitepages.submit()
	print "Λήψη δεδομένων..."
	content=res.read()
	decontent=decodeHtmlentities(content)
	output=decontent+number
	print '\033[31m'+output+''+'\033[0m'+''

def decodeHtmlentities(string):
	start=string.find(name_string[0])
	if start==-1:
		return 'Δεν βρέθηκαν εγγραφές για: '
	stop=string.find(name_string[1],start)
	start=start+len(name_string[0])
	Name=string[start:stop].replace("&nbsp;"," ")
	start=string.find(city_string[0],stop)
	stop=string.find(city_string[1],start)
	start=start+len(city_string[0])
	city=string[start:stop]
	start=string.find(address_string[0],stop)
        stop=string.find(address_string[1],start)
        start=start+len(address_string[0])
	Address=string[start:stop]
	return '\t'+Name+'\n'+'\t'+city+'\n'+'\t'+Address+'\n'+'\t'

def debug():
	print 'Χρήση:python ote.py [τηλέφωνο](προαιρετικά)'
	sys.exit(1)	

if __name__ == '__main__' :

	def handler(*args):
		print '\n'
		sys.exit(0)
	signal.signal(signal.SIGINT,handler)
	if len(sys.argv)==1:
		number  = raw_input("Τηλέφωνο: ")
	elif len(sys.argv)==2:
		number=sys.argv[1]
	else:
		debug()
	send_data(number)
