vm-provider := vbox

default: all

all: pythonweb-vbox.box

pythonweb-vbox.box: template.json scripts/provision.sh http/preseed.cfg
	packer validate template.json
	packer build -force -only=pythonweb-vbox template.json
	vagrant box add ./pythonweb-vbox.box  --name pythonweb

.PHONY: clean
clean:
	-vagrant box remove -f pythonweb --provider virtualbox
	-rm -fr output-*/ *.box
