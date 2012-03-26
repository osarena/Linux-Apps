/*Network monitor v0.1
 *Author:Panos M for OSArena
 *Last Update:March 2012
 *licence GPL v3.0 http://www.gnu.org/copyleft/gpl.html
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "Network_monitor.h"

#define min_size 64
#define medium_size 128
#define max_size 256
/*================function prototypes================*/
void getIP(char *argv,char *myip);
void getBase(char *argv,char *myip,char *baseIP);
int bitcount (unsigned int n);
/*================prototypes end here================*/

/*Out main function*/
int main (int argc,char *argv[]){
	station_T *head,*curr,*next;
	FILE *pipe;
	char *substring;
	char line[max_size];
	char baseIP[medium_size];
	char command[max_size];
	char myip[min_size];
	//check that we are root for sudo nmap!
	if(geteuid() != 0){
		printf("You must be root to run this app please try again as root.\n");
		exit(0);
	}
	//check for one interface only
	if(argc!=2){
		printf("Usage Network_monitor [interface]\n");
		exit(0);
	}
	//check for nmap
	if(!(pipe = (FILE*)popen("which nmap","r")) ){
	      perror("Problems with pipe");
	      exit(1);
	}
	while(fgets(line,sizeof(line),pipe))
	pclose(pipe);	
	if(*line=='\0'){
		printf("Install Nmap\n");
		exit(0);
	}
	/*All done let's start"*/
	printf("Acquiring interface and ip.....\n");
	/*Get current Ip in the network.We don't want to find our mac address*/
	getIP(argv[1],myip);
	/*Get the number of hosts we will search*/
	getBase(argv[1],myip,baseIP);
	myip[strlen(myip)-1]='\0';
	strncpy(command,"sudo nmap  -sP ",max_size-1);
	strcat(command,baseIP);
	strcat(command," |grep -e report -e MAC |sed -e \'{\n s/Nmap scan report for //g \n s/MAC Address: //g}\'");
	printf("Starting nmap....\n");
	if(!(pipe = (FILE*)popen(command,"r")) ){
              perror("Problems with pipe");
              exit(1);
        }     
	/*Initialize linked list.Prototype Network_monitor.h*/
	head=(station_T*)malloc(sizeof(station_T));
	head->next=NULL;
	curr=head;  
        while(fgets(line,sizeof(line),pipe)){
		 line[strlen(line)-1]='\0';
		 if(strstr (line,myip))
			continue;
	         next=(station_T*)malloc(sizeof(station_T));
		 strncpy(next->IP,line,min_size-1);
		 fgets(line,sizeof(line),pipe);
		 substring = strtok (line," ");
		 strncpy(next->mac,substring,min_size-1);
		 substring = strtok (NULL,"");
		 strncpy(next->owner,substring,max_size-1);
		 next->next=NULL;
		 curr->next=next;
		 curr=next;
	}   
        pclose(pipe);
	printf("Nmap done...\n");
	printf("\t\tList\n");
	for(curr=head->next;curr!=NULL;curr=curr->next){
		/*We don't need \n because curr->owner has one!*/
		printf("%s %s %s",curr->IP,curr->mac,curr->owner);
	}
	for(curr=head;curr!=NULL;curr=curr->next){
		free(curr);
	}
	return 0;
}
/*void getIP(char *argv,char *myip)
* Purpose: Check for the existance of the given interface and returns Ip assigned at that.
* Parameters:
argv: given interface from command line
myip: string to be written
* Preconditions: none
* Postconditions: The interface exists
*/
void getIP(char *argv,char *myip){
	char command[max_size];
	char line[36];
	FILE *pipe;
	*line='\0';
	strcpy(command,"ifconfig ");
	strncat(command,argv,max_size-1);
	strcat(command,"  2>&1|grep \"inet addr:\"|cut -d: -f2|cut -d\\  -f1 ");
	if(!(pipe = (FILE*)popen(command,"r")) ){
              perror("Problems with pipe");
              exit(1);
        }
        fgets(line,sizeof(line),pipe);
        pclose(pipe);
	if(*line=='\0'){
		printf("Not valid Interface.Please verify that you type that well\n");
		exit(0);
	}
	strcpy(myip,line);
}

/*void getBase(char *argv,char *myip,char *baseIP)
* Purpose: Calculate base of that interface 
* e.g. 192.168.1.0/24
* Parameters:
* argv: given interface from command line
* myip: string with our address
* baseIP:String to be written
* Preconditions: none
* Postconditions: none
*/
void getBase(char *argv,char *myip,char *baseIP){
	char command[max_size];
        char line[36];
        char *substringIP;
	char *substringMask;
	char buffer[max_size];
	char output[max_size];
	char temp_ip[min_size];
	int IP[4];
	int Mask[4];
	int Nadd[4];
	int i,sum,temp;
	FILE* pipe;
	*command='\0';

	strcpy(command,"ifconfig ");
        strcat(command,argv);
        strcat(command," |grep \"Mask\"|cut -d\\: -f4");
        if(!(pipe = (FILE*)popen(command,"r")) ){
              perror("Problems with pipe");
              exit(1);
        }
        fgets(line,sizeof(line),pipe);
        pclose(pipe);
	i=0;
	strcpy(temp_ip,myip);
	substringIP = strtok (temp_ip,".");
  	while (substringIP != NULL){
		IP[i]=atoi(substringIP);
		substringIP = strtok (NULL,".");
		i++;
  	}
	i=0;
	substringMask=strtok(line,".");
	while (substringMask != NULL){
                Mask[i]=atoi(substringMask);           
                substringMask=strtok (NULL,".");
                i++;
        }
	for(i=0;i<4;i++){
		Nadd[i]=IP[i]&Mask[i];
	}
	sum=0;
	for(i=0;i<4;i++){
		temp=Mask[i]^255;
		sum=sum+bitcount(temp);		
	}
	sprintf(buffer,"%d",Nadd[0]);
	strcpy(output,buffer);
	for(i=1;i<4;i++){
		strcat(output,".");
		sprintf(buffer,"%d",Nadd[i]);
		strcat(output,buffer);	
	}
	sprintf(buffer,"/%d",32-sum);
	strcat(output,buffer);
	strcpy(baseIP,output);
}

/*int bitcount (unsigned int n)
* Purpose: count 1 bits
* Parameters:
* n: our number
* Preconditions: none
* Postconditions: none
*/
int bitcount (unsigned int n) {
	   int count = 0;
	   while (n) {
	      count += n & 0x1u;
	      n >>= 1;
	   }
	   return count;
}
