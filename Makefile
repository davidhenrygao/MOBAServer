PLAT = linux
SKYNET_PATH = skynet

all: skynet

skynet:
$(SKYNET_PATH)/skynet: $(SKYNET_PATH)/Makefile
	cd $(SKYNET_PATH) && $(MAKE) $(PLAT)

.PHONY: all clean cleanall

clean:
	cd $(SKYNET_PATH) && $(MAKE) clean

cleanall:
	cd $(SKYNET_PATH) && $(MAKE) cleanall
