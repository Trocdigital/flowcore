install:
	pip install --upgrade python-datamodel
	pip install --upgrade asyncdb[default]
	pip install --upgrade navconfig[default]
	pip install --upgrade async-notify[all]
	pip install --upgrade navigator-api[locale,uvloop]
	# Nav requirements:
	pip install --upgrade navigator-session
	pip install --upgrade navigator-auth
	pip install --upgrade querysource
	pip install --upgrade gunicorn	
	pip install --upgrade azure-teambots


