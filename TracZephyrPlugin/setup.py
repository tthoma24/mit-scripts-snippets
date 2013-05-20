#!/usr/bin/python

from setuptools import find_packages, setup

setup(
    name='TracZephyrPlugin',
    version='1.4.2',
    author='Evan Broder and the SIPB Snippets team',
    author_email='snippets@mit.edu',
    description='Send a zephyr when a Trac ticket is created or updated',
    py_modules=["ZephyrPlugin"],
    entry_points = """
        [trac.plugins]
        ZephyrPlugin = ZephyrPlugin
    """,
)
