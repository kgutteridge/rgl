# 
#  make test   - run the tests
#  make clean  - tidy up
#

LIB=./lib
RGL=rgl-$(VERSION)
BOOST_DOC=http://www.boost.org/libs/graph/doc
#BOOST_DOC=file://D:/Programme/bgl/boost_1_25_1/libs/graph/doc

default: test
test:
	cd tests && ruby -I../lib runtests.rb

# Release must have VERSION variable set
#
#    make VERSION=0.2 release
#

release: doc stamp clean tar

ftpput: ${RGL}.tgz
	ftpput.rb $<

stamp:
		ruby -i.bak -pe 'sub!(/V\d+(\.\d+)+/, "V$(VERSION)") if /_VERSION =/' ${LIB}/rgl/base.rb
		rm ${LIB}/rgl/base.rb.bak
		cvs commit
		cvs rtag `echo V$(VERSION) | sed s/\\\\./_/g` ruby/rgl

doc: ${LIB}/rgl/*.rb README
#	cd ${LIB} && rdoc --diagram --fileboxes --title RGL --main rgl/base.rb --op ../doc
	cd ${LIB} && rdoc.bat --title RGL --main rgl/base.rb --op ../doc
	cp examples/*.jpg doc/files/rgl
	ruby -i.bak -pe 'sub!(/http:..example.jpg/,"example.jpg")' doc/files/rgl/base_rb.html
	ruby -i.bak -pe 'sub!(/http:..module_graph.jpg/,"module_graph.jpg")' doc/files/rgl/base_rb.html
	find doc -name \*.html -print | xargs	ruby -i.bak -pe 'sub!(/BOOST_DOC.(.*.html)/,"<a href=${BOOST_DOC}/\\1>\\1<a>")'

install:
	ruby install.rb

tags:
	 rtags `find ${LIB} -name  '*.rb'`

tar: test
		ln -fs rgl ../${RGL}
		tar --directory=..			\
			--create			\
			--dereference			\
			--file=${RGL}.tgz 	\
			--gzip 			\
			--exclude='CVS' 		\
			--exclude='cvs' 		\
			--exclude='misc' 		\
			--exclude='doc' 		\
			--exclude='*.tgz' 		\
			--exclude='*/.*'		\
			${RGL}
		rm ../${RGL}

clean:
		rm -rf rgl*.tgz graph.dot TAGS examples/*/*.dot
		find . -name \*~ -print | xargs rm -f
		find . -name \*.bak -print | xargs rm -f
		find . -name core -print | xargs rm -f
