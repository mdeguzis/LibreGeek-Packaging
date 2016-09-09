import sys
import os

from distutils.core import setup
from setuptools import find_packages

install_requires = [
    'lxml',
    'progressbar',
    'keyring',
    'pyxdg',
]

# sys.path.append is used for this specific build to give
# access to the resources normally in the GitHub directory
# See: debian/install for a file listing.

if sys.platform.startswith('linux'):

    # Append common directory to use resources if packaged:
    if os.path.isdir(/usr/share/humblebundle):
    	sys.path.append('/usr/share/humblebundle')

    install_requires += [
        'dbus-python',   # requires libdbus-glib-1-dev
        'secretstorage',
    ]

setup(
    name='humblebundle',
    version='0.0.0',
    url='https://github.com/MestreLion/humblebundle',
    packages=find_packages(exclude=['tests']),
    setup_requires=['setuptools-git'],
    install_requires=install_requires,
    entry_points={
        'console_scripts': [
            'humblebundle = humblebundle:cli',
        ],
    },
)
