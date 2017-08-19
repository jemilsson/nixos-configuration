from setuptools import setup


setup(
  name='helloflask',
  version='0.1',
  description='helloflask',
  package_dir={'':'helloflask'},
  include_package_data=True,
  packages=['helloflask'],
  #scripts=['voting/manage.py'],
)
