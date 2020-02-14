FROM chrishah/ubuntu-basic:18

MAINTAINER <christoph.hahn@uni-graz.at>

WORKDIR /usr/src

# install Augustus (the version shipping with ubuntu 18 is 3.3, but had problems with this so I replace it with version 3.3.2 which can be downloaded as executable from Github)
RUN apt install -y augustus augustus-data augustus-doc libyaml-perl parallel && \
	wget -O /usr/bin/augustus https://github.com/Gaius-Augustus/Augustus/releases/download/3.3.2/augustus
#Set the location of the augustus config data
ENV AUGUSTUS_CONFIG_PATH /usr/share/augustus/config
#Add Augustus scripts directory to PATH
ENV PATH="/usr/share/augustus/scripts:${PATH}"

#replace autoAugTrain.pl script with version that fixes a bug when training Augustus with UTR 
#replace autoAugPred.pl script with custom version that is parallelized (some steps) via GNU parallel
#both the scripts were modified from the versions shipping with Ubuntu 18.04
ADD to_include/autoAugTrain.pl to_include/autoAugPred.pl to_include/autoAug.pl /usr/share/augustus/scripts/

#fix path to augustus in scripts and remove check regarding scipio.pl abort in the autoAug pipeline
RUN sed -i 's?augpath = ".*?augpath = "/usr/bin/augustus";?' /usr/share/augustus/scripts/autoAug.pl && \
	sed -i 's/==0 or die("Program aborted. Possibly.*/;/' /usr/share/augustus/scripts/autoAugTrain.pl && \
	sed -i 's?aug="$AUGUSTUS_CONFIG_PATH/../src/augustus?aug="/usr/bin/augustus?' /usr/share/augustus/scripts/autoAugPred.pl

#Some perl modules
#DBI perl module is necessary for autoAug
ENV PERL_MM_USE_DEFAULT=1
RUN cpan DBI && \
	cpan YAML
#set up minimal bioperl
RUN wget https://github.com/bioperl/bioperl-live/archive/release-1-7-2.tar.gz && \
	tar xvfz release-1-7-2.tar.gz && \
	rm release-1-7-2.tar.gz
ENV PERL5LIB="/usr/src/bioperl-live-release-1-7-2"

#set up scipio
ADD to_include/scipio-1.4.zip /usr/src/
RUN unzip scipio-1.4.zip && \
	ln -s $(pwd)/scipio-1.4/*.pl /usr/bin && \
	ln -s $(pwd)/scipio-1.4/scipio.1.4.1.pl /usr/bin/scipio.pl

#Download blat and pslcdnafilter
RUN wget -O /usr/bin/blat http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64.v385/blat/blat && \
	chmod a+x /usr/bin/blat && \
	wget -O /usr/bin/pslCDnaFilter http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64.v385/pslCDnaFilter && \ 
	chmod a+x /usr/bin/pslCDnaFilter

#add user (not really necessary)
RUN adduser --disabled-password --gecos '' augustus
USER augustus
