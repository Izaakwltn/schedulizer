FROM ubuntu:latest

RUN apt-get update && apt-get install -y make wget sbcl

RUN cd /tmp && \
    wget https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --load quicklisp.lisp --quit --eval '(quicklisp-quickstart:install)'

WORKDIR /root/quicklisp/local-projects/bartleby

# Copy necessary bartleby files:
COPY /webbartleby .
COPY /src .
COPY webbartleby.asd .
COPY bartleby.asd .
COPY /invoices .
COPY load.lisp .
COPY Makefile .

RUN make

EXPOSE 4242

ENTRYPOINT ["./launch-webbartleby"]




#-------------------------------
#FROM clfoundation/sbcl:2.2.2

#ARG QUICKLISP_DIST_VERSION=2022-02-20
#ARG QUICKLISP_ADD_TO_INIT_FILE=true

#RUN apt-get update && apt-get install make

# Make and set working directory
#WORKDIR /root/quicklisp/local-projects/bartleby

# Copy necessary bartleby files:
#COPY /webbartleby .
#COPY /src .
#COPY webbartleby.asd .
#COPY bartleby.asd .
#COPY /invoices .
#COPY load.lisp .
#COPY Makefile .

# Open port 4242
#EXPOSE 4242

#RUN set -x; \
 # /usr/local/bin/install-quicklisp \

# RUN make && ./launch-webbartleby

# RUN sbcl --load ./load.lisp

#ENTRYPOINT ["./launch-webbartleby"]

# ENTRYPOINT ["sbcl", "--eval" "(ql:quickload :webbartleby)" "--eval" "(webbartleby::main)"]

# sbcl --eval '(ql:quickload :web-bartleby)' --eval '(web-bartleby::main)'