/* Creates a datagram server.  The port 
   number is passed as an argument.  This
   server runs forever */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>

#define bufsize 1024 /*A defined integer for our buffer size*/

void error(char *msg) {
    perror(msg);
    exit(0);
}

char * do_work(char matrix[]) {
  return matrix;
}

int main(int argc, char *argv[]) {
   int sock, length, fromlen, n;
   struct sockaddr_in server;
   struct sockaddr_in from;
   //char buf[bufsize];
   char *buf[bufsize], *tok;
   char * message;

   if (argc < 2) {
      fprintf(stderr, "ERROR, no port provided\n");
      exit(0);
   }
   
   sock=socket(AF_INET, SOCK_DGRAM, 0);
   if (sock < 0) error("Opening socket");
   length = sizeof(server);
   bzero(&server,length);
   server.sin_family=AF_INET;
   server.sin_addr.s_addr=INADDR_ANY;
   server.sin_port=htons(atoi(argv[1]));
   if (bind(sock,(struct sockaddr *)&server,length)<0) 
       error("binding");
   fromlen = sizeof(struct sockaddr_in);
   while (1) {
//receiving:
       //n = recvfrom(sock,buf,bufsize,0,(struct sockaddr *)&from,&fromlen);
       //if (n < 0) error("recvfrom");

//in a loop?!
//http://www.dreamincode.net/code/snippet488.htm
/*Read into the buffer contents within thr file stream*/
//while(fgets(buf, bufsize, fp) != NULL)
//n = recvfrom(sock,buf,bufsize,0,(struct sockaddr *)&from,&fromlen);
while(recvfrom(sock,buf,bufsize,0,(struct sockaddr *)&from,&fromlen) != NULL) {
       write(1,"Received a datagram: ",21);
       write(1,buf,n);

/*Here we tokenize our string and scan for " \n" characters*/
for(tok = strtok(buf," \n");tok;tok=strtok(0," \n")){
printf("%s\n",tok);
}                 
fclose(fp); /*Close file*/
}/*Continue until EOF is encoutered*/

//working:
       message = do_work("this is a test");

//responding
       n = sendto(sock,message,sizeof(message),
                  0,(struct sockaddr *)&from,fromlen);
       if (n  < 0) error("sendto");
   }
 }

