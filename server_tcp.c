/* A simple server in the internet domain using TCP
   The port number is passed as an argument */

//other options:
//http://cs.baylor.edu/~donahoo/practical/CSockets/textcode.html

#include <stdio.h> /* for printf and fprintf */
#include <sys/types.h> 
#include <sys/socket.h> /* for recv() and send() */
#include <netinet/in.h>
#include <unistd.h> /* for close() */

#define MAXPENDING 5 /*A defined integer for listener ?count? */
#define bufsize 32 /* size of receive buffer */

void error(char *msg) {
    perror(msg);
    exit(1);
}

char * do_work(char matrix[]) {
  return matrix;
}

int main(int argc, char *argv[]) {
     int sockfd, newsockfd, portno, clilen;
     struct sockaddr_in serv_addr, cli_addr;
     
     if (argc < 2) {
         fprintf(stderr,"ERROR, no port provided\n");
         exit(1);
     }

     sockfd = socket(AF_INET, SOCK_STREAM, 0);
     if (sockfd < 0) 
        error("ERROR opening socket");

     /* local port */
     portno = atoi(argv[1]);

     /* construct loccal address structure */
     bzero((char *) &serv_addr, sizeof(serv_addr));
     serv_addr.sin_family = AF_INET;
     serv_addr.sin_addr.s_addr = INADDR_ANY;
     serv_addr.sin_port = htons(portno);

     /* bind to local address */
     if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0) 
              error("ERROR on binding");

     /* mark the socket so it will listen for incoming connections */
     if (listen(sockfd,MAXPENDING) < 0)
      error("ERROR listen() failed");

//http://cs.baylor.edu/~donahoo/practical/CSockets/code/TCPEchoServer.c
while (1) {
     /* set the size of the in-out parameter */
     clilen = sizeof(cli_addr);

     /* wait for a client to connect */
     newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
     if (newsockfd < 0) 
          error("ERROR on accept");
     printf( "Handling client %s\n", inet_ntoa( serv_addr.sin_addr ) );
     handle_tcp_client(newsockfd);
/* handle (newsockfd)
     bzero(buffer,bufsize);
     n = read(newsockfd,buffer,255);
     if (n < 0) error("ERROR reading from socket");

     printf("Here is the message: %s\n",buffer);
     n = write(newsockfd,"I got your message",18);
     if (n < 0) error("ERROR writing to socket");
     return 0; 
*/
}

//http://cs.baylor.edu/~donahoo/practical/CSockets/code/HandleTCPClient.c
//recv is blocking ...therefore use 'read' ?!
//http://www.scottklement.com/rpg/socktut/nonblocking.html
//or is it the opposite ?!:
//http://jeremy.zawodny.com/blog/archives/010484.html
void handle_tcp_client(int clntSocket) {
    //char echoBuffer[bufsize];        /* Buffer for echo string */
    int recvMsgSize;                    /* Size of received message */
     //int n;
     char buffer[bufsize];
     //char *buffer[bufsize], *tok;

    /* Receive message from client */
    if ((recvMsgSize = recv(clntSocket, echoBuffer, bufsize, 0)) < 0)
        error("recv() failed");

    /* Send received string and receive again until end of transmission */
    while (recvMsgSize > 0)      /* zero indicates end of transmission */
    {
        /* Echo message back to client */
        if (send(clntSocket, echoBuffer, recvMsgSize, 0) != recvMsgSize)
            error("send() failed");

        /* See if there is more data to receive */
        if ((recvMsgSize = recv(clntSocket, echoBuffer, bufsize, 0)) < 0)
            error("recv() failed");
    }

    close(clntSocket);    /* Close client socket */
}
