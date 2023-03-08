
echo 'export PATH="/etc/poetry/bin:$PATH"' >> ${HOME}/.bashrc
source ${HOME}/.bashrc

poetry config virtualenvs.create false
poetry -vv install
