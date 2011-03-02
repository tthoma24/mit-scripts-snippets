#!/usr/bin/python

from setuptools import find_packages, setup

setup(
    name='TracZephyrPlugin',
    version='1.4.1',
    author='Evan Broder',
    author_email='broder@mit.edu',
    description='Send a zephyr when a Trac ticket is created or updated',
    py_modules=["ZephyrPlugin"],
    entry_points = """
        [trac.plugins]
        ZephyrPlugin = ZephyrPlugin
    """,
)
