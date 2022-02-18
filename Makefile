PLUGIN = cscope_auto

SOURCE = plugin/cscope_auto.vim
SOURCE += autoload/cscope_auto.vim

${PLUGIN}.vba: ${SOURCE}
	vim --cmd 'let g:plugin_name="${PLUGIN}"' -s build.vim

install:
	rsync -Rv ${SOURCE} ${HOME}/.vim/

clean:
	rm ${PLUGIN}.vmb
