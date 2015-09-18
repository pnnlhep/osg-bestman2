FROM kfox1111/osg-base
MAINTAINER Kevin Fox "Kevin.Fox@pnnl.gov"

RUN yum install -y osg-se-bestman lcmaps-plugins-gums-client lcmaps-plugins-basic lcmaps-plugins-verify-proxy pyxattr
ADD ./adler32 /usr/bin/adler32
RUN chmod +x /usr/bin/adler32
ADD ./start.sh /etc/start.sh
RUN chmod +x /etc/start.sh
RUN cp -a /etc/lcmaps.db /etc/lcmaps.db.bak
RUN echo globus_mapping liblcas_lcmaps_gt4_mapping.so lcmaps_callout echo > /etc/grid-security/gsi-authz.conf.bak

CMD ["/etc/start.sh"]
